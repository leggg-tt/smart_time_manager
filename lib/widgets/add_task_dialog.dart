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
                      labelText: 'Description (Optional)',  // 原来是 '描述（可选）'
                      hintText: 'Add any notes about this task...', // 原来是 '添加关于此任务的任何备注...'
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Text(
                    'Expected Duration',                     // 原来是 '预计时长'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _durationMinutes.toDouble(),
                          min: 15,
                          max: 240,
                          divisions: 15,
                          label: _formatDuration(_durationMinutes),
                          onChanged: (value) {
                            setState(() {
                              _durationMinutes = value.round();
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _formatDuration(_durationMinutes),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  Text(
                    'Priority',                              // 原来是 '优先级'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Priority>(
                    segments: const [
                      ButtonSegment(
                        value: Priority.low,
                        label: Text('Low'),                  // 原来是 '低'
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                      ButtonSegment(
                        value: Priority.medium,
                        label: Text('Medium'),               // 原来是 '中'
                        icon: Icon(Icons.remove, size: 16),
                      ),
                      ButtonSegment(
                        value: Priority.high,
                        label: Text('High'),                 // 原来是 '高'
                        icon: Icon(Icons.arrow_upward, size: 16),
                      ),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (value) {
                      setState(() => _priority = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Energy required
                  Text(
                    'Energy Required',                       // 原来是 '所需能量'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<EnergyLevel>(
                    segments: [
                      ButtonSegment(
                        value: EnergyLevel.low,
                        label: Text('Low'),                  // 原来是 '低'
                        icon: Icon(Icons.battery_1_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.medium,
                        label: Text('Medium'),               // 原来是 '中'
                        icon: Icon(Icons.battery_3_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.high,
                        label: Text('High'),                 // 原来是 '高'
                        icon: Icon(Icons.battery_full, size: 16),
                      ),
                    ],
                    selected: {_energyRequired},
                    onSelectionChanged: (value) {
                      setState(() => _energyRequired = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Focus required
                  Text(
                    'Focus Required',                        // 原来是 '所需专注度'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<FocusLevel>(
                    segments: const [
                      ButtonSegment(
                        value: FocusLevel.light,
                        label: Text('Light'),                // 原来是 '轻度'
                        icon: Icon(Icons.panorama_fish_eye, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.medium,
                        label: Text('Medium'),               // 原来是 '中度'
                        icon: Icon(Icons.adjust, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.deep,
                        label: Text('Deep'),                 // 原来是 '深度'
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
                        ? const Text('No deadline')         // 原来是 '无截止时间'
                        : Text(
                      '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}',
                    ),
                    trailing: _deadline == null
                        ? TextButton(
                      onPressed: _selectDeadline,
                      child: const Text('Set'),        // 原来是 '设置'
                    )
                        : TextButton(
                      onPressed: () => setState(() => _deadline = null),
                      child: const Text('Clear'),      // 原来是 '清除'
                    ),
                  ),

                  // Schedule immediately option
                  const Divider(),
                  RadioListTile<int>(
                    title: const Text('Don\'t schedule now'), // 原来是 '暂不安排'
                    subtitle: const Text('Add to pending tasks'), // 原来是 '添加到待办任务'
                    value: 0,
                    groupValue: _scheduleOption,
                    onChanged: (value) {
                      setState(() {
                        _scheduleOption = value!;
                        _scheduleImmediately = value == 1;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('Auto-schedule on specific date'), // 更清晰的描述
                    subtitle: _scheduledDate == null
                        ? const Text('System will find the best time slot')       // 更清晰的说明
                        : Text(
                      'Will auto-schedule on ${_scheduledDate!.month}/${_scheduledDate!.day}', // 明确说明会自动安排
                    ),
                    value: 1,
                    groupValue: _scheduleOption,
                    onChanged: (value) {
                      setState(() {
                        _scheduleOption = value!;
                        _scheduleImmediately = value == 1;
                        if (value == 1 && _scheduledDate == null) {
                          _selectScheduledDate();
                        }
                      });
                    },
                  ),
                  if (_scheduleOption == 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Change Date'),   // 原来是 '更改日期'
                        onPressed: _selectScheduledDate,
                      ),
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

    if (date != null && mounted) {
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

    if (date != null && mounted) {
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

      // 如果选择了自动安排到特定日期
      if (_scheduleOption == 1 && _scheduledDate != null) {
        if (!mounted) return;

        // 显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Finding best time slot...'),
              ],
            ),
          ),
        );

        // 获取推荐的时间段
        final slots = await provider.getRecommendedSlots(task, _scheduledDate!);

        // 关闭加载对话框
        if (mounted) Navigator.of(context).pop();

        if (slots.isNotEmpty) {
          // 自动选择第一个推荐的时间段
          final success = await provider.scheduleTask(task, slots.first.startTime);

          if (!mounted) return;
          Navigator.of(context).pop(); // 关闭添加任务对话框

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Task scheduled for ${_formatTime(slots.first.startTime)}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to schedule task. Added to pending tasks.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // 没有找到合适的时间段
          if (!mounted) return;
          Navigator.of(context).pop(); // 关闭添加任务对话框

          // 显示提示并询问是否手动选择
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Suitable Time Found'),
              content: Text(
                  'Smart scheduling couldn\'t find an optimal time slot on ${_scheduledDate!.month}/${_scheduledDate!.day}.\n\n'
                      'The task has been added to pending tasks. You can manually schedule it later.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Schedule Manually'),
                ),
              ],
            ),
          );

          if (result == true && mounted) {
            // TODO: 打开手动调度对话框
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please go to Task List to manually schedule this task.'),
              ),
            );
          }
        }
      } else {
        // 没有选择调度，正常关闭对话框
        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" created and added to pending tasks'),
          ),
        );
      }
    } catch (e) {
      // 确保关闭可能打开的加载对话框
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
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