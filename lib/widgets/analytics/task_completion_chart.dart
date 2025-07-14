import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TaskCompletionChart extends StatefulWidget {
  final Map<String, dynamic> data;

  const TaskCompletionChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<TaskCompletionChart> createState() => _TaskCompletionChartState();
}

class _TaskCompletionChartState extends State<TaskCompletionChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.data['completionRate'] as double,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.data['completedTasks'] as int;
    final total = widget.data['totalTasks'] as int;
    final pending = total - completed;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左侧：饼图
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 0,
                          centerSpaceRadius: 25,
                          sections: [
                            PieChartSectionData(
                              value: _animation.value,
                              title: '',
                              color: Theme.of(context).colorScheme.primary,
                              radius: 15,
                            ),
                            PieChartSectionData(
                              value: 100 - _animation.value,
                              title: '',
                              color: Colors.grey.shade200,
                              radius: 15,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_animation.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // 右侧：统计信息（简化版）
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Completion',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCompactStat('Total', total, Colors.blue),
                      _buildCompactStat('Done', completed, Colors.green),
                      _buildCompactStat('Todo', pending, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}