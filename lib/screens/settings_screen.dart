import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_block_provider.dart';
import '../providers/task_provider.dart';
import '../models/user_time_block.dart';
import '../widgets/time_block_list_item.dart';
import '../widgets/add_time_block_dialog.dart';
import '../widgets/pomodoro_settings_dialog.dart';
import '../widgets/scheduler_preferences_dialog.dart';
import '../services/test_data_generator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Time Blocks'),
                Tab(text: 'General'),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TimeBlockSettings(),
            _GeneralSettings(),
          ],
        ),
      ),
    );
  }
}

class _TimeBlockSettings extends StatelessWidget {
  const _TimeBlockSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeBlockProvider>(
      builder: (context, provider, child) {
        final timeBlocks = provider.timeBlocks;

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About Time Blocks',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time blocks help you define energy and focus levels for different periods. '
                            'The system uses this information to intelligently recommend task scheduling.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Time Blocks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => _showAddTimeBlockDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add time block',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (timeBlocks.isEmpty)
                _buildEmptyState(context)
              else
                ...timeBlocks.map((block) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimeBlockListItem(
                    timeBlock: block,
                    onTap: () => _editTimeBlock(context, block),
                    onToggle: () => provider.toggleTimeBlockActive(block.id),
                    onDelete: block.isDefault
                        ? null
                        : () => _deleteTimeBlock(context, provider, block),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No time blocks configured',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddTimeBlockDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Time Block'),
          ),
        ],
      ),
    );
  }

  void _showAddTimeBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeBlockDialog(),
    );
  }

  void _editTimeBlock(BuildContext context, UserTimeBlock block) {
    showDialog(
      context: context,
      builder: (context) => AddTimeBlockDialog(timeBlock: block),
    );
  }

  void _deleteTimeBlock(
      BuildContext context,
      TimeBlockProvider provider,
      UserTimeBlock block,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Block'),
        content: Text('Are you sure you want to delete "${block.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTimeBlock(block.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time block deleted')),
              );
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Pomodoro Timer'),
                subtitle: const Text('Customize work and break durations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const PomodoroSettingsDialog(),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Scheduling Algorithm'),
                subtitle: const Text('Adjust how tasks are automatically scheduled'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SchedulerPreferencesDialog(),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Task Reminders'),
                subtitle: const Text('Remind before task starts'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement reminder settings
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Working Hours'),
                subtitle: const Text('9:00 AM - 6:00 PM'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement working hours settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Lunch Break'),
                subtitle: const Text('12:00 PM - 1:00 PM'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement lunch break settings
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Theme'),
                subtitle: const Text('Follow System'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement theme settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement language settings
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Smart Time Manager',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 Smart Time Manager',
                  );
                },
              ),
            ],
          ),
        ),
        // Add developer options section at the bottom
        if (true) ...[  // You can change to kDebugMode for production
          const SizedBox(height: 32),
          Card(
            color: Colors.orange.shade50,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.developer_mode, color: Colors.orange),
                  title: const Text(
                    'Developer Options',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Test data generation for development'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Generate Test Data'),
                  subtitle: const Text('Create sample tasks for testing'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTestDataDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('Clear All Tasks'),
                  subtitle: const Text('Remove all tasks from database'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearDataDialog(context),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _TestDataGeneratorDialog(),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks?'),
        content: const Text(
          'This will permanently delete all tasks from the database. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final generator = TestDataGenerator();
              await generator.clearAllTasks();

              // Reload tasks
              if (context.mounted) {
                context.read<TaskProvider>().loadTasks();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All tasks cleared')),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Test data generator dialog - 改进版
class _TestDataGeneratorDialog extends StatefulWidget {
  @override
  State<_TestDataGeneratorDialog> createState() => _TestDataGeneratorDialogState();
}

class _TestDataGeneratorDialogState extends State<_TestDataGeneratorDialog> {
  int _daysBack = 7;  // 改为7天
  int _tasksPerDay = 3;  // 改为每天3个任务
  double _completionRate = 0.75;
  bool _includePomodoros = true;
  bool _useRealisticPatterns = true;  // 新增：真实模式
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Test Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure test data generation parameters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test tasks will be marked with [TEST] prefix',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Days back
            Text('Days to generate: $_daysBack'),
            Slider(
              value: _daysBack.toDouble(),
              min: 3,
              max: 30,
              divisions: 27,
              label: '$_daysBack days',
              onChanged: (value) {
                setState(() => _daysBack = value.round());
              },
            ),

            // Tasks per day
            Text('Tasks per day: $_tasksPerDay'),
            Slider(
              value: _tasksPerDay.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_tasksPerDay tasks',
              onChanged: (value) {
                setState(() => _tasksPerDay = value.round());
              },
            ),

            // Completion rate
            Text('Completion rate: ${(_completionRate * 100).toStringAsFixed(0)}%'),
            Slider(
              value: _completionRate,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_completionRate * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() => _completionRate = value);
              },
            ),

            // Options
            SwitchListTile(
              title: const Text('Include Pomodoro data'),
              subtitle: const Text('Add time tracking info to completed tasks'),
              value: _includePomodoros,
              onChanged: (value) {
                setState(() => _includePomodoros = value);
              },
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Realistic patterns'),
              subtitle: const Text('Vary task count by day of week'),
              value: _useRealisticPatterns,
              onChanged: (value) {
                setState(() => _useRealisticPatterns = value);
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            // 预计生成数量
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.assessment, color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimated: ~${_calculateEstimatedTasks()} tasks will be generated',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateData,
          child: _isGenerating
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Generate'),
        ),
      ],
    );
  }

  int _calculateEstimatedTasks() {
    // 计算工作日数量（假设5天工作制）
    final workDays = (_daysBack * 5 / 7).round();
    final baseTasks = workDays * _tasksPerDay;

    // 如果使用真实模式，增加一些变化
    if (_useRealisticPatterns) {
      return baseTasks + (baseTasks * 0.1).round() + 3; // +10% 变化 + 3天未来任务
    }

    return baseTasks + 3; // + 3天未来任务
  }

  Future<void> _generateData() async {
    setState(() => _isGenerating = true);

    try {
      final generator = TestDataGenerator();
      await generator.generateTestData(
        daysBack: _daysBack,
        tasksPerDay: _tasksPerDay,
        completionRate: _completionRate,
        includePomodoros: _includePomodoros,
        useRealisticPatterns: _useRealisticPatterns,
      );

      if (mounted) {
        // 重新加载任务
        context.read<TaskProvider>().loadTasks();

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ~${_calculateEstimatedTasks()} test tasks'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // 可以导航到任务列表页面
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}