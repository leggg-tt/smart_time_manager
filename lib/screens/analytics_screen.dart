import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../models/enums.dart';
import '../widgets/analytics/task_completion_chart.dart';
import '../widgets/analytics/category_distribution_chart.dart';
import '../widgets/analytics/productivity_heatmap.dart';
import '../widgets/analytics/daily_trend_chart.dart';
import '../widgets/analytics/priority_analysis_card.dart';
import '../widgets/analytics/time_utilization_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = '30d';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: _onPeriodChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 days')),
              const PopupMenuItem(value: 'custom', child: Text('Custom range')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 8),
                  Text(_getPeriodText()),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              _buildOverviewSection(),
              const SizedBox(height: 24),

              // Task Completion Chart
              _buildSectionTitle('Task Completion'),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _analyticsService.getTaskCompletionStats(
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return TaskCompletionChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Daily Trend
              _buildSectionTitle('Daily Activity Trend'),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getDailyTaskPattern(
                    days: _getDaysDifference(),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return DailyTrendChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Category Distribution
              _buildSectionTitle('Task Categories'),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getCategoryDistribution(
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return CategoryDistributionChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Priority Analysis
              _buildSectionTitle('Priority Analysis'),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _analyticsService.getPriorityDistribution(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: snapshot.data!
                        .map((data) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PriorityAnalysisCard(data: data),
                    ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Productivity Heatmap
              _buildSectionTitle('Peak Productivity Hours'),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getPeakProductivityHours(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ProductivityHeatmap(data: snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _analyticsService.getTimeUtilizationStats(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  return TimeUtilizationCard(data: snapshot.data!);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _analyticsService.getPomodoroStats(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pomodoro Stats',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                '${data['totalPomodoros']}',
                                'Pomodoros',
                                Icons.timer,
                              ),
                              _buildStatItem(
                                context,
                                '${(data['totalWorkHours'] as double).toStringAsFixed(1)}h',
                                'Focus Time',
                                Icons.schedule,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _onPeriodChanged(String period) async {
    if (period == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      );
      if (picked != null) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
          _selectedPeriod = period;
        });
      }
    } else {
      setState(() {
        _selectedPeriod = period;
        _endDate = DateTime.now();
        switch (period) {
          case '7d':
            _startDate = _endDate.subtract(const Duration(days: 7));
            break;
          case '30d':
            _startDate = _endDate.subtract(const Duration(days: 30));
            break;
          case '90d':
            _startDate = _endDate.subtract(const Duration(days: 90));
            break;
        }
      });
    }
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 90 days';
      case 'custom':
        final format = DateFormat('MMM d');
        return '${format.format(_startDate)} - ${format.format(_endDate)}';
      default:
        return 'Select period';
    }
  }

  int _getDaysDifference() {
    return _endDate.difference(_startDate).inDays;
  }
}