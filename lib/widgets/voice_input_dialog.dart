import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
import '../providers/task_provider.dart';

class VoiceInputDialog extends StatefulWidget {
  const VoiceInputDialog({Key? key}) : super(key: key);

  @override
  _VoiceInputDialogState createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AITaskParser _aiParser = AITaskParser();

  bool _isListening = false;
  bool _isProcessing = false;
  String _text = '';
  String _statusMessage = '点击麦克风开始说话';

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initSpeech();
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        setState(() {
          _statusMessage = '需要麦克风权限';
        });
      }
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('语音状态: $status');
        print('当前识别文本: $_text');  // 添加调试
        if (mounted) {  // 添加 mounted 检查
          if (status == 'done') {
            print('状态为done，文本是否为空: ${_text.isEmpty}');  // 添加调试
            if (_text.isNotEmpty) {
              print('准备处理语音输入...');  // 添加调试
              _processVoiceInput();
            }
          }
        }
      },
      onError: (error) {
        print('语音错误详情: ${error.errorMsg}, 是否永久错误: ${error.permanent}');
        if (mounted) {  // 添加 mounted 检查
          setState(() {
            _isListening = false;
            _statusMessage = '语音识别错误: ${error.errorMsg}';
          });
          _animationController.stop();
        }
      },
      debugLogging: true,  // 开启调试日志
    );

    if (!available && mounted) {  // 添加 mounted 检查
      setState(() {
        _statusMessage = '语音识别不可用';
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        // 获取可用的语言
        var locales = await _speech.locales();
        print('可用语言: ${locales.map((l) => l.localeId).toList()}');

        if (mounted) {
          setState(() {
            _isListening = true;
            _text = '';
            _statusMessage = '正在听...';
          });
        }
        _animationController.repeat(reverse: true);

        await _speech.listen(
          onResult: (result) {
            print('识别结果: ${result.recognizedWords}, 置信度: ${result.confidence}, 是否最终结果: ${result.finalResult}');
            if (mounted) {  // 添加 mounted 检查
              setState(() {
                _text = result.recognizedWords;
              });
            }
          },
          localeId: 'cmn_CN', // 改回中文
          cancelOnError: true,
          partialResults: true,
          onSoundLevelChange: (level) {
            // print('音量级别: $level');  // 注释掉避免太多日志
          },
          listenFor: const Duration(seconds: 10),  // 监听10秒
          pauseFor: const Duration(seconds: 3),   // 暂停3秒后停止
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = '识别完成';
        });
      }
      _animationController.stop();
      await _speech.stop();

      if (_text.isNotEmpty && mounted) {
        // 延迟一下确保状态更新完成
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _processVoiceInput();
          }
        });
      }
    }
  }

  void _processVoiceInput() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusMessage = '正在理解您的需求...';
      });
    }

    try {
      // 检查 API Key
      final apiKey = await _aiParser.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        _showApiKeyDialog();
        return;
      }

      // 解析语音输入
      final parsedData = await _aiParser.parseVoiceInput(_text);
      if (parsedData == null) {
        throw Exception('解析失败');
      }

      // 创建任务
      final task = parsedData.toTask();
      if (!mounted) return;  // 检查是否还在

      final provider = context.read<TaskProvider>();
      await provider.addTask(task);

      // 如果有建议时间，自动安排
      final suggestedDateTime = parsedData.getSuggestedDateTime();
      if (suggestedDateTime != null) {
        final canSchedule = await provider.scheduleTask(task, suggestedDateTime);
        if (canSchedule && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '已创建任务"${task.title}"并安排到 '
                    '${suggestedDateTime.month}月${suggestedDateTime.day}日 '
                    '${suggestedDateTime.hour.toString().padLeft(2, '0')}:'
                    '${suggestedDateTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
          );
        }
      } else if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已创建任务"${task.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '处理失败: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('设置 Claude API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '首次使用需要设置 Claude API Key\n'
                  '请访问 https://console.anthropic.com 获取',
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
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _aiParser.saveApiKey(controller.text);
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                    _statusMessage = '请重新尝试';
                  });
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();  // 添加取消所有回调
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '语音创建任务',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // 麦克风动画
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
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
              '例如：明天下午3点开会，大概2小时\n'
                  '周五之前完成项目报告，需要高度专注',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 关闭按钮
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}