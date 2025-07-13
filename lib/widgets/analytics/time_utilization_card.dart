import 'package:flutter/material.dart';

class TimeUtilizationCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const TimeUtilizationCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<TimeUtilizationCard> createState() => _TimeUtilizationCardState();
}

class _TimeUtilizationCardState extends State<TimeUtilizationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final utilizationRate = widget.data['utilizationRate'] as double;
    // 限制进度条最大值为 1.0 (100%)
    final clampedRate = utilizationRate.clamp(0, 100) / 100;

    _progressAnimation = Tween<double>(
      begin: 0,
      end: clampedRate,
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
    final plannedHours = widget.data['plannedHours'] as double;
    final actualHours = widget.data['actualHours'] as double;
    final utilizationRate = widget.data['utilizationRate'] as double;
    final isOvertime = utilizationRate > 100;

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
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Utilization',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Actual vs Planned Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOvertime)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_off, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Overtime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Animated stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnimatedStat(
                    context,
                    'Planned',
                    plannedHours,
                    Colors.blue,
                    Icons.event_note,
                    0,
                  ),
                  _buildAnimatedStat(
                    context,
                    'Actual',
                    actualHours,
                    isOvertime ? Colors.orange : Colors.green,
                    isOvertime ? Icons.timer_off : Icons.check_circle,
                    200,
                  ),
                  _buildAnimatedStat(
                    context,
                    'Efficiency',
                    utilizationRate,
                    _getEfficiencyColor(utilizationRate),
                    isOvertime ? Icons.trending_down : Icons.trending_up,
                    400,
                    isPercentage: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress bar with animation (修改为支持超时显示)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Usage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${actualHours.toStringAsFixed(1)}h / ${plannedHours.toStringAsFixed(1)}h',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // 正常进度条
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                                    (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 100% 标记线
                          if (isOvertime)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (isOvertime) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          '100%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Insight message with overtime info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOvertime ? Icons.warning_amber : _getEfficiencyIcon(utilizationRate),
                      color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOvertime ? _getOvertimeMessage(utilizationRate) : _getEfficiencyMessage(utilizationRate),
                            style: TextStyle(
                              color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOvertime) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Overtime: ${(actualHours - plannedHours).toStringAsFixed(1)}h (${(utilizationRate - 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildAnimatedStat(
      BuildContext context,
      String label,
      double value,
      Color color,
      IconData icon,
      int delay, {
        bool isPercentage = false,
      }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Duration(milliseconds: 1000 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              isPercentage
                  ? '${animatedValue.toStringAsFixed(1)}%'
                  : '${animatedValue.toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEfficiencyColor(double rate) {
    if (rate > 100) return Colors.orange.shade600;  // 超时
    if (rate >= 90) return Colors.green.shade600;
    if (rate >= 70) return Colors.blue.shade600;
    if (rate >= 50) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  IconData _getEfficiencyIcon(double rate) {
    if (rate >= 90 && rate <= 100) return Icons.sentiment_very_satisfied;
    if (rate >= 70) return Icons.sentiment_satisfied;
    if (rate >= 50) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getEfficiencyMessage(double rate) {
    if (rate >= 90 && rate <= 100) return 'Excellent time management! Keep it up!';
    if (rate >= 70) return 'Good utilization. Room for improvement.';
    if (rate >= 50) return 'Consider optimizing your time estimates.';
    return 'Time estimates may need adjustment.';
  }

  String _getOvertimeMessage(double rate) {
    final overtimePercent = rate - 100;
    if (overtimePercent <= 20) return 'Slightly over time. Consider better estimation.';
    if (overtimePercent <= 50) return 'Significant overtime. Review task complexity.';
    return 'Major overtime! Break down tasks into smaller pieces.';
  }
}