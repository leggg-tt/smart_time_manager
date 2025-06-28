import 'package:flutter/material.dart';

class TimeAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const TimeAnalysisCard({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final freeBlockCount = analysis['freeBlockCount'] ?? 0;
    final totalFreeHours = analysis['totalFreeHours'] ?? 0.0;
    final fragmentCount = analysis['fragmentCount'] ?? 0;
    final hasDeepWorkTime = analysis['hasDeepWorkTime'] ?? false;
    final suggestion = analysis['suggestion'] ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Analysis',                        // 原来是 '时间分析'
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistics information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.timer,
                  '${totalFreeHours.toStringAsFixed(1)}h',  // 原来是 '${totalFreeHours.toStringAsFixed(1)}小时'
                  'Free Time',                              // 原来是 '空闲时间'
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  Icons.scatter_plot,
                  '$freeBlockCount',                        // 原来是 '$freeBlockCount个'
                  'Time Blocks',                            // 原来是 '时间块'
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  Icons.broken_image,
                  '$fragmentCount',                         // 原来是 '$fragmentCount个'
                  'Fragments',                              // 原来是 '碎片时间'
                  Colors.red,
                ),
                _buildStatItem(
                  context,
                  hasDeepWorkTime ? Icons.check_circle : Icons.cancel,
                  hasDeepWorkTime ? 'Yes' : 'No',           // 原来是 '有' : '无'
                  'Deep Focus',                             // 原来是 '深度时间'
                  hasDeepWorkTime ? Colors.green : Colors.grey,
                ),
              ],
            ),

            if (suggestion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
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

  Widget _buildStatItem(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}