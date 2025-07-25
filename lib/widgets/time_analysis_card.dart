import 'package:flutter/material.dart';

// 定义TimeAnalysisCard类(无状态组件不会在运行时改变)
class TimeAnalysisCard extends StatelessWidget {
  // 定义一个不可变的map类型变量analysis(用来存储时间分析数据)
  final Map<String, dynamic> analysis;

  // 构造函数
  const TimeAnalysisCard({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  // 覆写build方法,用于构建UI
  @override
  Widget build(BuildContext context) {
    final freeBlockCount = analysis['freeBlockCount'] ?? 0;  // 空闲时间快数量,默认为0
    final totalFreeHours = analysis['totalFreeHours'] ?? 0.0;  // 总空闲小时数,默认为0.0
    final fragmentCount = analysis['fragmentCount'] ?? 0;  // 碎片时间数量,默认为0
    final hasDeepWorkTime = analysis['hasDeepWorkTime'] ?? false;  // 是否有深度工作时间
    final suggestion = analysis['suggestion'] ?? '';  // 建议文本

    // 返回card组件
    return Card(
      // 设置四周边距为16像素
      margin: const EdgeInsets.all(16),
      child: Padding(
        // 添加16像素的内边距
        padding: const EdgeInsets.all(16),
        // 垂直布局容器
        child: Column(
          // 子组件在水平方向上左对齐
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 横向排列图标和文字
            Row(
              children: [
                Icon(
                  Icons.analytics,  // 显示分析图标和文字
                  color: Theme.of(context).colorScheme.primary,  // 使用主题的主色调
                ),
                // 图标和文字之间8像素水平间距
                const SizedBox(width: 8),
                Text(
                  'Time Analysis',  // 标题文字
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            // 垂直间距
            const SizedBox(height: 12),

            // 统计信息
            Row(
              // 组件在主轴上均匀分布(spaceAround)
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 私有方法_buildStatItem创建统计项
                _buildStatItem(
                  context,
                  Icons.timer,  // 计时器图标
                  '${totalFreeHours.toStringAsFixed(1)}h',  // 总空闲时间,保留一位小数
                  'Free Time',  // 标签
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  Icons.scatter_plot,  // 图标
                  '$freeBlockCount',  // 时间块数量
                  'Time Blocks',
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  Icons.broken_image,  // 图标
                  '$fragmentCount',  // 碎片时间数量
                  'Fragments',
                  Colors.red,
                ),
                _buildStatItem(
                  context,
                  hasDeepWorkTime ? Icons.check_circle : Icons.cancel,  // 图标(判断有没有)
                  hasDeepWorkTime ? 'Yes' : 'No',  // 是否有深度工作时间
                  'Deep Focus',
                  hasDeepWorkTime ? Colors.green : Colors.grey,
                ),
              ],
            ),

            // 只有建议文本不为空时,才显示建议部分
            if (suggestion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),  // 内边距12
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,  // 背景色
                  borderRadius: BorderRadius.circular(8),  // 圆角半径
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,  // 建议图标
                      color: Theme.of(context).colorScheme.onPrimaryContainer,  // 颜色
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    // 让文本占据剩余空间(Expanded)
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 私有辅助方法,构建单个统计项的方法,接收图标,数值,标签,颜色参数
  Widget _buildStatItem(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    // 统计项布局
    return Column(
      children: [
        // 图标
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),  // 四像素间距
        // 数值文本
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        // 标签文本
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),  // // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.7)
          ),
        ),
      ],
    );
  }
}