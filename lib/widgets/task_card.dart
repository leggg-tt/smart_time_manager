import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final Function(TaskStatus)? onStatusChanged;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
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
              // Completion status checkbox
              if (onStatusChanged != null)
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    if (value == true) {
                      onStatusChanged?.call(TaskStatus.completed);
                    } else {
                      onStatusChanged?.call(TaskStatus.scheduled);
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

              // Task content
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? Theme.of(context).textTheme.titleSmall?.color?.withOpacity(0.5)
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Task category icon
                        Text(
                          task.taskCategory.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Property tags row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Duration tag
                        _buildChip(
                          context,
                          Icons.schedule,
                          task.durationDisplay,
                          Colors.blue,
                        ),

                        // Energy requirement tag
                        _buildChip(
                          context,
                          Icons.battery_full,
                          task.energyRequired.displayName,
                          _getEnergyColor(task.energyRequired),
                        ),

                        // Focus requirement tag
                        _buildChip(
                          context,
                          Icons.center_focus_strong,
                          task.focusRequired.displayName,
                          _getFocusColor(task.focusRequired),
                        ),

                        // Deadline tag (if exists)
                        if (task.deadline != null && !isCompleted)
                          _buildChip(
                            context,
                            Icons.event,
                            _formatDeadline(task.deadline!),
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

  Widget _buildChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
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