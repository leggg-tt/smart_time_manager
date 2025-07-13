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
  int touchedIndex = -1;

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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Task Completion',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Chart
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
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
                                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                startDegreeOffset: -90,
                                sectionsSpace: 0,
                                centerSpaceRadius: 50,
                                sections: _buildSections(),
                              ),
                            ),
                            // Center text
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_animation.value.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Completion Rate',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Statistics
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnimatedStatCard(
                      context,
                      'Total',
                      total,
                      Colors.blue,
                      Icons.assignment,
                      0,
                    ),
                    _buildAnimatedStatCard(
                      context,
                      'Completed',
                      completed,
                      Colors.green,
                      Icons.check_circle,
                      100,
                    ),
                    _buildAnimatedStatCard(
                      context,
                      'Pending',
                      pending,
                      Colors.orange,
                      Icons.pending,
                      200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final completionRate = _animation.value;
    final isTouched0 = touchedIndex == 0;
    final isTouched1 = touchedIndex == 1;

    return [
      PieChartSectionData(
        value: completionRate,
        title: completionRate > 10 ? '${completionRate.toStringAsFixed(0)}%' : '',
        titleStyle: TextStyle(
          fontSize: isTouched0 ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: Theme.of(context).colorScheme.primary,
        radius: isTouched0 ? 30 : 25,
        titlePositionPercentageOffset: 0.5,
      ),
      PieChartSectionData(
        value: 100 - completionRate,
        title: (100 - completionRate) > 10 ? '${(100 - completionRate).toStringAsFixed(0)}%' : '',
        titleStyle: TextStyle(
          fontSize: isTouched1 ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
        color: Colors.grey.shade200,
        radius: isTouched1 ? 30 : 25,
        titlePositionPercentageOffset: 0.5,
      ),
    ];
  }

  Widget _buildAnimatedStatCard(
      BuildContext context,
      String label,
      int value,
      Color color,
      IconData icon,
      int delay,
      ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Container(
            constraints: const BoxConstraints(minWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}