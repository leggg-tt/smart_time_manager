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
  const TaskListScreen({super.key});  // 添加 const 构造函数

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();  // 使用 State<TaskListScreen>
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
                  Tab(text: '待安排 (${pendingTasks.length})'),
                  Tab(text: '已安排 (${scheduledTasks.length})'),
                  Tab(text: '已完成 (${completedTasks.length})'),
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
          // 语音输入按钮
          FloatingActionButton.small(
            onPressed: () => _showVoiceInputDialog(context),
            heroTag: 'voice',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.mic, size: 20),
            tooltip: '语音创建任务',
          ),
          const SizedBox(height: 12),
          // 普通添加按钮
          FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context),
            heroTag: 'add',
            child: const Icon(Icons.add),
            tooltip: '添加任务',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskStatus status) {
    if (tasks.isEmpty) {
      return _buildEmptyState(status);
    }

    // 根据优先级分组
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
            '高优先级',
            highPriorityTasks,
            Colors.red,
          ),
          const SizedBox(height: 16),
        ],
        if (mediumPriorityTasks.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            '中优先级',
            mediumPriorityTasks,
            Colors.orange,
          ),
          const SizedBox(height: 16),
        ],
        if (lowPriorityTasks.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            '低优先级',
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
        title = '没有待安排的任务';
        subtitle = '点击右下角按钮创建新任务';
        break;
      case TaskStatus.scheduled:
        icon = Icons.event_note;
        title = '没有已安排的任务';
        subtitle = '从待安排列表中选择任务进行安排';
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle_outline;
        title = '还没有完成的任务';
        subtitle = '完成任务后会在这里显示';
        break;
      default:
        icon = Icons.list;
        title = '暂无任务';
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
      builder: (context) => const AddTaskDialog(),  // 添加 const
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
      // TODO: 显示任务详情
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('任务: ${task.title}')),
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
        title: const Text('删除任务'),
        content: Text('确定要删除"${task.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('任务已删除')),
              );
            },
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

// 改进的任务安排对话框
class _ScheduleTaskDialog extends StatefulWidget {
  final Task task;

  const _ScheduleTaskDialog({required this.task});

  @override
  _ScheduleTaskDialogState createState() => _ScheduleTaskDialogState();
}

class _ScheduleTaskDialogState extends State<_ScheduleTaskDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isSmartMode = true; // true: 智能推荐, false: 手动选择

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('安排任务: ${widget.task.title}'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 任务信息
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
                      Text('时长: ${widget.task.durationDisplay}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.battery_full, size: 16),
                      const SizedBox(width: 8),
                      Text('精力需求: ${widget.task.energyRequired.displayName}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 模式选择
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('智能推荐'),
                  icon: Icon(Icons.auto_awesome),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('手动选择'),
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

            // 日期选择
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('选择日期'),
              subtitle: Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
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
                    _selectedTime = null; // 重置时间选择
                  });
                }
              },
            ),

            // 手动模式下的时间选择
            if (!_isSmartMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('选择开始时间'),
                subtitle: Text(
                  _selectedTime == null
                      ? '点击选择时间'
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
                          '任务将从 ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} '
                              '持续到 ${_calculateEndTime(_selectedTime!)}',
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: (_isSmartMode || (!_isSmartMode && _selectedTime != null))
              ? () => _handleSchedule(context)
              : null,
          child: Text(_isSmartMode ? '智能安排' : '确认安排'),
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
      // 智能推荐模式
      Navigator.of(context).pop();

      final slots = await provider.getRecommendedSlots(
        widget.task,
        _selectedDate,
      );

      if (slots.isNotEmpty) {
        // 显示推荐时间选择对话框
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
                      '已将任务安排到 ${_formatTime(slot.startTime)}',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('安排失败，请重试'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      } else {
        // 没有找到合适的时间段，提供手动选择
        final shouldManual = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('未找到推荐时间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('智能推荐未能找到最佳时间段，可能的原因：'),
                const SizedBox(height: 8),
                Text('• 当天已安排的任务较多',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('• 没有匹配任务需求的时间块',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('• 高能量时段已被占用',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                const Text('您可以手动选择一个时间段。'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('手动选择'),
              ),
            ],
          ),
        );

        if (shouldManual == true) {
          // 重新显示对话框，切换到手动模式
          setState(() {
            _isSmartMode = false;
          });
        }
      }
    } else {
      // 手动选择模式
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 检查时间冲突
      final canSchedule = await provider.canScheduleTask(widget.task, startTime);

      if (!canSchedule) {
        // 显示冲突提示
        final shouldForce = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('时间冲突'),
            content: const Text(
              '选择的时间段与已有任务冲突。\n'
                  '您仍要继续安排吗？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('重新选择'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('强制安排'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        );

        if (shouldForce != true) return;
      }

      // 执行安排
      final success = await provider.scheduleTask(widget.task, startTime);
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已将任务安排到 ${_formatTime(startTime)}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('安排失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.month}月${time.day}日 '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

// 时间段选择对话框
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
      title: const Text('选择时间段'),
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
                      Text('时间块: ${slot.timeBlock!.name}'),
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
          child: const Text('取消'),
        ),
      ],
    );
  }
}