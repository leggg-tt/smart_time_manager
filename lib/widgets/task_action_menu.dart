import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../screens/pomodoro_screen.dart';

class TaskActionMenu extends StatelessWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const TaskActionMenu({
    Key? key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 检查任务是否已完成
    final isCompleted = task.status == TaskStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Task Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Task name
          Text(
            task.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Action items
          // 只有未完成的任务才能启动番茄钟
          if (!isCompleted)
            _buildActionItem(
              context,
              icon: Icons.local_fire_department,
              title: 'Start Task',
              subtitle: 'Use Pomodoro Timer to focus',
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PomodoroScreen(task: task),
                  ),
                );
              },
            ),

          // 只有未完成的任务才能编辑
          if (onEdit != null && !isCompleted)
            _buildActionItem(
              context,
              icon: Icons.edit,
              title: 'Edit Task',
              subtitle: 'Modify task details',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).pop();
                onEdit!();
              },
            ),

          // 查看详情功能对所有任务都开放
          if (onViewDetails != null)
            _buildActionItem(
              context,
              icon: Icons.info_outline,
              title: 'View Details',
              subtitle: 'See complete task information',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).pop();
                onViewDetails!();
              },
            ),

          // 删除功能对所有任务都开放
          if (onDelete != null)
            _buildActionItem(
              context,
              icon: Icons.delete_outline,
              title: 'Delete Task',
              subtitle: 'Remove this task',
              color: Colors.red,
              onTap: () {
                Navigator.of(context).pop();
                onDelete!();
              },
            ),

          const SizedBox(height: 16),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}