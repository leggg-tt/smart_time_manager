import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;

  const EditTaskDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late int _durationMinutes;
  late Priority _priority;
  late EnergyLevel _energyRequired;
  late FocusLevel _focusRequired;
  late TaskCategory _taskCategory;
  late DateTime? _deadline;
  late DateTime? _scheduledStartTime;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing task data
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');

    // Initialize other fields with existing task data
    _durationMinutes = widget.task.durationMinutes;
    _priority = widget.task.priority;
    _energyRequired = widget.task.energyRequired;
    _focusRequired = widget.task.focusRequired;
    _taskCategory = widget.task.taskCategory;
    _deadline = widget.task.deadline;
    _scheduledStartTime = widget.task.scheduledStartTime;
  }

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
                    'Edit Task',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Task name
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      hintText: 'e.g., Prepare project presentation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Task description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add task details...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Duration',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _durationMinutes,
                          underline: const SizedBox(),
                          isDense: true,
                          items: [15, 30, 45, 60, 90, 120, 180, 240]
                              .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('${minutes ~/ 60}h ${minutes % 60}m'
                                .replaceAll('0h ', '')
                                .replaceAll(' 0m', '')),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _durationMinutes = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Priority>(
                    segments: const [
                      ButtonSegment(
                        value: Priority.low,
                        label: Text('Low'),
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                      ButtonSegment(
                        value: Priority.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.remove, size: 16),
                      ),
                      ButtonSegment(
                        value: Priority.high,
                        label: Text('High'),
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
                    'Energy Required',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<EnergyLevel>(
                    segments: const [
                      ButtonSegment(
                        value: EnergyLevel.low,
                        label: Text('Low'),
                        icon: Icon(Icons.battery_1_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.battery_4_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.high,
                        label: Text('High'),
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
                    'Focus Required',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<FocusLevel>(
                    segments: const [
                      ButtonSegment(
                        value: FocusLevel.light,
                        label: Text('Light'),
                        icon: Icon(Icons.center_focus_weak, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.center_focus_weak, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.deep,
                        label: Text('Deep'),
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
                    'Task Category',
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

                  // Scheduled Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Scheduled Time'),
                    subtitle: _scheduledStartTime == null
                        ? const Text('Not scheduled')
                        : Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(_scheduledStartTime!),
                    ),
                    trailing: _scheduledStartTime == null
                        ? TextButton(
                      onPressed: _selectScheduledTime,
                      child: const Text('Schedule'),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _selectScheduledTime,
                          child: const Text('Change'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _scheduledStartTime = null);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),

                  // Deadline
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Deadline'),
                    subtitle: _deadline == null
                        ? const Text('No deadline')
                        : Text(
                      '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}',
                    ),
                    trailing: _deadline == null
                        ? TextButton(
                      onPressed: _selectDeadline,
                      child: const Text('Set'),
                    )
                        : TextButton(
                      onPressed: () {
                        setState(() => _deadline = null);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _updateTask,
                        child: const Text('Update Task'),
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

  Future<void> _selectScheduledTime() async {
    // First select date
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStartTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: _deadline ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      // Then select time
      final time = await showTimePicker(
        context: context,
        initialTime: _scheduledStartTime != null
            ? TimeOfDay.fromDateTime(_scheduledStartTime!)
            : const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
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

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Create updated task with new values
    final updatedTask = widget.task.copyWith(
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
      scheduledStartTime: _scheduledStartTime,
      status: _scheduledStartTime != null
          ? TaskStatus.scheduled
          : (_scheduledStartTime == null && widget.task.status == TaskStatus.scheduled)
          ? TaskStatus.pending
          : widget.task.status,
    );

    try {
      // Update task using provider
      await context.read<TaskProvider>().updateTask(updatedTask);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}