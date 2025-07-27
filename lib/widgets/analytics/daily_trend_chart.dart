import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// 定义DailyTrendChart有状态组件
class DailyTrendChart extends StatefulWidget {
  // data：接收的数据列表,每个元素是一个包含日期、任务数等信息的Map
  final List<Map<String, dynamic>> data;

  // 构造函数
  const DailyTrendChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  // 创建状态类实例
  @override
  State<DailyTrendChart> createState() => _DailyTrendChartState();
}

// 状态类定义
class _DailyTrendChartState extends State<DailyTrendChart> {
  // touchedIndex：记录当前触摸的柱状图索引,-1表示没有触摸
  int touchedIndex = -1;

  // build 方法开始
  @override
  Widget build(BuildContext context) {
    // 首先检查数据是否为空
    if (widget.data.isEmpty) {
      // 如果为空，返回一个显示"无数据"的卡片
      return const Card(
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    // 创建卡片容器
    return Card(
      // 卡片阴影高度
      elevation: 4,
      // 圆角矩形边框,圆角半径16
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // 卡片内容布局
      child: Padding(
        // 内边距20
        padding: const EdgeInsets.all(20),
        child: Column(
          // 使用列布,子元素左对齐
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行布局
            // 使用 Row 实现标题和图例的水平布局
            Row(
              // spaceBetween：两端对齐
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // 让标题占用剩余空间
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // 主标题
                        'Daily Activity Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 副标题
                      Text(
                        'Tasks created and completed over time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // 水平间距 8 像素
                const SizedBox(width: 8),
                // 调用_buildLegend方法构建图例
                _buildLegend(context),
              ],
            ),
            // 图表部分
            const SizedBox(height: 24),  // 顶部间距 24 像素
            // 让图表占用剩余垂直空间
            Expanded(
              // 创建柱状图
              child: BarChart(
                BarChartData(
                  // 柱状图均匀分布
                  alignment: BarChartAlignment.spaceAround,
                  // Y 轴最大值,通过_getMaxY()计算
                  maxY: _getMaxY(),
                  // 触摸交互配置
                  barTouchData: BarTouchData(
                    // 启用触摸功能
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      // 提示框内边距 8
                      tooltipPadding: const EdgeInsets.all(8),
                      // 提示框外边距 8
                      tooltipMargin: 8,
                      // 提示框内容生成
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        // 解析日期并格式化为"MMMd"（如"Jan 15"）
                        final date = DateTime.parse(widget.data[groupIndex]['date']);
                        final dateStr = DateFormat('MMM d').format(date);
                        final label = rodIndex == 0 ? 'Total' : 'Completed';
                        return BarTooltipItem(
                          '$dateStr\n$label: ${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    // 触摸事件处理
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      // 使用setState触发重绘
                      setState(() {
                        // 检查是否是有效的触摸事件
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          touchedIndex = -1;
                          return;
                        }
                        // 更新touchedIndex状态
                        touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    },
                  ),
                  // X轴标题配置
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // 检查索引防止越界
                          if (value.toInt() >= widget.data.length) return const Text('');
                          final date = DateTime.parse(widget.data[value.toInt()]['date']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              // 显示日期的天数
                              DateFormat('d').format(date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        // 预留 32 像素高度
                        reservedSize: 32,
                      ),
                    ),
                    // Y轴标题配置
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        // 显示标题
                        showTitles: true,
                        // 预留40像素宽度
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    // 隐藏顶部和右侧标题
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  // 边框配置
                  borderData: FlBorderData(
                    // 只显示左边和底边
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  // 生成柱状图数据
                  barGroups: _generateBarGroups(),
                  // 网格线配置
                  gridData: FlGridData(
                    // 只显示水平网格线
                    show: true,
                    drawVerticalLine: false,
                    // 分5个间隔
                    horizontalInterval: _getMaxY() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        // 网格线透明度 30%
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 计算Y轴最大值
  double _getMaxY() {
    // 使用fold找出最大任务数
    final maxTasks = widget.data.fold<int>(
      0,
          (max, item) => (item['taskCount'] as int) > max ? item['taskCount'] : max,
    );
    // 乘以1.2留出20%的空间
    return (maxTasks * 1.2).toDouble();
  }

  // 生成柱状图组数据
  List<BarChartGroupData> _generateBarGroups() {
    // asMap().entries：获取索引和值
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final dayData = entry.value;
      // 提取任务总数和完成数
      final taskCount = dayData['taskCount'] as int;
      final completed = dayData['completed'] as int;
      // 检查是否被触摸
      final isTouched = index == touchedIndex;

      // 第一根柱子（总任务数）
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: taskCount.toDouble(),
            color: Colors.blue.shade400,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: Colors.grey.shade100,
            ),
          ),
          // 第二根柱子（完成数）
          BarChartRodData(
            toY: completed.toDouble(),
            color: Colors.green.shade400,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0, 1] : [],
      );
    }).toList();
  }

  // 构建图例
  Widget _buildLegend(BuildContext context) {
    // 水平排列两个图例项
    return Row(
      children: [
        _buildLegendItem(context, 'Total', Colors.blue.shade400),
        // 间距16像素
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Completed', Colors.green.shade400),
      ],
    );
  }

  // 构建单个图例项
  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}