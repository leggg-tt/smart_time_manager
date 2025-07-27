import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/enums.dart';

// 定义CategoryDistributionChart类
class CategoryDistributionChart extends StatefulWidget {
  // data:接收的数据列表,每个Map包含类别(category)和数量(count)信息
  final List<Map<String, dynamic>> data;

  // 构造函数
  const CategoryDistributionChart({
    Key? key,
    // 必需参数,传入要显示的数据
    required this.data,
    // 调用父类构造函数
  }) : super(key: key);

  @override
  State<CategoryDistributionChart> createState() => _CategoryDistributionChartState();
}

class _CategoryDistributionChartState extends State<CategoryDistributionChart> {
  // touchedIndex:记录当前被触摸的饼图扇区索引,-1表示没有触摸
  int touchedIndex = -1;

  // build方法
  @override
  Widget build(BuildContext context) {
    // 首先检查数据是否为空
    if (widget.data.isEmpty) {
      return const Card(
        child: Center(
          // 如果为空,显示"No data available"提示
          child: Text('No data available'),
        ),
      );
    }

    // 主体card组件
    return Card(
      // 卡片阴影深度
      elevation: 4,
      // 圆角矩形边框,16像素圆角
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        // 卡片内容
        padding: const EdgeInsets.all(20),  // 20像素内边距
        // 垂直布局
        child: Column(
          // 左对齐
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // 使用大标题样式并加粗
              'Task Category Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // 24像素间距
            const SizedBox(height: 24),
            // Expanded确保占满剩余空间
            Expanded(
              child: Row(
                children: [
                  // 水平布局（饼图 + 图例）
                  Expanded(
                    flex: 2,  // 占据2/3的宽度
                    // 使用PieChart组件绘制饼图
                    child: PieChart(
                      PieChartData(
                        // 监听饼图触摸事件
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // 触发UI重建,实现交互效果
                            setState(() {
                              // 如果没有有效触摸,设置touchedIndex为-1
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              // 否则更新touchedIndex为触摸的扇区索引
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),  // 不显示边框
                        sectionsSpace: 2,  // 扇区之间2像素间距
                        centerSpaceRadius: 40,  // 中心空白半径40（环形图效果）
                        sections: _generateSections(),  // 调用_generateSections()生成扇区数据
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 占据剩余1/3宽度
                  Expanded(
                    // SingleChildScrollView支持滚动（数据多时）
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // asMap().entries获取带索引的数据,提取类别和数量信息,判断是否被选中
                        children: widget.data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final category = item['category'] as TaskCategory;
                          final count = item['count'] as int;
                          final isSelected = index == touchedIndex;

                          // 图例项容器
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            // 实现动画效果
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                // 选中时增加水平内边距（8像素 vs 4像素）
                                horizontal: isSelected ? 8 : 4,
                                vertical: 4,
                              ),
                              // 选中状态样式
                              decoration: BoxDecoration(
                                // 选中时：淡色背景（10%透明度）
                                color: isSelected
                                    ? _getCategoryColor(category).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),  // 八像素圆角
                                // 选中时：2像素彩色边框
                                border: isSelected
                                    ? Border.all(
                                  color: _getCategoryColor(category),
                                  width: 2,
                                )
                                    : null,
                              ),
                              // 图例色块和图标
                              child: Row(
                                children: [
                                  // 16x16像素的彩色方块
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(category),
                                      // 4像素圆角
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    // 中心显示类别图标
                                    child: Center(
                                      child: Text(
                                        category.icon,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  // 图里文本
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            // 类别名称：选中时加粗
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          // 任务数量
                                          '$count tasks',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 生成饼图扇区数据
  List<PieChartSectionData> _generateSections() {
    // 使用fold计算总任务数
    final total = widget.data.fold<int>(
      // 初始值0,累加每个类别的count
      0,
          (sum, item) => sum + (item['count'] as int),
    );

    // 扇区参数计算
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final category = item['category'] as TaskCategory;
      final count = item['count'] as int;
      // 计算百分比,避免除以0
      final percentage = total > 0 ? (count / total * 100) : 0.0;
      final isTouched = index == touchedIndex;
      // 触摸状态下与正常状态的不同显示
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;

      // 扇区配置
      return PieChartSectionData(
        // 颜色：根据类别获取
        color: _getCategoryColor(category),
        // 值：任务数量
        value: count.toDouble(),
        // 标题：百分比,保留1位小数
        title: '${percentage.toStringAsFixed(1)}%',
        // 白色加粗文字,带阴影效果
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              blurRadius: 2,
              color: Colors.black26,
              offset: Offset(1, 1),
            ),
          ],
        ),
        // 徽章（选中时显示）
        badgeWidget: isTouched
            ? Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            // 白色圆形容器
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            // 显示类别图标
            category.icon,
            style: const TextStyle(fontSize: 16),
          ),
        )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  // 颜色映射方法
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return Colors.purple.shade400;
      case TaskCategory.analytical:
        return Colors.blue.shade400;
      case TaskCategory.routine:
        return Colors.green.shade400;
      case TaskCategory.communication:
        return Colors.orange.shade400;
    }
  }
}