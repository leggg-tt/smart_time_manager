import 'package:flutter/material.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';

class TimeBlockListItem extends StatelessWidget {
  final UserTimeBlock timeBlock;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TimeBlockListItem({
    Key? key,
    required this.timeBlock,
    this.onTap,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(timeBlock.color.replaceAll('#', '0xFF')));

    return Card(
      elevation: timeBlock.isActive ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: timeBlock.isActive ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: color,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeBlock.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (timeBlock.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',                  // 原来是 '默认'
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timeBlock.startTime} - ${timeBlock.endTime}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    if (onToggle != null)
                      Switch(
                        value: timeBlock.isActive,
                        onChanged: (_) => onToggle!(),
                      ),
                    if (onDelete != null && !timeBlock.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        tooltip: 'Delete',                     // 原来是 '删除'
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Weekday display
                _buildWeekdayChips(context),

                const SizedBox(height: 12),

                // Feature tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureChip(
                      context,
                      Icons.battery_full,
                      'Energy: ${timeBlock.energyLevel.displayName}', // 原来是 '能量: ${timeBlock.energyLevel.displayName}'
                      _getEnergyColor(timeBlock.energyLevel),
                    ),
                    _buildFeatureChip(
                      context,
                      Icons.psychology,
                      'Focus: ${timeBlock.focusLevel.displayName}',   // 原来是 '专注: ${timeBlock.focusLevel.displayName}'
                      Colors.indigo,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Suitable task types
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suitable Task Types',                  // 原来是 '适合的任务类型'
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: timeBlock.suitableCategories.map((category) {
                        return Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                category.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),

                if (timeBlock.description != null && timeBlock.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    timeBlock.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayChips(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];  // 原来是 ['一', '二', '三', '四', '五', '六', '日']

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = timeBlock.daysOfWeek.contains(dayNumber);

        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeatureChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnergyColor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.high:
        return Colors.red;
      case EnergyLevel.medium:
        return Colors.orange;
      case EnergyLevel.low:
        return Colors.green;
    }
  }
}