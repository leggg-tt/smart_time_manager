import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';

// 定义TaskCard类
class TaskCard extends StatelessWidget {
  final Task task;  // 要显示的任务数据(必须参数)
  final VoidCallback? onTap;  // 可选点击回调函数
  final Function(TaskStatus)? onStatusChanged; // 可选的状态改变回调函数,接收TaskStatus参数

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据任务优先级获取对应的颜色
    final priorityColor = _getPriorityColor(task.priority);
    // 判断任务是否已经完成
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      elevation: 2,  // 卡片阴影
      margin: EdgeInsets.zero,  // 移除默认边距
      // 动画效果
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),  // 圆角半径
        // 容器装饰
        child: Container(
          padding: const EdgeInsets.all(12),  // 内边距
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: priorityColor,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              // 复选框
              // 只有提供了onStatusChanged回调时才显示复选框
              if (onStatusChanged != null)  // 条件渲染，只在提供回调时显示
                Checkbox(
                  value: isCompleted,
                  //状态改变处理，勾选设为completed，取消设为scheduled
                  onChanged: (value) {
                    if (value == true) {
                      onStatusChanged?.call(TaskStatus.completed);
                    } else {
                      onStatusChanged?.call(TaskStatus.scheduled);
                    }
                  },
                  // 减小点击区域大小
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

              // 任务内容
              // 让标题占据剩余空间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            // 已完成的任务显示删除线和半透明效果
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? Theme.of(context).textTheme.titleSmall?.color?.withOpacity(0.5)  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.5)
                                  : null,
                            ),
                            // 标题过长时显示省略号,最多一行
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 右侧显示任务分类的图标
                        Text(
                          task.taskCategory.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 属性标签组件
                    Wrap(
                      spacing: 4,  // 水平
                      runSpacing: 4,  // 垂直
                      children: [
                        // 任务持续时间标签
                        _buildChip(
                          context,
                          Icons.schedule,
                          task.durationDisplay,
                          Colors.blue,
                        ),

                        // 能量需求标签
                        _buildChip(
                          context,
                          Icons.battery_full,
                          task.energyRequired.displayName,
                          _getEnergyColor(task.energyRequired),
                        ),

                        // 专注度需求标签
                        _buildChip(
                          context,
                          Icons.center_focus_strong,
                          task.focusRequired.displayName,
                          _getFocusColor(task.focusRequired),
                        ),

                        // 截止日期标签(可选)
                        if (task.deadline != null && !isCompleted)
                          _buildChip(
                            context,
                            Icons.event,
                            _formatDeadline(task.deadline!),
                            // 过期与未过期用颜色区分
                            task.isOverdue ? Colors.red : Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildChip 方法
  Widget _buildChip(
      BuildContext context,  // 内容
      IconData icon,  // 图标
      String label,  // 标签
      Color color,  // 颜色
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),  // 透明度,问题同上
        borderRadius: BorderRadius.circular(12),  // 圆角半径
      ),
      // 只占用必要的空间
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,  // 图标大小
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,  // 文字大小
            ),
          ),
        ],
      ),
    );
  }

  // 优先级颜色
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.blue;
    }
  }

  // 能量等级颜色
  Color _getEnergyColor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.high:
        return Colors.red;
      case EnergyLevel.medium:
        return Colors.orange;
      case EnergyLevel.low:
        return Colors.green;
    }
  }

  // 专注度颜色
  Color _getFocusColor(FocusLevel level) {
    switch (level) {
      case FocusLevel.deep:
        return Colors.purple;
      case FocusLevel.medium:
        return Colors.indigo;
      case FocusLevel.light:
        return Colors.teal;
    }
  }

  // 格式化截止日期
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';                              // 原来是 '已过期'
    } else if (difference.inDays == 0) {
      return 'Today';                                // 原来是 '今天'
    } else if (difference.inDays == 1) {
      return 'Tomorrow';                             // 原来是 '明天'
    } else if (difference.inDays <= 7) {
      return 'In ${difference.inDays} days';         // 原来是 '${difference.inDays}天后'
    } else {
      return '${deadline.month}/${deadline.day}';    // 原来是 '${deadline.month}月${deadline.day}日'
    }
  }
}