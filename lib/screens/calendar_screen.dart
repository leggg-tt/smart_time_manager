import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/time_block_provider.dart';
import '../models/task.dart';
import '../models/user_time_block.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/time_analysis_card.dart';
import '../widgets/voice_input_dialog.dart';
import '../widgets/task_action_menu.dart';
import '../widgets/edit_task_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});  // 添加 const 构造函数

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();  // 使用 State<CalendarScreen>
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<DateTime> _selectedDay;
  late final ValueNotifier<DateTime> _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = ValueNotifier(DateTime.now());
    _focusedDay = ValueNotifier(DateTime.now());
  }

  @override
  void dispose() {
    _selectedDay.dispose();
    _focusedDay.dispose();
    super.dispose();
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.scheduledStartTime == null) return false;
      return isSameDay(task.scheduledStartTime!, day);
    }).toList()
      ..sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<TaskProvider, TimeBlockProvider>(
        builder: (context, taskProvider, timeBlockProvider, child) {
          return Column(
            children: [
              // 日历组件
              TableCalendar<Task>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay.value,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
                eventLoader: (day) => _getTasksForDay(day, taskProvider.tasks),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay.value = selectedDay;
                    _focusedDay.value = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay.value = focusedDay;
                },
              ),

              const Divider(height: 1),

              // 时间分析卡片
              FutureBuilder<Map<String, dynamic>>(
                future: taskProvider.getTimeAnalysis(_selectedDay.value),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return TimeAnalysisCard(analysis: snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),

              // 当日任务列表
              Expanded(
                child: _buildDaySchedule(
                  context,
                  _selectedDay.value,
                  _getTasksForDay(_selectedDay.value, taskProvider.tasks),
                  timeBlockProvider.getTimeBlocksForDay(_selectedDay.value.weekday),
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
          FloatingActionButton(
            onPressed: () => _showVoiceInputDialog(context),
            heroTag: 'calendar_voice',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.mic),
            tooltip: 'Voice input',  // 原来是 '语音创建任务'
          ),
          const SizedBox(height: 16),
          // 普通添加按钮
          FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context),
            heroTag: 'calendar_add',
            child: const Icon(Icons.add),
            tooltip: 'Add task',  // 原来是 '添加任务'
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(
      BuildContext context,
      DateTime selectedDay,
      List<Task> tasks,
      List<UserTimeBlock> timeBlocks,
      ) {
    final dateFormat = DateFormat('MMM dd, EEEE', 'en_US');  // 改为英文格式

    return Column(
      children: [
        // 日期标题
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${tasks.length} tasks',  // 原来是 '${tasks.length} 个任务'
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // 时间轴视图
        Expanded(
          child: _buildTimelineView(context, selectedDay, tasks, timeBlocks),
        ),
      ],
    );
  }

  Widget _buildTimelineView(
      BuildContext context,
      DateTime selectedDay,
      List<Task> tasks,
      List<UserTimeBlock> timeBlocks,
      ) {
    // 生成时间刻度（6:00 - 23:00）
    final hours = List.generate(18, (index) => index + 6);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final hourTasks = tasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          return task.scheduledStartTime!.hour == hour;
        }).toList();

        // 查找这个小时的时间块
        UserTimeBlock? hourTimeBlock;
        for (final block in timeBlocks) {
          final startHour = int.parse(block.startTime.split(':')[0]);
          final endHour = int.parse(block.endTime.split(':')[0]);
          if (hour >= startHour && hour < endHour) {
            hourTimeBlock = block;
            break;
          }
        }

        return _buildHourRow(
          context,
          hour,
          hourTasks,
          hourTimeBlock,
          selectedDay,
        );
      },
    );
  }

  Widget _buildHourRow(
      BuildContext context,
      int hour,
      List<Task> tasks,
      UserTimeBlock? timeBlock,
      DateTime selectedDay,
      ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          // 时间线
          Container(
            width: 2,
            color: Theme.of(context).dividerColor,
          ),

          // 内容区域
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              margin: const EdgeInsets.only(left: 16, bottom: 1),
              decoration: BoxDecoration(
                color: timeBlock != null
                    ? Color(int.parse(timeBlock.color.replaceAll('#', '0xFF')))
                    .withOpacity(0.1)
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 显示时间块信息
                  if (timeBlock != null &&
                      hour == int.parse(timeBlock.startTime.split(':')[0]))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                          timeBlock.color.replaceAll('#', '0xFF'),
                        )).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeBlock.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                  // 显示任务
                  ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TaskCard(
                      task: task,
                      onTap: () => _showTaskActionMenu(context, task),
                      onStatusChanged: (status) {
                        final updatedTask = task.copyWith(status: status);
                        context.read<TaskProvider>().updateTask(updatedTask);
                      },
                    ),
                  )),

                  // 空白区域可点击添加任务
                  if (tasks.isEmpty)
                    InkWell(
                      onTap: () => _showAddTaskDialogWithTime(
                        context,
                        selectedDay,
                        hour,
                      ),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialDate: _selectedDay.value,
      ),
    );
  }

  void _showVoiceInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VoiceInputDialog(),
    );
  }

  void _showAddTaskDialogWithTime(
      BuildContext context,
      DateTime date,
      int hour,
      ) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialDate: date,
        initialTime: DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          0,
        ),
      ),
    );
  }

  void _showTaskActionMenu(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: TaskActionMenu(
          task: task,
          onEdit: () {
            showDialog(
              context: context,
              builder: (context) => EditTaskDialog(task: task),
            );
          },
          onDelete: () {
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
          },
          onViewDetails: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task: ${task.title}')),
            );
          },
        ),
      ),
    );
  }
}