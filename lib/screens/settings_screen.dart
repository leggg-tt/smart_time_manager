import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_block_provider.dart';
import '../models/user_time_block.dart';
import '../widgets/time_block_list_item.dart';
import '../widgets/add_time_block_dialog.dart';
import '../widgets/pomodoro_settings_dialog.dart';
import '../widgets/scheduler_preferences_dialog.dart';

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
                Tab(text: 'Time Blocks'),     // 原来是 '时间块设置'
                Tab(text: 'General'),         // 原来是 '通用设置'
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
                            'About Time Blocks',            // 原来是 '关于时间块'
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time blocks help you define energy and focus levels for different periods. '
                            'The system uses this information to intelligently recommend task scheduling.',
                        // 原来是 '时间块帮助您定义不同时段的能量和专注度水平，系统会根据这些信息智能推荐任务安排。'
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
                    'My Time Blocks',                     // 原来是 '我的时间块'
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => _showAddTimeBlockDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add time block',            // 原来是 '添加时间块'
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
            'No time blocks configured',              // 原来是 '还没有设置时间块'
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddTimeBlockDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Time Block'),       // 原来是 '添加时间块'
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
        title: const Text('Delete Time Block'),         // 原来是 '删除时间块'
        content: Text('Are you sure you want to delete "${block.name}"?'), // 原来是 '确定要删除"${block.name}"吗？'
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),               // 原来是 '取消'
          ),
          TextButton(
            onPressed: () {
              provider.deleteTimeBlock(block.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time block deleted')), // 原来是 '时间块已删除'
              );
            },
            child: const Text('Delete'),               // 原来是 '删除'
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
                title: const Text('Task Reminders'),     // 原来是 '任务提醒'
                subtitle: const Text('Remind before task starts'), // 原来是 '在任务开始前提醒'
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
                title: const Text('Working Hours'),       // 原来是 '工作时间'
                subtitle: const Text('9:00 AM - 6:00 PM'), // 改为12小时制
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement working hours settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Lunch Break'),         // 原来是 '午休时间'
                subtitle: const Text('12:00 PM - 1:00 PM'), // 改为12小时制
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
                title: const Text('Theme'),               // 原来是 '主题设置'
                subtitle: const Text('Follow System'),    // 原来是 '跟随系统'
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement theme settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),            // 原来是 '语言'
                subtitle: const Text('English'),          // 原来是 '简体中文'
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
                title: const Text('About'),               // 原来是 '关于'
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Smart Time Manager',  // 原来是 '智能时间管理'
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 Smart Time Manager',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}