import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/enums.dart';

class CategoryDistributionChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const CategoryDistributionChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<CategoryDistributionChart> createState() => _CategoryDistributionChartState();
}

class _CategoryDistributionChartState extends State<CategoryDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Card(
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Category Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _generateSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final category = item['category'] as TaskCategory;
                          final count = item['count'] as int;
                          final isSelected = index == touchedIndex;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 8 : 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getCategoryColor(category).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                  color: _getCategoryColor(category),
                                  width: 2,
                                )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(category),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.icon,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
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

  List<PieChartSectionData> _generateSections() {
    final total = widget.data.fold<int>(
      0,
          (sum, item) => sum + (item['count'] as int),
    );

    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final category = item['category'] as TaskCategory;
      final count = item['count'] as int;
      final percentage = total > 0 ? (count / total * 100) : 0.0;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;

      return PieChartSectionData(
        color: _getCategoryColor(category),
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
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
        badgeWidget: isTouched
            ? Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
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
            category.icon,
            style: const TextStyle(fontSize: 16),
          ),
        )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

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