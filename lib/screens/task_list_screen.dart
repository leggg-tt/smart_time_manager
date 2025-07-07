import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/voice_input_dialog.dart';
import '../services/scheduler_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final pendingTasks = taskProvider.pendingTasks;
          final scheduledTasks = taskProvider.tasks
              .where((t) => t.status == TaskStatus.scheduled)
              .toList();
          final completedTasks = taskProvider.completedTasks;

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Pending (${pendingTasks.length})'),
                  Tab(text: 'Scheduled (${scheduledTasks.length})'),
                  Tab(text: 'Completed (${completedTasks.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(pendingTasks, TaskStatus.pending),
                    _buildTaskList(scheduledTasks, TaskStatus.scheduled),
                    _buildTaskList(completedTasks, TaskStatus.completed),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice input button
          FloatingActionButton.small(
            onPressed: () => _showVoiceInputDialog(context),
            heroTag: 'task_list_voice',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.mic, size: 20),
            tooltip: 'Voice create task',
          ),
          const SizedBox(height: 12),
          // Add task button
          FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context),
            heroTag: 'task_list_add',
            child: const Icon(Icons.add),
            tooltip: 'Add task',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskStatus status) {
    if (tasks.isEmpty) {
      return _buildEmptyState(status);
    }

    // Group by priority
    final highPriorityTasks = tasks
        .where((t) => t.priority == Priority.high)
        .toList();
    final mediumPriorityTasks = tasks
        .where((t) => t.priority == Priority.medium)
        .toList();
    final lowPriorityTasks = tasks
        .where((t) => t.priority == Priority.low)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (highPriorityTasks.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            'High Priority',
            highPriorityTasks,
            Colors.red,
          ),
          const SizedBox(height: 16),
        ],
        if (mediumPriorityTasks.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            'Medium Priority',
            mediumPriorityTasks,
            Colors.orange,
          ),
          const SizedBox(height: 16),
        ],
        if (lowPriorityTasks.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            'Low Priority',
            lowPriorityTasks,
            Colors.blue,
          ),
        ],
      ],
    );
  }

  Widget _buildPrioritySection(
      BuildContext context,
      String title,
      List<Task> tasks,
      Color color,
      ) {
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskListItem(
            task: task,
            onTap: () => _handleTaskTap(context, task),
            onDelete: () => _deleteTask(context, task),
            onSchedule: task.status == TaskStatus.pending
                ? () => _scheduleTask(context, task)
                : null,
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState(TaskStatus status) {
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case TaskStatus.pending:
        icon = Icons.inbox;
        title = 'No pending tasks';
        subtitle = 'Tap the + button to create a new task';
        break;
      case TaskStatus.scheduled:
        icon = Icons.event_note;
        title = 'No scheduled tasks';
        subtitle = 'Schedule tasks from the pending list';
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle_outline;
        title = 'No completed tasks yet';
        subtitle = 'Completed tasks will appear here';
        break;
      default:
        icon = Icons.list;
        title = 'No tasks';
        subtitle = '';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showVoiceInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VoiceInputDialog(),
    );
  }

  void _handleTaskTap(BuildContext context, Task task) {
    if (task.status == TaskStatus.pending) {
      _scheduleTask(context, task);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task: ${task.title}')),
      );
    }
  }

  void _scheduleTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleTaskDialog(task: task),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

// Enhanced task scheduling dialog
class _ScheduleTaskDialog extends StatefulWidget {
  final Task task;

  const _ScheduleTaskDialog({required this.task});

  @override
  _ScheduleTaskDialogState createState() => _ScheduleTaskDialogState();
}

class _ScheduleTaskDialogState extends State<_ScheduleTaskDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isSmartMode = true; // true: smart recommendation, false: manual selection

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Schedule Task: ${widget.task.title}'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Task information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 8),
                      Text('Duration: ${widget.task.durationDisplay}'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.battery_full, size: 16),
                      const SizedBox(width: 8),
                      Text('Energy Required: ${widget.task.energyRequired.displayName}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode selection
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Smart Schedule'),
                  icon: Icon(Icons.auto_awesome),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Manual Select'),
                  icon: Icon(Icons.edit_calendar),
                ),
              ],
              selected: {_isSmartMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isSmartMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date selection
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Select Date'),
              subtitle: Text(
                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: widget.task.deadline ??
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; // Reset time selection
                  });
                }
              },
            ),

            // Time selection in manual mode
            if (!_isSmartMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Select Start Time'),
                subtitle: Text(
                  _selectedTime == null
                      ? 'Tap to select time'
                      : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
              if (_selectedTime != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Task will run from ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} '
                              'to ${_calculateEndTime(_selectedTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSmartMode || (!_isSmartMode && _selectedTime != null))
              ? () => _handleSchedule(context)
              : null,
          child: Text(_isSmartMode ? 'Smart Schedule' : 'Confirm'),
        ),
      ],
    );
  }

  String _calculateEndTime(TimeOfDay startTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + widget.task.durationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSchedule(BuildContext context) async {
    final provider = context.read<TaskProvider>();

    if (_isSmartMode) {
      // Smart recommendation mode
      Navigator.of(context).pop();

      final slots = await provider.getRecommendedSlots(
        widget.task,
        _selectedDate,
      );

      if (slots.isNotEmpty) {
        // Show recommended time slots dialog
        showDialog(
          context: context,
          builder: (context) => _TimeSlotSelectionDialog(
            task: widget.task,
            slots: slots,
            onSelect: (slot) async {
              final success = await provider.scheduleTask(widget.task, slot.startTime);
              Navigator.of(context).pop();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task scheduled for ${_formatTime(slot.startTime)}',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to schedule. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      } else {
        // No suitable time slots found, offer manual selection
        final shouldManual = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Recommended Times'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart scheduling couldn\'t find optimal time slots. Possible reasons:'),
                const SizedBox(height: 8),
                Text('• Day already has many scheduled tasks',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('• No time blocks match task requirements',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('• High-energy periods are occupied',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                const Text('You can manually select a time slot.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Manual Select'),
              ),
            ],
          ),
        );

        if (shouldManual == true) {
          // Show dialog again, switch to manual mode
          setState(() {
            _isSmartMode = false;
          });
        }
      }
    } else {
      // Manual selection mode
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Check for time conflicts
      final canSchedule = await provider.canScheduleTask(widget.task, startTime);

      if (!canSchedule) {
        // Show conflict warning
        final shouldForce = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Time Conflict'),
            content: const Text(
              'The selected time slot conflicts with existing tasks.\n'
                  'Do you still want to schedule it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Choose Another Time'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Force Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        );

        if (shouldForce != true) return;
      }

      // Execute scheduling
      final success = await provider.scheduleTask(widget.task, startTime);
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task scheduled for ${_formatTime(startTime)}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

// Time slot selection dialog
class _TimeSlotSelectionDialog extends StatelessWidget {
  final Task task;
  final List<TimeSlot> slots;
  final Function(TimeSlot) onSelect;

  const _TimeSlotSelectionDialog({
    required this.task,
    required this.slots,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Time Slot'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${slot.score.toInt()}'),
                ),
                title: Text(
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:'
                      '${slot.startTime.minute.toString().padLeft(2, '0')} - '
                      '${slot.endTime.hour.toString().padLeft(2, '0')}:'
                      '${slot.endTime.minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slot.timeBlock != null)
                      Text('Time Block: ${slot.timeBlock!.name}'),
                    ...slot.reasons.map((reason) => Text('• $reason')),
                  ],
                ),
                onTap: () => onSelect(slot),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}