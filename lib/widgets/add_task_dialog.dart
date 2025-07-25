import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';

// 定义AddTaskDialog类
class AddTaskDialog extends StatefulWidget {
  final DateTime? initialDate;  // 可选初始日期
  final DateTime? initialTime;  // 可选初始时间

  // 构造函数
  const AddTaskDialog({
    Key? key,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  // 重写父类方法
  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  // 表单的全局键,用于验证和提交表单
  final _formKey = GlobalKey<FormState>();
  // 控制任务标题输入框
  final _titleController = TextEditingController();
  // 控制任务描述输入框
  final _descriptionController = TextEditingController();

  int _durationMinutes = 60;  // 任务预计时长(默认60分钟)
  Priority _priority = Priority.medium;  // 优先级(默认中等)
  EnergyLevel _energyRequired = EnergyLevel.medium;  // 所需能量(默认中等)
  FocusLevel _focusRequired = FocusLevel.medium;  // 所需专注度(默认中等)
  TaskCategory _taskCategory = TaskCategory.routine;  // 任务类别(默认事务性)
  DateTime? _deadline;  // 截至日期
  bool _scheduleImmediately = false; // 是否立即安排
  int _scheduleOption = 0; // （0=不安排，1=指定日期）
  DateTime? _scheduledDate;  // 计划安排日期

  // 资源释放
  @override
  void dispose() {
    // 组件销毁时释放文本控制器，防止内存泄漏
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // UI构建
  @override
  Widget build(BuildContext context) {
    // 返回一个Dialog组件
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),  // 限制最大宽度为400像素
        // 允许内容滚动,防止溢出(SingleChildScrollView)
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),  // 内边距
            child: Form(
              // 表单容器,使用_formKey关联
              key: _formKey,
              child: Column(
                // 列表高度由内容多少决定
                mainAxisSize: MainAxisSize.min,
                // 子组件左对齐
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 添加任务
                  Text(
                    'Add New Task',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),  // 下方间距

                  // 任务名称
                  TextFormField(
                    // 使用_titleController控制
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',  // 标签文本
                      hintText: 'e.g., Prepare project presentation',  // 提示文本
                      border: OutlineInputBorder(),  // 外边框样式
                      prefixIcon: Icon(Icons.task),  // 前缀图标
                    ),
                    // 输入验证(检查是否为空,返回错误消息或null)
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 描述输入框(可选)
                  TextFormField(
                    // 使用_descriptionController控制
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',  // 标签文本
                      hintText: 'Add any notes about this task...',  // 提示文本
                      border: OutlineInputBorder(),  // 边框样式
                      prefixIcon: Icon(Icons.notes),  // 前缀图标
                    ),
                    maxLines: 3,  // 最多三行文本
                  ),
                  const SizedBox(height: 16),

                  // 持续时长
                  Text(
                    'Expected Duration',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        // 使用滑块来进行选择,范围是15-240,15一个刻度
                        child: Slider(
                          value: _durationMinutes.toDouble(),
                          min: 15,
                          max: 240,
                          divisions: 15,
                          label: _formatDuration(_durationMinutes),
                          // 滑块变化处理
                          onChanged: (value) {
                            // 更新状态并触发UI重建
                            setState(() {
                              _durationMinutes = value.round();
                            });
                          },
                        ),
                      ),
                      // 时长显示标签
                      Container(
                        // 对称内边距
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // 获取当前上下文主题
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),  // 圆角设置
                        ),
                        child: Text(
                          // 显示格式化时长
                          // 传入当前选择的分钟数
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

                  // 优先级
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // 分段选择器(使用SegmentedButton)
                  SegmentedButton<Priority>(
                    // segments属性
                    segments: const [
                      // 按钮段
                      ButtonSegment(
                        value: Priority.low,  // 对应的枚举值
                        label: Text('Low'),  // 显示文本
                        icon: Icon(Icons.arrow_downward, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: Priority.medium,  // 对应的枚举值
                        label: Text('Medium'),  // 显示文本
                        icon: Icon(Icons.remove, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: Priority.high,  // 对应的枚举值
                        label: Text('High'),  // 显示文本
                        icon: Icon(Icons.arrow_upward, size: 16),  // 图标
                      ),
                    ],
                    // 选中状态
                    selected: {_priority},
                    // 当用户选择不同选项时触发的回调
                    onSelectionChanged: (value) {
                      // 更新组件状态并触发重新构建
                      setState(() => _priority = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 能量需求
                  Text(
                    'Energy Required',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<EnergyLevel>(
                    segments: [
                      ButtonSegment(
                        value: EnergyLevel.low,
                        label: Text('Low'),
                        icon: Icon(Icons.battery_1_bar, size: 16),
                      ),
                      ButtonSegment(
                        value: EnergyLevel.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.battery_3_bar, size: 16),
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

                  // 专注度需求
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
                        icon: Icon(Icons.panorama_fish_eye, size: 16),
                      ),
                      ButtonSegment(
                        value: FocusLevel.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.adjust, size: 16),
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

                  // 任务类型
                  Text(
                    'Task Category',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),  // 8像素的间距
                  Wrap(
                    spacing: 8,  // 子组件之间的水平间距为8像素
                    children: [
                      // 循环遍历所有任务类型
                      for (final category in TaskCategory.values)
                        ChoiceChip(
                          label: Row(
                            // 宽度由内容决定
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 显示类别图标
                              Text(category.icon),
                              // 四像素间距
                              const SizedBox(width: 4),
                              // 显示类别名称
                              Text(category.displayName),
                            ],
                          ),
                          // 比较当前类别是否是循环中的类别
                          selected: _taskCategory == category,
                          onSelected: (selected) {
                            // 是否被选中
                            if (selected) {
                              // 选中则更新状态
                              setState(() => _taskCategory = category);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 截至时间设置
                  ListTile(
                    // 移除默认内边距
                    contentPadding: EdgeInsets.zero,
                    // 左侧显示日历图标
                    leading: const Icon(Icons.event),
                    // 主题
                    title: const Text('Deadline'),
                    // 无截止日期时显示"No deadline",有截止日期时显示格式化的日期（月/日/年）
                    subtitle: _deadline == null
                        ? const Text('No deadline')
                        : Text(
                      '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}',
                    ),
                    // 右侧组件
                    trailing: _deadline == null
                        ? TextButton(
                      // 点击调用_selectDeadline方法
                      onPressed: _selectDeadline,
                      child: const Text('Set'),
                    )
                        : TextButton(
                      // 点击时清除截止日期（设为null）
                      onPressed: () => setState(() => _deadline = null),
                      child: const Text('Clear'),
                    ),
                  ),

                  // 立即调度选项
                  // 功能区分隔
                  const Divider(),
                  RadioListTile<int>(
                    // 主标题
                    title: const Text('Don\'t schedule now'),
                    // 副标题
                    subtitle: const Text('Add to pending tasks'),
                    value: 0,
                    // 当前选中的值
                    groupValue: _scheduleOption,
                    onChanged: (value) {
                      setState(() {
                        _scheduleOption = value!;
                        _scheduleImmediately = value == 1;
                      });
                    },
                  ),
                  // 结合了单选按钮和ListTile的组件
                  RadioListTile<int>(
                    // 主标题
                    title: const Text('Auto-schedule on specific date'),
                    // 动态副标题,未选择日期和选择日期
                    subtitle: _scheduledDate == null
                        ? const Text('System will find the best time slot')
                        : Text(
                      'Will auto-schedule on ${_scheduledDate!.month}/${_scheduledDate!.day}',
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
                      // 更改日期按钮
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),  // 图标
                        label: const Text('Change Date'),  // 标签
                        // 点击调用时用_selectScheduledDate方法
                        onPressed: _selectScheduledDate,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 操作按钮
                  Row(
                    // 控制子组件在主轴（水平方向）上的对齐,右对齐
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        // 获取当前上下文的导航器,关闭当前页面（对话框）
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      // 创建任务按钮
                      ElevatedButton(
                        // 点击触发,_submitTask
                        onPressed: _submitTask,
                        child: const Text('Create Task'),
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

  // 时长格式化方法
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${mins}min';
      }
    }
  }

  // 选择截止日期方法
  Future<void> _selectDeadline() async {
    // 显示日期选择器
    final date = await showDatePicker(
      context: context,
      // 如果有截止日期就用,没有就用明天
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      // 最早可选今日
      firstDate: DateTime.now(),
      // 最晚一年后
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    // 防止选择过去的日期
    if (date != null && mounted) {
      setState(() => _deadline = date);
    }
  }

  // 选择调度日期的方法
  Future<void> _selectScheduledDate() async {
    // 打开日期选择器,用于选择自动调度的目标日期
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      //智能日期范围：最早今天,最晚截止日期或一年后
      firstDate: DateTime.now(),
      lastDate: _deadline ?? DateTime.now().add(const Duration(days: 365)),
    );

    // 防止选择过去的日期
    if (date != null && mounted) {
      setState(() => _scheduledDate = date);
    }
  }

  // 提交任务主方法
  Future<void> _submitTask() async {
    // 表单验证
    if (!_formKey.currentState!.validate()) return;

    // 创建任务对象,标题：从控制器获取,描述：空字符串转为null
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

    // 保存任务
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
          // 加载对话框内容
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

          // 成功反馈
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
            // 调度失败
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
    return '${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}