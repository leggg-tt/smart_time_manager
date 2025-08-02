import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../providers/task_provider.dart';

class ExampleTasksDialog extends StatelessWidget {
  const ExampleTasksDialog({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> exampleTasks = const [
    {
      'title': '📊 Prepare Quarterly Report',
      'description': 'High priority analytical task best scheduled in morning',
      'duration': 120,
      'priority': Priority.high,
      'energy': EnergyLevel.high,
      'focus': FocusLevel.deep,
      'category': TaskCategory.analytical,
      'explanation': 'This task requires deep thinking and high energy, perfect for morning time blocks (8-11 AM)',
    },
    {
      'title': '📧 Reply to Emails',
      'description': 'Low energy communication task for afternoon',
      'duration': 30,
      'priority': Priority.medium,
      'energy': EnergyLevel.low,
      'focus': FocusLevel.light,
      'category': TaskCategory.communication,
      'explanation': 'Email tasks work well in low-energy periods like post-lunch (2-3 PM)',
    },
    {
      'title': '🎨 Design New Logo',
      'description': 'Creative task requiring high focus',
      'duration': 90,
      'priority': Priority.high,
      'energy': EnergyLevel.high,
      'focus': FocusLevel.deep,
      'category': TaskCategory.creative,
      'explanation': 'Creative work needs your peak mental state, ideal for morning golden hours',
    },
    {
      'title': '📝 Update Documentation',
      'description': 'Routine task for medium energy periods',
      'duration': 45,
      'priority': Priority.low,
      'energy': EnergyLevel.medium,
      'focus': FocusLevel.medium,
      'category': TaskCategory.routine,
      'explanation': 'Routine tasks fit well in medium-energy slots like late morning (11-12 PM)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Example Tasks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Click any example to see how tasks match with time blocks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: exampleTasks.length,
                itemBuilder: (context, index) {
                  final example = exampleTasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(example['priority']),
                        child: Text(
                          example['title'].toString().substring(0, 2),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(example['title']),
                      subtitle: Text(example['description']),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAttributeChips(context, example),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        example['explanation'],
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _createExampleTask(context, example),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Try This Example'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeChips(BuildContext context, Map<String, dynamic> example) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(
            'Priority: ${(example['priority'] as Priority).displayName}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getPriorityColor(example['priority']).withOpacity(0.2),
        ),
        Chip(
          label: Text(
            'Energy: ${(example['energy'] as EnergyLevel).displayName}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.orange.withOpacity(0.2),
        ),
        Chip(
          label: Text(
            'Focus: ${(example['focus'] as FocusLevel).displayName}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.purple.withOpacity(0.2),
        ),
        Chip(
          label: Text(
            '${example['duration']} min',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.grey.withOpacity(0.2),
        ),
      ],
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  void _createExampleTask(BuildContext context, Map<String, dynamic> example) {
    final task = Task(
      title: example['title'].toString().substring(2), // Remove emoji
      description: example['description'],
      durationMinutes: example['duration'],
      priority: example['priority'],
      energyRequired: example['energy'],
      focusRequired: example['focus'],
      taskCategory: example['category'],
    );

    context.read<TaskProvider>().addTask(task);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Example task "${task.title}" created!'),
        action: SnackBarAction(
          label: 'Schedule Now',
          onPressed: () {
            // This would trigger the scheduling dialog
          },
        ),
      ),
    );
  }
}