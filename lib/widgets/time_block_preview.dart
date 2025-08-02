import 'package:flutter/material.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';

class TimeBlockPreview extends StatelessWidget {
  final UserTimeBlock timeBlock;
  final bool showExamples;

  const TimeBlockPreview({
    Key? key,
    required this.timeBlock,
    this.showExamples = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(timeBlock.color.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timeBlock.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    '${timeBlock.startTime} - ${timeBlock.endTime}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            if (timeBlock.description != null) ...[
              const SizedBox(height: 8),
              Text(
                timeBlock.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Characteristics
            Row(
              children: [
                _buildCharacteristic(
                  context,
                  Icons.battery_charging_full,
                  'Energy: ${timeBlock.energyLevel.displayName}',
                  _getEnergyColor(timeBlock.energyLevel),
                ),
                const SizedBox(width: 16),
                _buildCharacteristic(
                  context,
                  Icons.psychology,
                  'Focus: ${timeBlock.focusLevel.displayName}',
                  _getFocusColor(timeBlock.focusLevel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Suitable for
            Text(
              'Best for:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...timeBlock.suitableCategories.map((category) => Chip(
                  label: Text(
                    '${category.icon} ${category.displayName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
              ],
            ),
            if (showExamples) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Example tasks for this time:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._getExampleTasks().map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $example',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristic(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getEnergyColor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.high:
        return Colors.green;
      case EnergyLevel.medium:
        return Colors.orange;
      case EnergyLevel.low:
        return Colors.red;
    }
  }

  Color _getFocusColor(FocusLevel level) {
    switch (level) {
      case FocusLevel.deep:
        return Colors.purple;
      case FocusLevel.medium:
        return Colors.blue;
      case FocusLevel.light:
        return Colors.teal;
    }
  }

  List<String> _getExampleTasks() {
    if (timeBlock.energyLevel == EnergyLevel.high &&
        timeBlock.focusLevel == FocusLevel.deep) {
      return [
        'Strategic planning',
        'Complex problem solving',
        'Creative brainstorming',
        'Important presentations',
      ];
    } else if (timeBlock.energyLevel == EnergyLevel.low) {
      return [
        'Email responses',
        'Routine administrative tasks',
        'Simple data entry',
        'Casual team check-ins',
      ];
    } else {
      return [
        'Regular meetings',
        'Code reviews',
        'Documentation updates',
        'Task planning',
      ];
    }
  }
}