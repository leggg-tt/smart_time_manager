import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_settings_service.dart';
import '../providers/pomodoro_provider.dart';

// 定义PomodoroSettingsDialog类
class PomodoroSettingsDialog extends StatefulWidget {
  const PomodoroSettingsDialog({Key? key}) : super(key: key);

  @override
  State<PomodoroSettingsDialog> createState() => _PomodoroSettingsDialogState();
}

// 状态类定义
class _PomodoroSettingsDialogState extends State<PomodoroSettingsDialog> {
  // _settings:存储当前的番茄钟设置（工作时长、休息时长等）
  late PomodoroSettings _settings;
  // _selectedPreset:当前选中的预设模式（classic、short_focus、deep_work或custom）
  String _selectedPreset = 'custom';
  // _isLoading:加载状态标志，用于显示加载指示器
  bool _isLoading = true;

  @override
  // 在组件创建时调用一次
  void initState() {
    super.initState();
    // 加载用户保存的设置
    _loadCurrentSettings();
  }

  // 加载设置方法
  Future<void> _loadCurrentSettings() async {
    // 异步方法,从服务层加载设置
    final settings = await PomodoroSettingsService.loadSettings();
    // 更新UI状态
    setState(() {
      _settings = settings;
      _isLoading = false;
      // 检查当前设置是否匹配某个预设
      _checkPreset(settings);
    });
  }

  // 检查预设方法
  void _checkPreset(PomodoroSettings settings) {
    // 检查当前设置是否与任何预设匹配
    for (final entry in PomodoroSettings.presets.entries) {
      final preset = entry.value;
      // 遍历所有预设模式,比较当前设置的各项参数是否完全匹配某个预设
      if (preset.workDuration == settings.workDuration &&
          preset.shortBreakDuration == settings.shortBreakDuration &&
          preset.longBreakDuration == settings.longBreakDuration &&
          preset.pomodorosUntilLongBreak == settings.pomodorosUntilLongBreak) {
        _selectedPreset = entry.key;
        return;
      }
    }
    // 如果都不匹配,设置为 'custom'
    _selectedPreset = 'custom';
  }

  @override
  // 加载状态
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 主对话结构
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题部分
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pomodoro Timer Settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 预设选项
                Text(
                  'Presets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // 预设选择部分
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPresetChip('classic', 'Classic (25-5-15)'),
                    _buildPresetChip('short_focus', 'Short Focus (15-3-10)'),
                    _buildPresetChip('deep_work', 'Deep Work (45-10-30)'),
                    _buildPresetChip('custom', 'Custom'),
                  ],
                ),
                const SizedBox(height: 24),

                // 创建工作时长滑块
                _buildDurationSlider(
                  title: 'Work Duration',
                  value: _settings.workDuration,
                  min: 5,
                  max: 90,
                  divisions: 17,
                  suffix: 'minutes',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(workDuration: value.round());
                      _selectedPreset = 'custom';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 短休时间
                _buildDurationSlider(
                  title: 'Short Break',
                  value: _settings.shortBreakDuration,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  suffix: 'minutes',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(shortBreakDuration: value.round());
                      _selectedPreset = 'custom';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 长休时间
                _buildDurationSlider(
                  title: 'Long Break',
                  value: _settings.longBreakDuration,
                  min: 5,
                  max: 60,
                  divisions: 11,
                  suffix: 'minutes',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(longBreakDuration: value.round());
                      _selectedPreset = 'custom';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 经历几个番茄时间点进入长休阶段
                _buildDurationSlider(
                  title: 'Pomodoros Until Long Break',
                  value: _settings.pomodorosUntilLongBreak,
                  min: 2,
                  max: 10,
                  divisions: 8,
                  suffix: 'pomodoros',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(pomodorosUntilLongBreak: value.round());
                      _selectedPreset = 'custom';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 预览区域
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      // 详细展示番茄时钟工作流程
                      Text(
                        'Work: ${_settings.workDuration} min → '
                            'Break: ${_settings.shortBreakDuration} min\n'
                            'Repeat ${_settings.pomodorosUntilLongBreak}x → '
                            'Long break: ${_settings.longBreakDuration} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 操作按钮
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await PomodoroSettingsService.resetToDefault();
                        await _loadCurrentSettings();
                      },
                      // "重置为默认"按钮：恢复默认设置并重新加载
                      child: const Text('Reset to Default'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    // 保存按钮
                    ElevatedButton(
                      onPressed: () async {
                        // 验证设置的有效性
                        if (PomodoroSettingsService.validateSettings(_settings)) {
                          // 保存设置到本地存储
                          await PomodoroSettingsService.saveSettings(_settings);

                          // 检查组件是否仍然挂载,避免异步操作后的错误
                          if (context.mounted) {
                            try {
                              final provider = context.read<PomodoroProvider>();
                              await provider.updateSettings(_settings);
                            } catch (e) {
                              // 尝试更新Provider中的设置（如果Provider存在）
                            }
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings saved')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid settings'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 预设芯片构建方法
  Widget _buildPresetChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      // 选中预设时,自动应用对应的设置值
      selected: _selectedPreset == key,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPreset = key;
            // 如果选择custom,保持当前设置不变
            if (key != 'custom') {
              _settings = PomodoroSettings.presets[key]!;
            }
          });
        }
      },
    );
  }

  // 滑块构建方法
  Widget _buildDurationSlider({
    required String title,
    required num value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${value.round()} $suffix',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()} $suffix',
          onChanged: onChanged,
        ),
      ],
    );
  }
}