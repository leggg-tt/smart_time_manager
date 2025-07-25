import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/voice_input_dialog.dart';
import '../services/scheduler_service.dart';

// 定义TaskListScreen有状态组件(表示这个页面有内部状态需要管理)
class TaskListScreen extends StatefulWidget {
  // 用于传递 widget key
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    // 混入mixin,为动画提供ticker
    with SingleTickerProviderStateMixin {
  // 延迟初始化的标签控制器,管理顶部标签切换
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 创建包含三个标签的控制器(待处理,已安排,已完成)
    _tabController = TabController(length: 3, vsync: this);
  }

  // 清理资源,防止内存泄漏
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 基础页面结构
    return Scaffold(
      // 监听TaskProvider的状态变化,自动重建UI
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // 获取不同状态的任务列表
          final pendingTasks = taskProvider.pendingTasks;
          final scheduledTasks = taskProvider.tasks
              .where((t) => t.status == TaskStatus.scheduled ||
              t.status == TaskStatus.inProgress)
              .toList();
          final completedTasks = taskProvider.completedTasks;

          // 标签栏
          return Column(
            // 显示三个标签,每个标签显示对应的任务数量
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Pending (${pendingTasks.length})'),
                  Tab(text: 'Scheduled (${scheduledTasks.length})'),
                  Tab(text: 'Completed (${completedTasks.length})'),
                ],
              ),
              // 占用剩余空间(expanded)
              Expanded(
                // 显示与标签对应的内容
                child: TabBarView(
                  controller: _tabController,
                  // 调用_buildTaskList来创建任务列表
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
      // 浮动操作按钮组
      floatingActionButton: Column(
        // 按钮主界面右对齐
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: () => _showVoiceInputDialog(context),
            // 防止多个 FAB 之间的动画冲突
            heroTag: 'task_list_voice',
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            child: const Icon(Icons.mic, size: 20),
            // 长按显示提示文字
            tooltip: 'Voice create task',
          ),
          const SizedBox(height: 12),
          // 添加任务按钮
          FloatingActionButton(
            // 点击后显示添加任务对话框
            onPressed: () => _showAddTaskDialog(context),
            heroTag: 'task_list_add',
            child: const Icon(Icons.add),
            tooltip: 'Add task',
          ),
        ],
      ),
    );
  }

  // 构建任务列表方法
  Widget _buildTaskList(List<Task> tasks, TaskStatus status) {
    // 如果任务列表为空,显示空状态提示
    if (tasks.isEmpty) {
      return _buildEmptyState(status);
    }

    // 按优先级分组,使用where过滤不同优先级的任务
    final highPriorityTasks = tasks
        .where((t) => t.priority == Priority.high)
        .toList();
    final mediumPriorityTasks = tasks
        .where((t) => t.priority == Priority.medium)
        .toList();
    final lowPriorityTasks = tasks
        .where((t) => t.priority == Priority.low)
        .toList();

    // 可滚动列表
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 只有当该优先级有任务时才显示对应部分
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

  // 优先级分组小组件头部
  Widget _buildPrioritySection(
      BuildContext context,
      String title,
      List<Task> tasks,
      Color color,
      ) {
    return Column(
      // 子组件向左对齐
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                // 不同优先级使用不同颜色
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
            // 任务数量标签,显示该优先级的任务数量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
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
        // map将每个任务转换为TaskListItem组件
        ...tasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskListItem(
            task: task,
            // 点击回调函数
            onTap: () => _handleTaskTap(context, task),
            // 删除回调函数
            onDelete: () => _deleteTask(context, task),
            // 安排回调函数(只有待处理任务才显示)
            onSchedule: task.status == TaskStatus.pending
                ? () => _scheduleTask(context, task)
                : null,
          ),
        )),
      ],
    );
  }

  // 空状态提示
  Widget _buildEmptyState(TaskStatus status) {
    IconData icon;
    String title;
    String subtitle;

    // 根据不同的任务状态显示不同的提示信息
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

    // 居中布局
    return Center(
      child: Column(
        // 子元素在垂直方向上居中
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.3)
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.6)
            ),
          ),
          // 只有当副标题不为空时才显示
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.4)
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 显示AddTaskDialog组件
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  // 显示VoiceInputDialog组件
  void _showVoiceInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VoiceInputDialog(),
    );
  }

  // 处理任务项的点击事件
  void _handleTaskTap(BuildContext context, Task task) {
    // 如果是待处理任务,调用_scheduleTask方法
    if (task.status == TaskStatus.pending) {
      _scheduleTask(context, task);
    } else {
      // 如果是其他状态任务,仅显示任务标题,后面可能要优化成任务详情
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task: ${task.title}')),
      );
    }
  }

  // _scheduleTask方法
  void _scheduleTask(BuildContext context, Task task) {
    // 显示任务安排对话框
    showDialog(
      context: context,
      builder: (context) => _ScheduleTaskDialog(task: task),
    );
  }

  // _deleteTask方法
  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 显示任务具体名称,让用户确认
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // 通过 Provider 调用删除方法
              context.read<TaskProvider>().deleteTask(task.id);
              // 关闭确认对话框
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                // 显示SnackBar,给用户反馈,确认任务已删除
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

// 任务安排对话框
class _ScheduleTaskDialog extends StatefulWidget {
  // 接收要安排的任务作为参数
  final Task task;

  const _ScheduleTaskDialog({required this.task});

  @override
  _ScheduleTaskDialogState createState() => _ScheduleTaskDialogState();
}

class _ScheduleTaskDialogState extends State<_ScheduleTaskDialog> {
  DateTime _selectedDate = DateTime.now();  // 选择的日期,默认是今天
  TimeOfDay? _selectedTime;  // 选择的时间,可空
  bool _isSmartMode = true;  // 智能推荐模式or手动选择模式

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Schedule Task: ${widget.task.title}'),
      content: Container(
        // 占满可用宽度
        width: double.maxFinite,
        child: Column(
          // 高度自适应内容
          mainAxisSize: MainAxisSize.min,
          children: [
            // 任务信息展示
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

            // 模式选择按钮
            SegmentedButton<bool>(
              // 分段
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
              // 使用Set表示当前选中状态
              selected: {_isSmartMode},
              onSelectionChanged: (Set<bool> newSelection) {
                // 通过setState更新状态,触发UI重建
                setState(() {
                  _isSmartMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // 日期选择器
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
                  // 只可以选择今天或之后的日期
                  firstDate: DateTime.now(),
                  // 如果任务有截止日期则使用,没有则默认未来一年
                  lastDate: widget.task.deadline ??
                      DateTime.now().add(const Duration(days: 365)),
                );
                // 选择新日期后重置时间选择,防止时间与日期不匹配
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; // Reset time selection
                  });
                }
              },
            ),

            // 手动模式时间选择器
            // 只有手动模式下显示时间选择器
            if (!_isSmartMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Select Start Time'),
                subtitle: Text(
                  // 未选择时显示提示文字
                  _selectedTime == null
                      ? 'Tap to select time'
                      : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                    // 设置为24小时制
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
                        // 选择时间后显示任务的开始和结束时间
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
      // 操作按钮
      actions: [
        TextButton(
          // 取消按钮:关闭对话框
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // 确认按钮:智能模式下始终可用,手动模式下只有选择了时间才可用,按钮文字根据模式动态变化
          onPressed: (_isSmartMode || (!_isSmartMode && _selectedTime != null))
              ? () => _handleSchedule(context)
              : null,
          child: Text(_isSmartMode ? 'Smart Schedule' : 'Confirm'),
        ),
      ],
    );
  }

  // _calculateEndTime辅助方法
  String _calculateEndTime(TimeOfDay startTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + widget.task.durationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  // _handleSchedule核心调度方法
  Future<void> _handleSchedule(BuildContext context) async {
    final provider = context.read<TaskProvider>();

    if (_isSmartMode) {
      // 智能化推荐模式
      Navigator.of(context).pop();

      // 调用 provider 获取推荐时间段
      final slots = await provider.getRecommendedSlots(
        widget.task,
        _selectedDate,
      );

      if (slots.isNotEmpty) {
        // 如果有推荐时间段,显示选择对话框
        showDialog(
          context: context,
          builder: (context) => _TimeSlotSelectionDialog(
            task: widget.task,
            slots: slots,
            onSelect: (slot) async {
              // 用户选择后执行实际的安排操作
              final success = await provider.scheduleTask(widget.task, slot.startTime);
              Navigator.of(context).pop();

              // 根据结果显示成功或失败的提示
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
        // 解释无法找到推荐时间的可能原因
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
          // 再次切换到手动选择模式
          setState(() {
            _isSmartMode = false;
          });
        }
      }
    } else {
      // 手动处理模式
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 检查是否有时间冲突
      final canSchedule = await provider.canScheduleTask(widget.task, startTime);

      if (!canSchedule) {
        // 显示冲突警告
        final shouldForce = await showDialog<bool>(
          context: context,
          // 如果有冲突显示警示对话框
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
                // 允许用户强制安排
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

      // 执行任务安排
      // 调用TaskProvider中的方法
      final success = await provider.scheduleTask(widget.task, startTime);
      Navigator.of(context).pop();

      if (success) {
        // 消息管理器
        ScaffoldMessenger.of(context).showSnackBar(
          // 底部弹出的临时信息条
          SnackBar(
            content: Text(
              'Task scheduled for ${_formatTime(startTime)}',
            ),
          ),
        );
      } else {
        // 显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // _formatTime格式化方法
  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

// _TimeSlotSelectionDialog类
// 无状态组件,只负责显示
class _TimeSlotSelectionDialog extends StatelessWidget {
  final Task task;
  final List<TimeSlot> slots;
  final Function(TimeSlot) onSelect;

  // 构造函数
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
                // 评分显示
                title: Text(
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:'
                      '${slot.startTime.minute.toString().padLeft(2, '0')} - '
                      '${slot.endTime.hour.toString().padLeft(2, '0')}:'
                      '${slot.endTime.minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Column(
                  // 详细信息显示
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
          // 用户点击某个时间段时,调用传入的onSelect回调
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}