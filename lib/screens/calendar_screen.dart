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
import '../widgets/onboarding_overlay.dart';  // 【新增导入】

// 定义CalendarScreen有状态组件(需要管理选中日期等状态)
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 使用ValueNotifier监听用户选中的日期
  late final ValueNotifier<DateTime> _selectedDay;
  // 当前聚焦的日期
  late final ValueNotifier<DateTime> _focusedDay;
  // 日历显示格式
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    // 在组建创建时调用
    super.initState();
    // 初始化选中日期和聚焦日期为当前日期
    _selectedDay = ValueNotifier(DateTime.now());
    _focusedDay = ValueNotifier(DateTime.now());
  }

  // 释放资源,防止内存泄漏
  @override
  void dispose() {
    _selectedDay.dispose();
    _focusedDay.dispose();
    super.dispose();
  }

  // 获取指定日期的任务
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    // 过滤出指定日期的所有任务
    return allTasks.where((task) {
      if (task.scheduledStartTime == null) return false;
      // 使用isSameDay比较日期
      return isSameDay(task.scheduledStartTime!, day);
    }).toList()
      ..sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));
  }

  @override
  Widget build(BuildContext context) {
    // 【修改开始】- 使用 OnboardingOverlay 包裹整个 Scaffold
    return OnboardingOverlay(
      screen: 'time_blocks',
      child: Scaffold(
        // 【修改结束】
        // 监听两个Provider(任务和时间块)的变化
        body: Consumer2<TaskProvider, TimeBlockProvider>(
          // 当任一数据发生变化时,自动重建界面
          builder: (context, taskProvider, timeBlockProvider, child) {
            return Column(
              children: [
                // 日历组件
                TableCalendar<Task>(
                  // 日历可显示的日期范围(前后一年)
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  // 当前聚焦的日期
                  focusedDay: _focusedDay.value,
                  // 显示格式
                  calendarFormat: _calendarFormat,
                  // 判断某天是否被选中
                  selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
                  // 加载每天的事件
                  eventLoader: (day) => _getTasksForDay(day, taskProvider.tasks),
                  // 每周从周一开始
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    // 不显示当月以外的日期
                    outsideDaysVisible: false,
                    // 选中日期的样式
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    // 今天的样式
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    // 事件标记的样式
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 日历头部样式
                  headerStyle: HeaderStyle(
                    // 显示格式切换按钮
                    formatButtonVisible: true,
                    // 标题居中
                    titleCentered: true,
                    // 格式按钮不显示下一个格式
                    formatButtonShowsNext: false,
                    // 格式按钮的装饰
                    formatButtonDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // 日历事件处理
                  // 用户选择某一天时触发
                  onDaySelected: (selectedDay, focusedDay) {
                    // 触发时,触发界面重建
                    setState(() {
                      _selectedDay.value = selectedDay;
                      _focusedDay.value = focusedDay;
                    });
                  },
                  // 切换日历格式时触发
                  onFormatChanged: (format) {
                    // 触发时,触发界面重建
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  // 翻页时触发
                  onPageChanged: (focusedDay) {
                    _focusedDay.value = focusedDay;
                  },
                ),

                const Divider(height: 1),

                // 时间分析卡片
                // FutureBuilder-异步构建组件,等待时间分析数据
                FutureBuilder<Map<String, dynamic>>(
                  future: taskProvider.getTimeAnalysis(_selectedDay.value),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      // 显示时间分析的卡片
                      return TimeAnalysisCard(analysis: snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 当日任务列表
                // 占用剩余空间
                Expanded(
                  // 构建当天的时间表
                  child: _buildDaySchedule(
                    // 传递选中日期,该日任务,时间块信息
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
        // 浮动操作按钮
        floatingActionButton: Column(
          // 子组件右对齐
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 语音输入按钮
            FloatingActionButton(
              onPressed: () => _showVoiceInputDialog(context),
              heroTag: 'calendar_voice',
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.mic),
              // 长按时显示提示文本
              tooltip: 'Voice input',
            ),
            const SizedBox(height: 16),
            // 普通添加按钮
            FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              heroTag: 'calendar_add',
              child: const Icon(Icons.add),
              tooltip: 'Add task',
            ),
          ],
        ),
      ),
    );  // 【修改结束】- 闭合 OnboardingOverlay
  }

  // 构建日程表方法
  Widget _buildDaySchedule(
      BuildContext context,
      DateTime selectedDay,
      List<Task> tasks,
      List<UserTimeBlock> timeBlocks,
      ) {
    // 使用DateFormat格式化日期显示
    final dateFormat = DateFormat('MMM dd, EEEE', 'en_US');

    // 日期标题栏
    return Column(
      children: [
        // 日期标题
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标
              Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              // 格式化的日期
              Text(
                dateFormat.format(selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // 弹性空间,推开左右内容
              const Spacer(),
              // 任务数量
              Text(
                '${tasks.length} tasks',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // 时间轴视图
        // 沾满剩余空间
        Expanded(
          // 调用_buildTimelineView构建时间轴
          child: _buildTimelineView(context, selectedDay, tasks, timeBlocks),
        ),
      ],
    );
  }

  // 时间轴视图方法(很难看,后期修改)
  Widget _buildTimelineView(
      BuildContext context,
      DateTime selectedDay,
      List<Task> tasks,
      List<UserTimeBlock> timeBlocks,
      ) {
    // 生成时间刻度（6:00 - 23:00）
    final hours = List.generate(18, (index) => index + 6);

    // 高效构建长列表
    return ListView.builder(
      // 过滤出每个小时的任务
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
        // 遍历所有时间块
        for (final block in timeBlocks) {
          // 解析时间字符串获取小时
          final startHour = int.parse(block.startTime.split(':')[0]);
          final endHour = int.parse(block.endTime.split(':')[0]);
          // 找到包含当前小时的时间块
          if (hour >= startHour && hour < endHour) {
            hourTimeBlock = block;
            break;
          }
        }

        // 构建每小时的行(时间轴试图)
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

  // 构建小时行的方法
  Widget _buildHourRow(
      BuildContext context,
      int hour,
      List<Task> tasks,
      UserTimeBlock? timeBlock,
      DateTime selectedDay,
      ) {
    // 让行高度适应内容
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          SizedBox(
            width: 60,  // 固定宽度60
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
            // 垂直时间线
            width: 2,
            color: Theme.of(context).dividerColor,
          ),

          // 内容区域
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              margin: const EdgeInsets.only(left: 16, bottom: 1),
              decoration: BoxDecoration(
                // 如果有时间块，显示对应颜色背景
                color: timeBlock != null
                    ? Color(int.parse(timeBlock.color.replaceAll('#', '0xFF')))
                    .withOpacity(0.1)
                    : null,
                border: Border(
                  bottom: BorderSide(
                    // 底部边框作为分隔线
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
                      //  点击显示操作菜单
                      onTap: () => _showTaskActionMenu(context, task),
                      // 状态改变时更新任务
                      onStatusChanged: (status) {
                        final updatedTask = task.copyWith(status: status);
                        context.read<TaskProvider>().updateTask(updatedTask);
                      },
                    ),
                  )),

                  // 空白区域可点击添加任务
                  if (tasks.isEmpty)
                    InkWell(
                      // 点击可快速添加任务到该时段
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

  // 显示添加任务对话框
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        // 传递选中的日期作为初始日期
        initialDate: _selectedDay.value,
      ),
    );
  }

  // 显示语音输入对话框
  void _showVoiceInputDialog(BuildContext context) {
    // 简单的对话框显示
    showDialog(
      context: context,
      builder: (context) => const VoiceInputDialog(),
    );
  }

  // 带时间的添加任务对话框(好像有点问题)
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

  // 任务操作菜单
  void _showTaskActionMenu(BuildContext context, Task task) {
    // 使用从底部弹出的表单
    showModalBottomSheet(
      context: context,
      // 润许控制高度
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
          // 删除确认对话框
          onDelete: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                // 二次确认防止误删
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
                        // 删除后有用户提示
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
          // 临时显示,目前只显示任务标题,之后会改成任务详情
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