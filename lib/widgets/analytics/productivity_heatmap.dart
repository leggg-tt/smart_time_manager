import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// 定义roductivityHeatmap有状态的组件
class ProductivityHeatmap extends StatefulWidget {
  // 接收一个数据列表作为参数,每个数据项是一个Map
  final List<Map<String, dynamic>> data;

  //构造函数
  const ProductivityHeatmap({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<ProductivityHeatmap> createState() => _ProductivityHeatmapState();
}

// 定义了hoveredHour变量,用于跟踪鼠标悬停在哪个小时格子上
class _ProductivityHeatmapState extends State<ProductivityHeatmap> {
  int? hoveredHour;

  // build方法
  @override
  Widget build(BuildContext context) {
    // 使用List.generate创建一个包含24个元素的列表
    final hourlyData = List.generate(24, (hour) {
      // 查找匹配的小时数据或创建默认
      for (final data in widget.data) {
        if (data['hour'] == hour) {
          return data;
        }
      }
      // 如果没有就返回默认值
      return {
        'hour': hour,
        'taskCount': 0,
        'completed': 0,
        'completionRate': 0.0,
      };
    });

    // 返回一个Card组件作为容器
    return Card(
      // 阴影高度为4
      elevation: 4,
      // 圆角矩形,圆角半径16像素
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 主标题
                    Text(
                      'Peak Productivity Hours',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 副标题
                    Text(
                      'Task completion rate by hour of day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                // 如果有鼠标悬停的小时,显示该小时的详细信息
                if (hoveredHour != null) _buildHourDetail(hourlyData[hoveredHour!]),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // 创建小时标签行,每3个小时显示一个标签
                      SizedBox(
                        height: 30,
                        child: Row(
                          children: List.generate(24, (hour) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  hour % 3 == 0 ? hour.toString() : '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // 热力图主体部分
                      Expanded(
                        child: Row(
                          children: List.generate(24, (hour) {
                            final data = hourlyData[hour];
                            final taskCount = data['taskCount'] as int;
                            final completionRate = data['completionRate'] as double;

                            return Expanded(
                              // MouseRegion组件用于检测鼠标悬停
                              child: MouseRegion(
                                // 鼠标进入时,设置hoveredHour
                                onEnter: (_) => setState(() => hoveredHour = hour),
                                // 鼠标离开时,清除hoveredHour
                                onExit: (_) => setState(() => hoveredHour = null),
                                // 动画容器
                                child: AnimatedContainer(
                                  // 动画时长200毫秒
                                  duration: const Duration(milliseconds: 200),
                                  // 边距2像素
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    // 颜色根据任务数和完成率决定
                                    color: _getHeatColor(taskCount, completionRate),
                                    // 圆角4像素
                                    borderRadius: BorderRadius.circular(4),
                                    // 悬停时显示边框,使用主题的主色调,宽度2像素
                                    border: hoveredHour == hour
                                        ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                        : null,
                                    // 悬停时添加阴影效果
                                    boxShadow: hoveredHour == hour
                                        ? [
                                      BoxShadow(
                                        // 主色调30%透明度
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        // 8像素
                                        blurRadius: 8,
                                        // 向下便宜2像素
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  // 格子中心显示任务数量
                                  child: Center(
                                    // 只有任务数大于0时才显示
                                    child: taskCount > 0
                                        ? Text(
                                      taskCount.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: completionRate > 50
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Color scale
                      _buildColorScale(context),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建悬停时显示的详细信息面板
  Widget _buildHourDetail(Map<String, dynamic> data) {
    final hour = data['hour'] as int;  // 时间,格式化为 HH:00
    final taskCount = data['taskCount'] as int;  // 任务总数
    final completed = data['completed'] as int;  // 完成数量
    final completionRate = data['completionRate'] as double;  // 完成率

    // 返回一个Container容器
    return Container(
      // 内边距12像素
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 使用主题的surfaceVariant颜色
        color: Theme.of(context).colorScheme.surfaceVariant,
        // 8像素圆角
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // 将小时数格式化为两位数
            '${hour.toString().padLeft(2, '0')}:00',
            // 使用titleMedium文字样式并加粗
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // 显示统计信息
          const SizedBox(height: 4),
          Text('Tasks: $taskCount'),  // 任务数量
          Text('Completed: $completed'),  // 完成数量
          Text('Rate: ${completionRate.toStringAsFixed(1)}%'),  // 完成率(保留一位小数)
        ],
      ),
    );
  }

  // 根据任务数和完成率返回对应的颜色
  Color _getHeatColor(int taskCount, double completionRate) {
    if (taskCount == 0) {
      return Colors.grey.shade100;
    }

    // 根据完成率返回不同颜色
    if (completionRate >= 80) {
      return Colors.green.shade600;
    } else if (completionRate >= 60) {
      return Colors.green.shade400;
    } else if (completionRate >= 40) {
      return Colors.yellow.shade600;
    } else if (completionRate >= 20) {
      return Colors.orange.shade400;
    } else {
      return Colors.red.shade400;
    }
  }

  // 构建颜色图例容器
  Widget _buildColorScale(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // 装饰设置
      decoration: BoxDecoration(
        // 使用主题的surfaceVariant颜色,50%透明度
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        // 圆角
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 显示标题
          Text(
            'Completion Rate:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          // 使用 Wrap 组件排列图例项
          Wrap(
            // 居中对齐
            alignment: WrapAlignment.center,
            // 水平间距4像素
            spacing: 4,
            // 行间距4像素
            runSpacing: 4,
            // 创建5个图例项,对应5个完成率区间
            children: [
              _buildScaleItem('0-20%', Colors.red.shade400),
              _buildScaleItem('20-40%', Colors.orange.shade400),
              _buildScaleItem('40-60%', Colors.yellow.shade600),
              _buildScaleItem('60-80%', Colors.green.shade400),
              _buildScaleItem('80-100%', Colors.green.shade600),
            ],
          ),
        ],
      ),
    );
  }

  // _buildScaleItem方法
  Widget _buildScaleItem(String label, Color color) {
    // 构建单个图例项,使用Row水平排列
    return Row(
      // 让Row只占用必要的空间
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // 12x12像素的正方形
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            // 传入的颜色参数
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}