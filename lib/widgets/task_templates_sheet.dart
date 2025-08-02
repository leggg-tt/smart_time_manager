import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/task_template_service.dart';
import '../models/enums.dart';

/// 任务模板管理底部弹窗
class TaskTemplatesSheet extends StatelessWidget {
  const TaskTemplatesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TaskProvider>().templates;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部手柄
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Task Templates',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    // 模板数量指示
                    if (templates.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${templates.length}/20',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    // 关闭按钮
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 模板列表
          Expanded(
            child: templates.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, template);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态界面
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No templates yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Long press any task to save as template',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建模板卡片
  Widget _buildTemplateCard(BuildContext context, TaskTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _useTemplate(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 类别图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(template.taskCategory).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(template.taskCategory),
                  color: _getCategoryColor(template.taskCategory),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // 模板信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // 时长
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 优先级
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(template.priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.priority.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getPriorityColor(template.priority),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 能量需求
                        Icon(
                          _getEnergyIcon(template.energyRequired),
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),

                        // 专注度需求
                        Icon(
                          _getFocusIcon(template.focusRequired),
                          size: 14,
                          color: Colors.blue,
                        ),
                      ],
                    ),

                    // 描述（如果有）
                    if (template.description != null && template.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          template.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // 操作菜单
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'use',
                    child: Row(
                      children: [
                        Icon(Icons.add_task),
                        SizedBox(width: 8),
                        Text('Use Template'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'use') {
                    _useTemplate(context, template);
                  } else if (value == 'delete') {
                    _deleteTemplate(context, template);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取类别图标
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return Icons.palette;
      case TaskCategory.analytical:
        return Icons.analytics;
      case TaskCategory.routine:
        return Icons.repeat;
      case TaskCategory.communication:
        return Icons.people;
    }
  }

  /// 获取类别颜色
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return Colors.purple;
      case TaskCategory.analytical:
        return Colors.blue;
      case TaskCategory.routine:
        return Colors.green;
      case TaskCategory.communication:
        return Colors.orange;
    }
  }

  /// 获取优先级颜色
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  /// 获取能量图标
  IconData _getEnergyIcon(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.high:
        return Icons.battery_full;
      case EnergyLevel.medium:
        return Icons.battery_5_bar;
      case EnergyLevel.low:
        return Icons.battery_3_bar;
    }
  }

  /// 获取专注度图标
  IconData _getFocusIcon(FocusLevel focus) {
    switch (focus) {
      case FocusLevel.deep:
        return Icons.visibility;
      case FocusLevel.medium:
        return Icons.remove_red_eye_outlined;
      case FocusLevel.light:
        return Icons.visibility_outlined;
    }
  }

  /// 使用模板创建任务
  void _useTemplate(BuildContext context, TaskTemplate template) {
    context.read<TaskProvider>().createTaskFromTemplate(template);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task created from template: ${template.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 删除模板
  void _deleteTemplate(BuildContext context, TaskTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text(
          'Are you sure you want to delete the template "${template.title}"?\n\n'
              'This will not affect any tasks created from this template.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTemplate(template.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Template deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}