import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // 【模板功能：新增导入】
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';  // 【模板功能：新增导入】

// 定义TaskListItem类(无状态组件，不需要管理内部状态)
class TaskListItem extends StatelessWidget {
  final Task task;  // 任务对象,包含任务的所有信息
  final VoidCallback? onTap;  // 可选的点击回调函数
  final VoidCallback? onDelete;  // 可选的删除回调函数
  final VoidCallback? onSchedule;  // 可选的安排时间回调函数

  // 构造函数
  const TaskListItem({
    Key? key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onSchedule,
  }) : super(key: key);

  // 重写父类的build方法来构建UI
  @override
  Widget build(BuildContext context) {
    // 根据任务优先级获取对应的颜色
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      elevation: 1,  // 轻微阴影
      // 提供点击水波纹效果,圆角边框
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        // 【模板功能：添加长按菜单】
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(12),  // 内边距12像素
          // 垂直布局
          child: Column(
            // 子组件左对齐
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题信息和操作按钮
              Row(
                children: [
                  // 优先级指示器(左侧的彩色竖条,颜色根据任务优先级变化（红/橙/蓝）)
                  Container(
                    width: 4,  // 宽
                    height: 40,  // 高
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 任务信息
                  Expanded(
                    child: Column(
                      // 子组件左对齐
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,  // 最多显示1行
                          overflow: TextOverflow.ellipsis,  // 超出部分省略号显示
                        ),
                        // 任务描述(可选),只有不为null时才显示
                        if (task.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,  // 最多显示两行(文字较小)
                            overflow: TextOverflow.ellipsis,  // 超出部分省略号显示
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 【模板功能：修改操作按钮，添加更多菜单】
                  // 更多操作按钮（包含保存为模板选项）
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (BuildContext context) => [
                      // 如果有安排回调，显示安排选项
                      if (onSchedule != null)
                        const PopupMenuItem(
                          value: 'schedule',
                          child: Row(
                            children: [
                              Icon(Icons.schedule),
                              SizedBox(width: 8),
                              Text('Schedule'),
                            ],
                          ),
                        ),
                      // 保存为模板选项
                      const PopupMenuItem(
                        value: 'save_template',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_add),
                            SizedBox(width: 8),
                            Text('Save as Template'),
                          ],
                        ),
                      ),
                      // 如果有删除回调，显示删除选项
                      if (onDelete != null) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 任务属性
              Wrap(
                spacing: 8,  // 水平间距
                runSpacing: 4,  // 行间距
                children: [
                  // 调用 _buildPropertyChip 方法创建各种属性标签
                  _buildPropertyChip(
                    context,
                    Icons.schedule,  // 图标
                    task.durationDisplay,  // 任务持续时间
                    Colors.blue,  // 颜色
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.category,  // 图标
                    task.taskCategory.displayName,  // 任务类型
                    Colors.purple,  // 颜色
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.flash_on,  // 图标
                    'Energy: ${task.energyRequired.displayName}',  // 能量需求等级
                    _getEnergyColor(task.energyRequired),  // 对应等级获得对应颜色
                  ),
                  _buildPropertyChip(
                    context,
                    Icons.psychology,  // 图标
                    'Focus: ${task.focusRequired.displayName}',   // 专注等级
                    Colors.indigo,  // 颜色
                  ),
                  if (task.deadline != null)
                    _buildPropertyChip(
                      context,
                      Icons.event,  // 图标
                      _formatDeadline(task.deadline!),  // deadline显示
                      task.isOverdue ? Colors.red : Colors.orange,  // 颜色(先判断是否逾期)
                    ),
                  if (task.scheduledStartTime != null)
                    _buildPropertyChip(
                      context,
                      Icons.access_time,  // 图标
                      _formatScheduledTime(task.scheduledStartTime!),  // 计划开始时间
                      Colors.green,  // 颜色
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 【模板功能：新增长按菜单方法】
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSchedule != null)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    onSchedule!();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.bookmark_add),
                title: const Text('Save as Template'),
                onTap: () {
                  Navigator.pop(context);
                  _saveAsTemplate(context);
                },
              ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // 【模板功能：处理菜单操作】
  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'schedule':
        if (onSchedule != null) onSchedule!();
        break;
      case 'save_template':
        _saveAsTemplate(context);
        break;
      case 'delete':
        if (onDelete != null) onDelete!();
        break;
    }
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

  // 属性标签构建方法
  Widget _buildPropertyChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),  // 背景色,现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
        borderRadius: BorderRadius.circular(16),  // 完全圆角
        border: Border.all(
          color: color.withOpacity(0.3),  // 边框,现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.3)
          width: 1,
        ),
      ),
      child: Row(
        // Row只占用必要的宽度(mainAxisSize.min)
        mainAxisSize: MainAxisSize.min,
        children: [
          // 小图标
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          // 标签文字
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

  // 优先级颜色映射
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

  // 能量等级颜色映射：
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

  // 截止日期格式化
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due ${deadline.month}/${deadline.day}';
    }
  }

  // 已安排时间格式化
  String _formatScheduledTime(DateTime time) {
    return '${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}