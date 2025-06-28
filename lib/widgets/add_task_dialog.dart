import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialTime;

  const AddTaskDialog({
    Key? key,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _durationMinutes = 60;
  Priority _priority = Priority.medium;
  EnergyLevel _energyRequired = EnergyLevel.medium;
  FocusLevel _focusRequired = FocusLevel.medium;
  TaskCategory _taskCategory = TaskCategory.routine;
  DateTime? _deadline;
  bool _scheduleImmediately = false;
  int _scheduleOption = 0; // 0: Don't schedule, 1: Specify date
  DateTime? _scheduledDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Task',                        // 原来是 '添加新任务'
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Task name
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',              // 原来是 '任务名称'
                      hintText: 'e.g., Prepare project presentation', // 原来是 '例如：准备项目演示'
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task name';   // 原来是 '请输入任务名称'
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Task description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',  // 原来是 '任务描述（可选）'
                      hintText: 'Add more details...',      // 原来是 '添加更多细节...'
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Estimated duration
                  Text(
                    'Estimated Duration',                   // 原来是 '预估时长'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final duration in [30, 60, 90, 120, 180, 240])
                        ChoiceChip(
                          label: Text(_formatDuration(duration)),
                          selected: _durationMinutes == duration,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _durationMinutes = duration);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Task properties
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',                    // 原来是 '优先级'
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<Priority>(
                              segments: const [
                                ButtonSegment(
                                  value: Priority.low,
                                  label: Text('Low'),        // 原来是 '低'
                                  icon: Icon(Icons.arrow_downward, size: 16),
                                ),
                                ButtonSegment(
                                  value: Priority.medium,
                                  label: Text('Medium'),     // 原来是 '中'
                                  icon: Icon(Icons.remove, size: 16),
                                ),
                                ButtonSegment(
                                  value: Priority.high,
                                  label: Text('High'),       // 原来是 '高'
                                  icon: Icon(Icons.arrow_upward, size: 16),
                                ),
                              ],
                              selected: {_priority},
                              onSelectionChanged: (value) {
                                setState(() => _priority = value.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Energy requirement
                  Text(
                    'Energy Required',                       // 原来是 '精力需求'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<EnergyLevel>(
                    segments: const [
                      ButtonSegment(
                        value: EnergyLevel.low,
                        label: Text('Low'),                 // 原来是 '低'
                        icon: Icon(Icons.battery_1_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.medium,
                        label: Text('Medium'),              // 原来是 '中'
                        icon: Icon(Icons.battery_4_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.high,
                        label: Text('High'),                // 原来是 '高'
                        icon: Icon(Icons.battery_full, size: 16),
                      ),
                    ],
                    selected: {_energyRequired},
                    onSelectionChanged: (value) {
                      setState(() => _energyRequired = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Focus requirement
                  Text(
                    'Focus Required',                        // 原来是 '专注度需求'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<FocusLevel>(
                    segments: const [
                      ButtonSegment(
                        value: FocusLevel.light,
                        label: Text('Light'),               // 原来是 '轻度'
                        icon: Icon(Icons.blur_on, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.medium,
                        label: Text('Medium'),              // 原来是 '中度'
                        icon: Icon(Icons.center_focus_weak, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.deep,
                        label: Text('Deep'),                // 原来是 '深度'
                        icon: Icon(Icons.center_focus_strong, size: 16),
                      ),
                    ],
                    selected: {_focusRequired},
                    onSelectionChanged: (value) {
                      setState(() => _focusRequired = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Task category
                  Text(
                    'Task Category',                         // 原来是 '任务类型'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final category in TaskCategory.values)
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon),
                              const SizedBox(width: 4),
                              Text(category.displayName),
                            ],
                          ),
                          selected: _taskCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _taskCategory = category);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Deadline
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Deadline'),          // 原来是 '截止时间'
                    subtitle: _deadline == null
                        ? const Text('Not set')             // 原来是 '未设置'
                        : Text(
                      '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}', // 改为美式日期格式
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDeadline,
                    ),
                  ),

                  // Task scheduling options
                  const SizedBox(height: 16),
                  Text(
                    'Task Scheduling',                       // 原来是 '任务安排'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Don\'t schedule now'), // 原来是 '暂不安排'
                    subtitle: const Text('Schedule manually later'), // 原来是 '稍后手动安排时间'
                    value: 0,
                    groupValue: _scheduleOption,
                    onChanged: (value) {
                      setState(() {
                        _scheduleOption = value!;
                        _scheduleImmediately = false;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Specify date'),      // 原来是 '指定日期'
                    subtitle: Text(_scheduledDate == null
                        ? 'Choose date to schedule'          // 原来是 '选择要安排的日期'
                        : '${_scheduledDate!.month}/${_scheduledDate!.day}/${_scheduledDate!.year}'), // 改为美式日期格式
                    value: 1,
                    groupValue: _scheduleOption,
                    onChanged: (value) async {
                      setState(() => _scheduleOption = value!);
                      if (value == 1) {
                        await _selectScheduledDate();
                      }
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _scheduleOption == 1 ? _selectScheduledDate : null,
                    ),
                  ),
                  if (_scheduleOption == 1 && _scheduledDate != null)
                    CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 56),
                      title: const Text('Smart recommend time'), // 原来是 '智能推荐时间'
                      subtitle: const Text('Auto-recommend optimal time slots on selected date'), // 原来是 '在选定日期自动推荐最佳时间段'
                      value: _scheduleImmediately,
                      onChanged: (value) {
                        setState(() => _scheduleImmediately = value ?? false);
                      },
                    ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),        // 原来是 '取消'
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitTask,
                        child: const Text('Create Task'),   // 原来是 '创建任务'
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';                            // 原来是 '$minutes分钟'
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';                              // 原来是 '$hours小时'
      } else {
        return '${hours}h ${mins}min';                   // 原来是 '$hours小时$mins分钟'
      }
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _deadline ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      durationMinutes: _durationMinutes,
      priority: _priority,
      energyRequired: _energyRequired,
      focusRequired: _focusRequired,
      taskCategory: _taskCategory,
      deadline: _deadline,
    );

    try {
      final provider = context.read<TaskProvider>();
      await provider.addTask(task);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" created'),  // 原来是 '任务"${task.title}"已创建'
          action: _scheduleImmediately && _scheduledDate != null
              ? SnackBarAction(
            label: 'View Recommendations',             // 原来是 '查看推荐'
            onPressed: () async {
              // Get recommended times for specified date
              final slots = await provider.getRecommendedSlots(
                task,
                _scheduledDate!,
              );
              if (slots.isNotEmpty) {
                // Auto-select first recommended time
                await provider.scheduleTask(task, slots.first.startTime);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task scheduled for ${_formatTime(slots.first.startTime)}', // 原来是 '已将任务安排到 ${_formatTime(slots.first.startTime)}'
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No suitable time slots found')), // 原来是 '没有找到合适的时间段'
                );
              }
            },
          )
              : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'), // 原来是 '创建任务失败: $e'
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} '                   // 改为美式日期格式
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}