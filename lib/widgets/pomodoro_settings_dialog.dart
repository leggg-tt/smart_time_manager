import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_settings_service.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroSettingsDialog extends StatefulWidget {
  const PomodoroSettingsDialog({Key? key}) : super(key: key);

  @override
  State<PomodoroSettingsDialog> createState() => _PomodoroSettingsDialogState();
}

class _PomodoroSettingsDialogState extends State<PomodoroSettingsDialog> {
  late PomodoroSettings _settings;
  String _selectedPreset = 'custom';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settings = await PomodoroSettingsService.loadSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
      _checkPreset(settings);
    });
  }

  void _checkPreset(PomodoroSettings settings) {
    // Check if current settings match any preset
    for (final entry in PomodoroSettings.presets.entries) {
      final preset = entry.value;
      if (preset.workDuration == settings.workDuration &&
          preset.shortBreakDuration == settings.shortBreakDuration &&
          preset.longBreakDuration == settings.longBreakDuration &&
          preset.pomodorosUntilLongBreak == settings.pomodorosUntilLongBreak) {
        _selectedPreset = entry.key;
        return;
      }
    }
    _selectedPreset = 'custom';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                // Title
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

                // Preset selection
                Text(
                  'Presets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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

                // Work duration
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

                // Short break duration
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

                // Long break duration
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

                // Pomodoros until long break
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

                // Preview
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

                // Action buttons
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await PomodoroSettingsService.resetToDefault();
                        await _loadCurrentSettings();
                      },
                      child: const Text('Reset to Default'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (PomodoroSettingsService.validateSettings(_settings)) {
                          await PomodoroSettingsService.saveSettings(_settings);

                          // Update provider if it exists
                          if (context.mounted) {
                            try {
                              final provider = context.read<PomodoroProvider>();
                              await provider.updateSettings(_settings);
                            } catch (e) {
                              // Provider might not exist
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

  Widget _buildPresetChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPreset == key,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPreset = key;
            if (key != 'custom') {
              _settings = PomodoroSettings.presets[key]!;
            }
          });
        }
      },
    );
  }

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