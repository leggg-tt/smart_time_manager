import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // 【模板功能：新增导入】
import '../models/task.dart';
import '../models/enums.dart';
import '../screens/pomodoro_screen.dart';
import '../providers/task_provider.dart';  // 【模板功能：新增导入】

// 定义任务操作菜单
class TaskActionMenu extends StatelessWidget {
  final Task task;  // 要操作的任务对象
  final VoidCallback? onEdit;  // 可选回调,编辑任务时调用
  final VoidCallback? onDelete;  // 可选回调,删除任务时调用
  final VoidCallback? onViewDetails;  // 可选回调,查看详情时调用(功能还没做,不确定后面加不加)

  // 构造函数
  const TaskActionMenu({
    Key? key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  }) : super(key: key);

  // 构建UI核心方法
  @override
  Widget build(BuildContext context) {
    // 检查任务是否已完成
    final isCompleted = task.status == TaskStatus.completed;

    // 跟容器:垂直内边距20
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      // 列布局
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // 40*4横条,灰色背景
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),  // 圆角2像素
            ),
          ),
          const SizedBox(height: 20),  // 20像素垂直间距

          // 标题文本
          Text(
            'Task Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Task name
          Text(
            task.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.7)
            ),
            maxLines: 2,  // 最多显示两行
            overflow: TextOverflow.ellipsis,  // 超出部分省略号
            textAlign: TextAlign.center,  // 文本居中对齐
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
              // 点击后关闭当前菜单,再导航到番茄始终界面
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

          // 【模板功能：新增保存为模板选项】
          _buildActionItem(
            context,
            icon: Icons.bookmark_add,
            title: 'Save as Template',
            subtitle: 'Reuse this task configuration',
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).pop();
              _saveAsTemplate(context);
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

          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // 【模板功能：保存为模板方法】
  void _saveAsTemplate(BuildContext context) {
    context.read<TaskProvider>().saveTaskAsTemplate(task);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task saved as template'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 统一样式操作项
  Widget _buildActionItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    // 使用ListTile组件
    return ListTile(
      // 左侧图标容器
      leading: Container(
        padding: const EdgeInsets.all(8),  // 8像素内边距
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
          borderRadius: BorderRadius.circular(8),  // 8像素圆角
        ),
        // 图标使用传入的颜色
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}