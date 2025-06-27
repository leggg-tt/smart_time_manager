import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSchedule;

  const TaskListItem({
    Key? key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onSchedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                children: [
                  // 优先级指示器
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 任务信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 操作按钮
                  if (onSchedule != null)
                    IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: onSchedule,
                      tooltip: '安排时间',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      tooltip: '删除',
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 任务属性
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildPropertyChip(
                    context,
                    Icons.schedule,
                    task.durationDisplay,
                    Colors.blue,
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.category,
                    task.taskCategory.displayName,
                    Colors.purple,
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.flash_on,
                    '精力: ${task.energyRequired.displayName}',
                    _getEnergyColor(task.energyRequired),
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.psychology,
                    '专注: ${task.focusRequired.displayName}',
                    Colors.indigo,
                  ),
                  if (task.deadline != null)
                    _buildPropertyChip(
                      context,
                      Icons.event,
                      _formatDeadline(task.deadline!),
                      task.isOverdue ? Colors.red : Colors.orange,
                    ),
                  if (task.scheduledStartTime != null)
                    _buildPropertyChip(
                      context,
                      Icons.access_time,
                      _formatScheduledTime(task.scheduledStartTime!),
                      Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return '已过期';
    } else if (difference.inDays == 0) {
      return '今天截止';
    } else if (difference.inDays == 1) {
      return '明天截止';
    } else {
      return '${deadline.month}/${deadline.day} 截止';
    }
  }

  String _formatScheduledTime(DateTime time) {
    return '${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}