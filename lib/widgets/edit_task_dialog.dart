import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';

// 定义有状态组件EditTaskDialog
class EditTaskDialog extends StatefulWidget {
  final Task task;

  // 构造函数
  const EditTaskDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

// 状态类定义(late final表示这些变量会在initState中初始化)
class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();  // 表单的全局键,用于验证表单
  late final TextEditingController _titleController;  // 控制任务标题输入框
  late final TextEditingController _descriptionController;  // 控制任务描述输入框

  late int _durationMinutes;  // 任务持续时间
  late Priority _priority;  // 优先级
  late EnergyLevel _energyRequired;  // 所需能量等级
  late FocusLevel _focusRequired;  // 所需专注度等级
  late TaskCategory _taskCategory;  // 任务类别
  late DateTime? _deadline;  // 截止日期
  late DateTime? _scheduledStartTime;  // 计划开始时间

  @override
  // 初始化方法
  void initState() {
    super.initState();
    // 用现有任务数据填充所有表单字段,如果描述为null,使用空字符串
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');

    // 用现有任务数据填充所有表单字段
    _durationMinutes = widget.task.durationMinutes;
    _priority = widget.task.priority;
    _energyRequired = widget.task.energyRequired;
    _focusRequired = widget.task.focusRequired;
    _taskCategory = widget.task.taskCategory;
    _deadline = widget.task.deadline;
    _scheduledStartTime = widget.task.scheduledStartTime;
  }

  @override
  // 清理方法
  void dispose() {
    // 释放文本控制器,防止内存泄露
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // build方法
  @override
  Widget build(BuildContext context) {
    // 返回Dialog组件
    return Dialog(
      child: Container(
        // 最大宽度为400像素,保证大屏幕不会过宽
        constraints: const BoxConstraints(maxWidth: 400),
        // 允许内容滚动(SingleChildScrollView)
        child: SingleChildScrollView(
          // 表单结构
          child: Padding(
            padding: const EdgeInsets.all(24),
            // form组件(用于表单验证)
            child: Form(
              key: _formKey,
              // 垂直排列子组件
              child: Column(
                // 让对话框高度适应内容
                mainAxisSize: MainAxisSize.min,
                // 左对齐
                crossAxisAlignment: CrossAxisAlignment.start,
                // 标题显示
                children: [
                  Text(
                    'Edit Task',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // 任务名称输入框
                  // 使用TextFormField创建输入框
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',  // 标签
                      hintText: 'e.g., Prepare project presentation',  // 提示文本
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task),  // 图标
                    ),
                    // 确保任务名称不为空
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 任务描述输入框
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',  // 标签
                      hintText: 'Add task details...',  // 提示文本
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),  // 图标
                    ),
                    // 最多允许输入三行
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 持续时间选择器
                  // 水平排列子元素
                  Row(
                    children: [
                      // 显示计时器图标
                      const Icon(Icons.timer, size: 20),  // 大小设置
                      const SizedBox(width: 8),  // 8像素的水平间距
                      // 标签文本
                      Text(
                        'Duration',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      // 弹性空间(Spacer会占据所有剩余空间)
                      const Spacer(),
                      // 下拉菜单内容
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),  // 水平内边距 12 像素，垂直内边距 4 像素
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),  // 边框
                          borderRadius: BorderRadius.circular(8),  // 8像素圆角
                        ),
                        // 下拉按钮设置(值类型为整数)
                        child: DropdownButton<int>(
                          // 当前选中的值
                          value: _durationMinutes,
                          // 移除默认下划线
                          underline: const SizedBox(),
                          // 使下拉按钮更紧凑
                          isDense: true,
                          // 下拉菜单选项
                          items: [15, 30, 45, 60, 90, 120, 180, 240]
                              .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            // 显示文本格式化
                            child: Text('${minutes ~/ 60}h ${minutes % 60}m'
                                .replaceAll('0h ', '')
                                .replaceAll(' 0m', '')),
                          ))
                              .toList(),
                          // 选择事件处理
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

                  // 优先级选择器
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
                  // 分段选择器(使用SegmentedButton)
                  SegmentedButton<EnergyLevel>(
                    // segments属性
                    segments: const [
                      // 按钮段
                      ButtonSegment(
                        value: EnergyLevel.low,  // 对应的枚举值
                        label: Text('Low'),  // 显示文本
                        icon: Icon(Icons.battery_1_bar, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: EnergyLevel.medium,  // 对应的枚举值
                        label: Text('Medium'),  // 显示文本
                        icon: Icon(Icons.battery_4_bar, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: EnergyLevel.high,  // 对应的枚举值
                        label: Text('High'),  // 显示文本
                        icon: Icon(Icons.battery_full, size: 16),  // 图标
                      ),
                    ],
                    // 选中状态
                    selected: {_energyRequired},
                    // 当用户选择不同选项时触发的回调
                    onSelectionChanged: (value) {
                      // 更新组件状态并触发重新构建
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
                  // 分段选择器(使用SegmentedButton)
                  SegmentedButton<FocusLevel>(
                    // segments属性
                    segments: const [
                      // 按钮段
                      ButtonSegment(
                        value: FocusLevel.light,  // 对应的枚举值
                        label: Text('Light'),  // 显示文本
                        icon: Icon(Icons.center_focus_weak, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: FocusLevel.medium,  // 对应的枚举值
                        label: Text('Medium'),  // 显示文本
                        icon: Icon(Icons.center_focus_weak, size: 16),  // 图标
                      ),
                      ButtonSegment(
                        value: FocusLevel.deep,  // 对应的枚举值
                        label: Text('Deep'),  // 显示文本
                        icon: Icon(Icons.center_focus_strong, size: 16),  // 图标
                      ),
                    ],
                    // 选中状态
                    selected: {_focusRequired},
                    // 当用户选择不同选项时触发的回调
                    onSelectionChanged: (value) {
                      // 更新组件状态并触发重新构建
                      setState(() => _focusRequired = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 任务类型
                  Text(
                    'Task Category',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // 自动换行的流式布局组件wrap
                  Wrap(
                    spacing: 8,  // 水平间距为 8 像素
                    children: [
                      // TaskCategory.values:获取枚举的所有值
                      for (final category in TaskCategory.values)
                        ChoiceChip(
                          label: Row(
                            // Row 只占用必要的空间
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 显示类别的图标
                              Text(category.icon),
                              const SizedBox(width: 4),  // 四像素间距
                              // 显示类别名称
                              Text(category.displayName),
                            ],
                          ),
                          // 判断当前类别是否被选中,返回true/false控制芯片的选中状态
                          selected: _taskCategory == category,
                          // 点击芯片时触发
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _taskCategory = category);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 计划时间
                  ListTile(
                    contentPadding: EdgeInsets.zero,  // 移除默认内边距
                    leading: const Icon(Icons.schedule),  // 左侧显示时钟图标
                    title: const Text('Scheduled Time'),
                    // 副标题显示
                    // 未设置时间显示"Not scheduled"
                    subtitle: _scheduledStartTime == null
                        ? const Text('Not scheduled')
                        : Text(
                      // 格式化显示时间
                      DateFormat('MMM dd, yyyy HH:mm').format(_scheduledStartTime!),
                    ),
                    // 尾部操作按钮,未设置时间时：显示"Schedule"按钮
                    trailing: _scheduledStartTime == null
                        ? TextButton(
                      onPressed: _selectScheduledTime,
                      child: const Text('Schedule'),
                    )
                        : Row(
                      // 让对话框高度适应内容
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Change":调用_selectScheduledTime修改时间
                        TextButton(
                          onPressed: _selectScheduledTime,
                          child: const Text('Change'),
                        ),
                        // "Clear":直接将 _scheduledStartTime 设为 null
                        TextButton(
                          onPressed: () {
                            setState(() => _scheduledStartTime = null);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),

                  // 截至日期部分
                  ListTile(
                    contentPadding: EdgeInsets.zero,  // 移除默认内边距
                    leading: const Icon(Icons.event),  // 左侧显示日历图标
                    title: const Text('Deadline'),
                    // 未设置：显示"No deadline"
                    subtitle: _deadline == null
                        ? const Text('No deadline')
                        : Text(
                      // 已设置：显示格式化日期
                      '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}',
                    ),
                    // 未设置时：显示"Set"按钮
                    trailing: _deadline == null
                        ? TextButton(
                      onPressed: _selectDeadline,
                      child: const Text('Set'),
                    )
                        : TextButton(
                      // 已设置时：显示"Clear"按钮
                      onPressed: () {
                        setState(() => _deadline = null);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 操作按钮部分
                  Row(
                    // 按钮靠右对齐
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 取消按钮
                      TextButton(
                        // Navigator.of(context).pop():从导航栈弹出当前对话框
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      // 更新按钮
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

  // 选择时间方法
  Future<void> _selectScheduledTime() async {
    // 首次选择日期
    final date = await showDatePicker(
      context: context,
      // 日期选择器打开时默认选中的日期
      initialDate: _scheduledStartTime ?? DateTime.now(),
      // 可选择的最早日期
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      // 可选择的最晚日期
      lastDate: _deadline ?? DateTime.now().add(const Duration(days: 365)),
    );

    // 检查日期选择结果
    if (date != null && mounted) {
      // 选择时间
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

  // 选择deadline方法
  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      // 初始默认明天
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      // 今天
      firstDate: DateTime.now(),
      // 只选择日期
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    // 直接将选择的日期赋值给_deadline
    if (date != null && mounted) {
      setState(() => _deadline = date);
    }
  }

  // 任务更新方法
  Future<void> _updateTask() async {
    // 调用表单的验证方法(为空直接返回)
    if (!_formKey.currentState!.validate()) return;

    // 创建更新后的任务对象
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
      // 任务状态逻辑
      // 如果设置了计划时间:scheduled（已安排）
      // 如果清除了计划时间且原状态是已安排：状态改为pending（待处理）
      // 其他情况：保持原状态不变
      status: _scheduledStartTime != null
          ? TaskStatus.scheduled
          : (_scheduledStartTime == null && widget.task.status == TaskStatus.scheduled)
          ? TaskStatus.pending
          : widget.task.status,
    );

    // 异步更新和错误处理
    try {
      // 使用Provider模式调用更新方法,await等待异步操作完成
      await context.read<TaskProvider>().updateTask(updatedTask);

      // 成功处理
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // 错误处理
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