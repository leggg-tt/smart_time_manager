import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductivityHeatmap extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const ProductivityHeatmap({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<ProductivityHeatmap> createState() => _ProductivityHeatmapState();
}

class _ProductivityHeatmapState extends State<ProductivityHeatmap> {
  int? hoveredHour;

  @override
  Widget build(BuildContext context) {
    // Prepare data for heatmap
    final hourlyData = List.generate(24, (hour) {
      // Find matching hour data or create default
      for (final data in widget.data) {
        if (data['hour'] == hour) {
          return data;
        }
      }
      // Return default if not found
      return {
        'hour': hour,
        'taskCount': 0,
        'completed': 0,
        'completionRate': 0.0,
      };
    });

    return Card(
      elevation: 4,
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
                    Text(
                      'Peak Productivity Hours',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Task completion rate by hour of day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (hoveredHour != null) _buildHourDetail(hourlyData[hoveredHour!]),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Hour labels
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
                      // Heatmap
                      Expanded(
                        child: Row(
                          children: List.generate(24, (hour) {
                            final data = hourlyData[hour];
                            final taskCount = data['taskCount'] as int;
                            final completionRate = data['completionRate'] as double;

                            return Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => hoveredHour = hour),
                                onExit: (_) => setState(() => hoveredHour = null),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _getHeatColor(taskCount, completionRate),
                                    borderRadius: BorderRadius.circular(4),
                                    border: hoveredHour == hour
                                        ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                        : null,
                                    boxShadow: hoveredHour == hour
                                        ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Center(
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

  Widget _buildHourDetail(Map<String, dynamic> data) {
    final hour = data['hour'] as int;
    final taskCount = data['taskCount'] as int;
    final completed = data['completed'] as int;
    final completionRate = data['completionRate'] as double;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tasks: $taskCount'),
          Text('Completed: $completed'),
          Text('Rate: ${completionRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Color _getHeatColor(int taskCount, double completionRate) {
    if (taskCount == 0) {
      return Colors.grey.shade100;
    }

    // Calculate color based on completion rate
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

  Widget _buildColorScale(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Completion Rate:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
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

  Widget _buildScaleItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
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