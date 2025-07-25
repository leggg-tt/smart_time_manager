import 'package:flutter/material.dart';
import '../models/scheduler_preferences.dart';
import '../services/scheduler_preferences_service.dart';

// 定义一个有状态对话框组件
class SchedulerPreferencesDialog extends StatefulWidget {
  const SchedulerPreferencesDialog({Key? key}) : super(key: key);

  @override
  State<SchedulerPreferencesDialog> createState() => _SchedulerPreferencesDialogState();
}

// 状态类
class _SchedulerPreferencesDialogState extends State<SchedulerPreferencesDialog> {
  late SchedulerPreferences _preferences;  // 存储当前的偏好设置
  String _selectedPreset = 'custom'; // 当前选中的预设方案
  bool _isLoading = true;  // 加载状态标志

  // 初始化方法
  @override
  void initState() {
    super.initState();
    // 初始化时加载偏好设置
    _loadPreferences();
  }

  // 加载偏好设置
  Future<void> _loadPreferences() async {
    // 异步加载保存的偏好设置
    final prefs = await SchedulerPreferencesService.loadPreferences();
    // 更新状态并检查是否匹配预设方案
    setState(() {
      _preferences = prefs;
      _isLoading = false;
      _checkPreset(prefs);
    });
  }

  //检查预设匹配
  void _checkPreset(SchedulerPreferences prefs) {
    // 直接比较原始值,不进行归一化
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
    // 如果不匹配任何预设,标记为自定义
    _selectedPreset = 'custom';
  }

  // 权重比较方法
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

  // 构建UI界面
  @override
  Widget build(BuildContext context) {
    // 如果还在加载,显示加载指示器
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 主对话框结构
    return Dialog(
      child: Container(
        // 显示最大宽度
        constraints: const BoxConstraints(maxWidth: 600),
        // 允许内容滚动
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

                // 预设选择器
                Text(
                  'Presets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  // 自动换行显示预设选项
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 提供多种预设方案供用户快速选择
                    _buildPresetChip('balanced', 'Balanced'),
                    _buildPresetChip('energy_focused', 'Energy Focused'),
                    _buildPresetChip('priority_focused', 'Priority Focused'),
                    _buildPresetChip('efficiency_focused', 'Efficiency Focused'),
                    _buildPresetChip('custom', 'Custom'),
                  ],
                ),
                const SizedBox(height: 24),

                // 权重滑块
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

                // 为能量权重因素创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 为专注度权重因素创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 为任务种类匹配度权重因素创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 为优先权重因素创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 为时间利用率因素创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 为早上优先度创建一个滑块
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
                      // 修改后标记为自定义
                      _selectedPreset = 'custom';
                    });
                  },
                ),

                // 总权重显示
                const SizedBox(height: 16),
                Container(
                  // 显示所有权重的总和
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
                        // 提示用户系统会将权重归一化到100%
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

                // 行为偏好开关
                Text(
                  'Scheduling Behaviors',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // 提供优先早晨时段开关选项控制调度行为
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

                // 提供避免时间碎片化开关选项控制调度行为
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

                // 提供相似任务分组开关选项控制调度行为
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

                // 最小休息时间设置
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
                  // 每五分钟一个刻度
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

                // 操作按钮
                Wrap(
                  // 按钮右对齐
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 重置按钮
                    TextButton(
                      onPressed: () async {
                        // 重置到默认设置
                        await SchedulerPreferencesService.resetToDefault();
                        // 重新加载偏好设置,更新UI
                        await _loadPreferences();
                        // 检查context是否仍然有效（防止异步操作后widget已被销毁）
                        if (context.mounted) {
                          // 显示成功提示
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reset to default')),
                          );
                        }
                      },
                      child: const Text('Reset'),
                    ),
                    // 取消按钮
                    TextButton(
                      // 直接关闭对话框,不保存任何更改
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    // 保存按钮
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

                        // 保存偏好设置
                        await SchedulerPreferencesService.savePreferences(toSave);

                        // 检查context有效性
                        if (context.mounted) {
                          // 关闭对话框
                          Navigator.of(context).pop();
                          // 显示保存成功提示
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

  // 构建预设卡片方法
  Widget _buildPresetChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPreset == key,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPreset = key;
            if (key != 'custom') {
              // 应用预设的值
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

  // 构建权重滑块
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
            // 彩色指示条
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
              // 主标题和副标题
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
              // 显示当前值的标签
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
            max: 100,  // 改为100,因为权重可以是0-100
            divisions: 100,  // 精确到1%
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