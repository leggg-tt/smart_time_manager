import 'package:flutter/material.dart';
import '../models/scheduler_preferences.dart';
import '../services/scheduler_preferences_service.dart';

class SchedulerPreferencesDialog extends StatefulWidget {
  const SchedulerPreferencesDialog({Key? key}) : super(key: key);

  @override
  State<SchedulerPreferencesDialog> createState() => _SchedulerPreferencesDialogState();
}

class _SchedulerPreferencesDialogState extends State<SchedulerPreferencesDialog> {
  late SchedulerPreferences _preferences;
  String _selectedPreset = 'custom';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SchedulerPreferencesService.loadPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
      _checkPreset(prefs);
    });
  }

  void _checkPreset(SchedulerPreferences prefs) {
    // 直接比较原始值，不进行归一化
    for (final entry in SchedulerPreferences.presets.entries) {
      final preset = entry.value;
      if (_compareWeights(preset, prefs) &&
          preset.preferMorningForHighPriority == prefs.preferMorningForHighPriority &&
          preset.avoidFragmentation == prefs.avoidFragmentation &&
          preset.groupSimilarTasks == prefs.groupSimilarTasks &&
          preset.minBreakBetweenTasks == prefs.minBreakBetweenTasks) {
        _selectedPreset = entry.key;
        return;
      }
    }
    _selectedPreset = 'custom';
  }

  bool _compareWeights(SchedulerPreferences a, SchedulerPreferences b) {
    // 允许小的浮点数差异（由于归一化可能产生的）
    const tolerance = 0.1;
    return (a.energyMatchWeight - b.energyMatchWeight).abs() < tolerance &&
        (a.focusMatchWeight - b.focusMatchWeight).abs() < tolerance &&
        (a.categoryMatchWeight - b.categoryMatchWeight).abs() < tolerance &&
        (a.priorityMatchWeight - b.priorityMatchWeight).abs() < tolerance &&
        (a.timeUtilizationWeight - b.timeUtilizationWeight).abs() < tolerance &&
        (a.morningBoostWeight - b.morningBoostWeight).abs() < tolerance;
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
        constraints: const BoxConstraints(maxWidth: 600),
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
                      Icons.tune,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Task Scheduling Preferences',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Adjust how the system prioritizes different factors when scheduling tasks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
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
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('balanced', 'Balanced'),
                    _buildPresetChip('energy_focused', 'Energy Focused'),
                    _buildPresetChip('priority_focused', 'Priority Focused'),
                    _buildPresetChip('efficiency_focused', 'Efficiency Focused'),
                    _buildPresetChip('custom', 'Custom'),
                  ],
                ),
                const SizedBox(height: 24),

                // Weight sliders
                Text(
                  'Scoring Weights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Higher values mean this factor is more important when choosing time slots',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                _buildWeightSlider(
                  title: 'Energy Level Match',
                  subtitle: 'Match task energy needs with your energy levels',
                  value: _preferences.energyMatchWeight,
                  color: Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        energyMatchWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                _buildWeightSlider(
                  title: 'Focus Level Match',
                  subtitle: 'Match task focus needs with time block focus levels',
                  value: _preferences.focusMatchWeight,
                  color: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        focusMatchWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                _buildWeightSlider(
                  title: 'Task Category Match',
                  subtitle: 'Schedule tasks in time blocks suitable for their type',
                  value: _preferences.categoryMatchWeight,
                  color: Colors.blue,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        categoryMatchWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                _buildWeightSlider(
                  title: 'Priority Importance',
                  subtitle: 'Give better time slots to high priority tasks',
                  value: _preferences.priorityMatchWeight,
                  color: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        priorityMatchWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                _buildWeightSlider(
                  title: 'Time Utilization',
                  subtitle: 'Prefer time blocks that match task duration',
                  value: _preferences.timeUtilizationWeight,
                  color: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        timeUtilizationWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                _buildWeightSlider(
                  title: 'Morning Boost',
                  subtitle: 'Extra points for scheduling important tasks in the morning',
                  value: _preferences.morningBoostWeight,
                  color: Colors.amber,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        morningBoostWeight: value.round(),
                      );
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // Total weight display
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total: ${_getTotalWeight()}% (normalized to 100%)',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Behavior preferences
                Text(
                  'Scheduling Behaviors',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Prefer Morning for High Priority'),
                  subtitle: const Text('Schedule important tasks in morning time blocks'),
                  value: _preferences.preferMorningForHighPriority,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        preferMorningForHighPriority: value,
                      );
                    });
                  },
                ),

                SwitchListTile(
                  title: const Text('Avoid Time Fragmentation'),
                  subtitle: const Text('Minimize small gaps between tasks'),
                  value: _preferences.avoidFragmentation,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        avoidFragmentation: value,
                      );
                    });
                  },
                ),

                SwitchListTile(
                  title: const Text('Group Similar Tasks'),
                  subtitle: const Text('Schedule similar tasks together'),
                  value: _preferences.groupSimilarTasks,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        groupSimilarTasks: value,
                      );
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Minimum break time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Minimum Break Between Tasks'),
                          Text(
                            'Time buffer between consecutive tasks',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_preferences.minBreakBetweenTasks} min',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _preferences.minBreakBetweenTasks.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 6,
                  label: '${_preferences.minBreakBetweenTasks} min',
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        minBreakBetweenTasks: value.round(),
                      );
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Action buttons
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await SchedulerPreferencesService.resetToDefault();
                        await _loadPreferences();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reset to default')),
                          );
                        }
                      },
                      child: const Text('Reset'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // 如果选择的是预设，直接保存预设值，不进行归一化
                        SchedulerPreferences toSave;
                        if (_selectedPreset != 'custom' && SchedulerPreferences.presets.containsKey(_selectedPreset)) {
                          // 使用预设的原始值
                          toSave = SchedulerPreferences.presets[_selectedPreset]!;
                        } else {
                          // 自定义设置才进行归一化
                          toSave = _preferences.normalize();
                        }

                        await SchedulerPreferencesService.savePreferences(toSave);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preferences saved')),
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
              final preset = SchedulerPreferences.presets[key]!;
              // 完整复制预设的所有设置，包括行为偏好
              _preferences = SchedulerPreferences(
                energyMatchWeight: preset.energyMatchWeight,
                focusMatchWeight: preset.focusMatchWeight,
                categoryMatchWeight: preset.categoryMatchWeight,
                priorityMatchWeight: preset.priorityMatchWeight,
                timeUtilizationWeight: preset.timeUtilizationWeight,
                morningBoostWeight: preset.morningBoostWeight,
                preferMorningForHighPriority: preset.preferMorningForHighPriority,
                avoidFragmentation: preset.avoidFragmentation,
                groupSimilarTasks: preset.groupSimilarTasks,
                minBreakBetweenTasks: preset.minBreakBetweenTasks,
              );
            }
          });
        }
      },
    );
  }

  Widget _buildWeightSlider({
    required String title,
    required String subtitle,
    required int value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$value%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.3),
            thumbColor: color,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,  // 改为100，因为权重可以是0-100
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  int _getTotalWeight() {
    return _preferences.energyMatchWeight +
        _preferences.focusMatchWeight +
        _preferences.categoryMatchWeight +
        _preferences.priorityMatchWeight +
        _preferences.timeUtilizationWeight +
        _preferences.morningBoostWeight;
  }
}