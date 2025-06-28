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
  String _statusMessage = 'Tap microphone to start speaking';

  // 语言选择
  String _selectedLocale = 'en_US';
  final Map<String, String> _localeNames = {
    'en_US': 'English (US)',
    'en_GB': 'English (UK)',
    'cmn_CN': '中文',
  };

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
          _statusMessage = 'Microphone permission required';
        });
      }
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        print('Current recognized text: $_text');
        if (mounted) {
          if (status == 'done') {
            print('Status is done, text empty: ${_text.isEmpty}');
            if (_text.isNotEmpty) {
              print('Processing voice input...');
              _processVoiceInput();
            }
          }
        }
      },
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        // 获取可用的语言
        var locales = await _speech.locales();
        print('Available languages: ${locales.map((l) => l.localeId).toList()}');

        if (mounted) {
          setState(() {
            _isListening = true;
            _text = '';
            _statusMessage = 'Listening...';
          });
        }
        _animationController.repeat(reverse: true);

        await _speech.listen(
          onResult: (result) {
            print('Recognition result: ${result.recognizedWords}, confidence: ${result.confidence}, final: ${result.finalResult}');
            if (mounted) {
              setState(() {
                _text = result.recognizedWords;
              });
            }
          },
          localeId: _selectedLocale, // 使用选择的语言
          cancelOnError: true,
          partialResults: true,
          onSoundLevelChange: (level) {
            // print('Sound level: $level');
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Recognition completed';
        });
      }
      _animationController.stop();
      await _speech.stop();

      if (_text.isNotEmpty && mounted) {
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
        _statusMessage = 'Understanding your request...';
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
        throw Exception('Parsing failed');
      }

      // 创建任务
      final task = parsedData.toTask();
      if (!mounted) return;

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

  void _showApiKeyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
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

            // 提示信息（英文版）
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