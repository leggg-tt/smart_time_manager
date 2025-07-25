import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
import '../providers/task_provider.dart';

// 定义一个有状态的VoiceInputDialog对话框组件
class VoiceInputDialog extends StatefulWidget {
  const VoiceInputDialog({Key? key}) : super(key: key);

  @override
  _VoiceInputDialogState createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    // 用于提供动画控制器所需的vsync
    with SingleTickerProviderStateMixin {
  // 成员变量
  final stt.SpeechToText _speech = stt.SpeechToText();  // 语音识别实例
  final AITaskParser _aiParser = AITaskParser();  //  AI解析器实例,用于将自然语言转换为任务

  bool _isListening = false;  // 是否正在监听语音
  bool _isProcessing = false;  // 是否正在处理识别结果
  String _text = '';  // 识别到的文本
  String _statusMessage = 'Tap microphone to start speaking';  // 状态提示信息

  // 语言选择
  String _selectedLocale = 'en_US';  // 默认选择美式英语
  // 支持多语言识别
  final Map<String, String> _localeNames = {
    'en_US': 'English (US)',
    'en_GB': 'English (UK)',
    'cmn_CN': '中文',
  };

  // 动画控制器和动画对象,用于实现麦克风图标的脉冲动画效果
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 初始化方法
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      // 缩放动画,使用缓入缓出曲线
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // 初始化语音识别
    _initSpeech();
  }

  // 语音识别初始化
  void _initSpeech() async {
    // 请求麦克风权限
    final status = await Permission.microphone.request();
    // 如果未授权则更新状态消息并返回
    if (status != PermissionStatus.granted) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Microphone permission required';
        });
      }
      return;
    }

    // 初始化语音识别
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        print('Current recognized text: $_text');
        if (mounted) {
          // 当识别状态为done且有识别文本时，自动处理语音输入
          if (status == 'done') {
            print('Status is done, text empty: ${_text.isEmpty}');
            // 当识别为空时则出现请输入语音文本
            if (_text.isNotEmpty) {
              print('Processing voice input...');
              _processVoiceInput();
            }
          }
        }
      },
      // 设置错误回调,打印错误信息并更新UI状态
      onError: (error) {
        print('Speech error: ${error.errorMsg}, permanent: ${error.permanent}');
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusMessage = 'Speech recognition error: ${error.errorMsg}';
          });
          _animationController.stop();
        }
      },
      debugLogging: true,
    );

    if (!available && mounted) {
      setState(() {
        _statusMessage = 'Speech recognition not available';
      });
    }
  }

  // 语音监听方法
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        // 获取可用的语言
        var locales = await _speech.locales();
        // 重新初始化并获取设备支持的语言列表
        print('Available languages: ${locales.map((l) => l.localeId).toList()}');

        // 更新UI状态,清空之前的文本,启动脉冲动画
        if (mounted) {
          setState(() {
            _isListening = true;
            _text = '';
            _statusMessage = 'Listening...';
          });
        }
        _animationController.repeat(reverse: true);

        // 开始语音监听,设置各种参数
        await _speech.listen(
          // 识别结果回调,实时更新识别文本
          onResult: (result) {
            print('Recognition result: ${result.recognizedWords}, confidence: ${result.confidence}, final: ${result.finalResult}');
            if (mounted) {
              setState(() {
                _text = result.recognizedWords;
              });
            }
          },
          localeId: _selectedLocale, // 使用选择的语言
          cancelOnError: true,  // 出错时自动取消
          partialResults: true,  // 启用部分结果,实时显示识别内容
          onSoundLevelChange: (level) {
            // print('Sound level: $level');
          },
          // 最长监听时间10秒
          listenFor: const Duration(seconds: 30),
          // 用户停顿3秒后自动停止
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      // 停止监听
      if (mounted) {
        // 更新状态
        setState(() {
          _isListening = false;
          _statusMessage = 'Recognition completed';
        });
      }
      _animationController.stop();
      await _speech.stop();

      if (_text.isNotEmpty && mounted) {
        // 如果有识别文本,延迟100毫秒后处理
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _processVoiceInput();
          }
        });
      }
    }
  }

  // 处理语音输入
  void _processVoiceInput() async {
    if (mounted) {
      // 开始处理,更新处理状态和提示信息
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Understanding your request...';
      });
    }

    try {
      // 检查 API Key
      final apiKey = await _aiParser.getApiKey();
      // 如果没有则显示配置对话框
      if (apiKey == null || apiKey.isEmpty) {
        _showApiKeyDialog();
        return;
      }

      // 解析语音输入
      final parsedData = await _aiParser.parseVoiceInput(_text);
      if (parsedData == null) {
        throw Exception('Parsing failed');
      }

      // 创建任务
      final task = parsedData.toTask();
      if (!mounted) return;

      // 通过Provider添加到任务列表
      final provider = context.read<TaskProvider>();
      await provider.addTask(task);

      // 如果有建议时间，自动安排
      final suggestedDateTime = parsedData.getSuggestedDateTime();
      // 如果AI解析出了具体时间,尝试自动安排任务
      if (suggestedDateTime != null) {
        final canSchedule = await provider.scheduleTask(task, suggestedDateTime);
        if (canSchedule && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            // 成功后关闭对话框并显示成功提示
            SnackBar(
              content: Text(
                'Created task "${task.title}" and scheduled for '
                    '${suggestedDateTime.month}/${suggestedDateTime.day} '
                    '${suggestedDateTime.hour.toString().padLeft(2, '0')}:'
                    '${suggestedDateTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
          );
        }
      } else if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created task "${task.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Processing failed: $e';
          _isProcessing = false;
        });
      }
    }
  }

  // API Key配置对话框
  void _showApiKeyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      // 不能点击外部关闭
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set Claude API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'First time usage requires Claude API Key\n'
                  'Please visit https://console.anthropic.com to get one',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(),
              ),
              // 密码模式，隐藏输入
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            // 取消按钮
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            // 提交按钮
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _aiParser.saveApiKey(controller.text);
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                    _statusMessage = 'Please try again';
                  });
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // 资源释放
  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // UI构建
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        // 构建一个最大宽度400的对话框
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice Task Creation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // 语言选择下拉菜单
            DropdownButtonFormField<String>(
              value: _selectedLocale,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: _localeNames.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocale = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // 麦克风动画
            // 监听动画变化
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // 实现缩放效果
                return Transform.scale(
                  scale: _animation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.red.withOpacity(0.1)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: IconButton(
                      onPressed: _isProcessing ? null : _listen,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 48,
                        // 监听时显示红色
                        color: _isListening
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 状态信息
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            // 识别的文本
            if (_text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _text,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // 处理中的进度条
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],

            const SizedBox(height: 24),

            // 提示信息
            Text(
              'Examples:\n'
                  '"Schedule meeting tomorrow at 3 PM for 2 hours"\n'
                  '"Finish project report by Friday, needs high focus"\n'
                  '"Call mom sometime this week"',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 关闭按钮
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}