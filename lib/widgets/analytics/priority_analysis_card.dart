import 'package:flutter/material.dart';
import '../../models/enums.dart';

// 定义PriorityAnalysisCard无状态组件
class PriorityAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> data;

  // 构造函数
  const PriorityAnalysisCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从data Map中提取数据
    final priority = data['priority'] as Priority;  // 任务优先级（高/中/低）
    final count = data['count'] as int;  // 该优先级的任务总数
    final completed = data['completed'] as int;  // 已完成的任务数
    final completionRate = data['completionRate'] as double;  // 完成率百分比

    // 获取对应优先级的颜色：
    final color = _getPriorityColor(priority);

    // 创建卡片容器
    return Card(
      child: Padding(
        // 内边距16
        padding: const EdgeInsets.all(16),
        // 左侧彩色指示条
        child: Row(
          children: [
            Container(
              // 宽度4像素,高度60像素的竖条
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                // 颜色根据优先级动态设置
                color: color,
                // 圆角半径 2 像素
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 左边距 16 像素
            const SizedBox(width: 16),
            // 占据剩余水平空间
            Expanded(
              child: Column(
                // 使用列布局,左对齐
                crossAxisAlignment: CrossAxisAlignment.start,
                // 优先级标题
                children: [
                  Text(
                    // 显示优先级名称,使用displayName获取枚举的显示名称
                    '${priority.displayName} Priority',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // 任务总数文本
                  const SizedBox(height: 4),
                  Text(
                    // 显示该优先级的任务总数
                    '$count total tasks',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // 右侧完成率显示
            Column(
              // 右对齐的列布局
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 显示完成率百分比
                Text(
                  '${completionRate.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completed completed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 优先级颜色映射方法
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
}