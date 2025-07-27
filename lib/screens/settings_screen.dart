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
import '../providers/theme_provider.dart';
import '../widgets/theme_selector_dialog.dart';
import '../widgets/ai_settings_dialog.dart';

// 主组件SettingsScreen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用DefaultTabController创建标签页布局
    return DefaultTabController(
      length: 2, // 两个标签页
      child: Scaffold(
        // PreferredSize用于自定义AppBar高度
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Time Blocks'),  // 时间块设置
                Tab(text: 'General'),  // 通用设置
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TimeBlockSettings(),  // 时间块设置页面
            _GeneralSettings(),  // 通用设置页面
          ],
        ),
      ),
    );
  }
}

//  时间块设置页面
class _TimeBlockSettings extends StatelessWidget {
  const _TimeBlockSettings({super.key});

  // 基本结构
  @override
  Widget build(BuildContext context) {
    return Consumer<TimeBlockProvider>(
      builder: (context, provider, child) {
        final timeBlocks = provider.allTimeBlocks;

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 信息卡片
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
                      // 显示时间块功能说明
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

              // 时间块列表头部
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 标题
                  Text(
                    'My Time Blocks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // 添加按钮
                  IconButton(
                    // 点击添加按钮显示新建时间块对话框
                    onPressed: () => _showAddTimeBlockDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add time block',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 时间块列表显示
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
                        ? null  // 默认时间块不能删除
                        : () => _deleteTimeBlock(context, provider, block),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  // 空状态显示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            // 按钮
            Icons.access_time,
            size: 64,
            // 使用半透明效果增强视觉层次
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            // 标题
            'No time blocks configured',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              // 使用半透明效果增强视觉层次
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

  // 添加时间块对话框
  void _showAddTimeBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeBlockDialog(),
    );
  }

  // 修改时间对话框
  void _editTimeBlock(BuildContext context, UserTimeBlock block) {
    showDialog(
      context: context,
      builder: (context) => AddTimeBlockDialog(timeBlock: block),
    );
  }

  // 删除时间块对话框
  void _deleteTimeBlock(
      BuildContext context,
      TimeBlockProvider provider,
      UserTimeBlock block,
      ) {
    showDialog(
      // 确认删除的对话框,防止误操作
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
              // 删除后显示 SnackBar 提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time block deleted')),
              );
            },
            child: const Text('Delete'),
            // 使用红色文字强调删除操作的危险性
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

// 通用设置页面(_GeneralSettings)
class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 主要设置选项
        Card(
          child: Column(
            children: [
              // 使用ListTile组件创建标准的设置项布局
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Pomodoro Timer'),
                subtitle: const Text('Customize work and break durations'),
                trailing: const Icon(Icons.chevron_right),
                // 点击后打开对应的设置对话框
                onTap: () {
                  showDialog(
                    context: context,
                    // 跳到番茄时钟自定义界面
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
                    // 跳到自定义任务调度页面
                    builder: (context) => const SchedulerPreferencesDialog(),
                  );
                },
              ),
              const Divider(height: 1),
              // 开关类设置(设置提醒功能,暂时还未实现)
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Task Reminders'),
                subtitle: const Text('Remind before task starts'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现任务提醒设置
                  },
                ),
              ),
              const Divider(height: 1),
              // AI 助手设置
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI Assistant'),
                subtitle: const Text('Configure AI behavior and preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AISettingsDialog(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 主题选择
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Theme'),
                subtitle: Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    return Text(provider.themeModeText);
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ThemeSelectorDialog(),
                  );
                },
              ),
              const Divider(height: 1),
              // 多种语言设置(暂时未实现)
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 实现多种语言设置
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
        // 开发者选项
        if (true) ...[  // 可以更改为kDebugMode以进行生产
          const SizedBox(height: 32),
          Card(
            color: Colors.orange.shade50,  // 橙色背景突出显示
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.developer_mode, color: Colors.orange),
                  title: const Text(
                    // 标题显示
                    'Developer Options',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Test data generation for development'),
                ),
                const Divider(height: 1),
                ListTile(
                  // 生成任务数据
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Generate Test Data'),
                  subtitle: const Text('Create sample tasks for testing'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTestDataDialog(context),
                ),
                ListTile(
                  // 清理所有任务数据
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

  // 测试数据生成界面
  void _showTestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _TestDataGeneratorDialog(),
    );
  }

  // 清空数据界面
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 使用AlertDialog提供确认界面
        title: const Text('Clear All Tasks?'),
        content: const Text(
          'This will permanently delete all tasks from the database. '
              'This action cannot be undone.',
        ),
        // 操作按钮
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            // 使用async/await异步处理数据库操作
            onPressed: () async {
              final generator = TestDataGenerator();
              await generator.clearAllTasks();

              // context.mounted检查:防止组件已卸载时操作context，避免内存泄漏
              if (context.mounted) {
                context.read<TaskProvider>().loadTasks();
                Navigator.of(context).pop();
                // 通过SnackBar提供操作结果反馈
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

// 测试数据生成器对话框
class _TestDataGeneratorDialog extends StatefulWidget {
  @override
  State<_TestDataGeneratorDialog> createState() => _TestDataGeneratorDialogState();
}

// 状态管理
// 定义测试数据生成的各种参数
// 使用有状态组件管理用户输入
class _TestDataGeneratorDialogState extends State<_TestDataGeneratorDialog> {
  int _daysBack = 7;  // 生成过去7天的数据
  int _tasksPerDay = 3;  // 每天3个任务
  double _completionRate = 0.75;  // 75%完成率
  bool _includePomodoros = true;  // 包含番茄钟数据
  bool _useRealisticPatterns = true;  // 使用真实模式
  bool _isGenerating = false;  // 生成中状态

  // UI构建
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 使用AlertDialog提供确认界面
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
                      // 告知用户测试数据会有 [TEST] 前缀标记
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

            // 天数选择滑块
            Text('Days to generate: $_daysBack'),
            Slider(
              value: _daysBack.toDouble(),
              min: 3,  // 最少3天
              max: 30,  // 最多30天
              divisions: 27,  // 30-3 = 27个分段
              label: '$_daysBack days',  // 拖动时显示的标签
              onChanged: (value) {
                // value.round():确保是整数天数
                setState(() => _daysBack = value.round());
              },
            ),

            // 每日任务数量滑块
            Text('Tasks per day: $_tasksPerDay'),
            Slider(
              value: _tasksPerDay.toDouble(),  // Slider 需要 double 类型值
              min: 1,  // 最少一个任务
              max: 7,  // 最多七个
              divisions: 6,  // 将 1-7 分成 6 段（7-1=6），每段代表1个任务
              label: '$_tasksPerDay tasks',  // 拖动时显示的悬浮提示
              onChanged: (value) {
                setState(() => _tasksPerDay = value.round());
              },
            ),

            // 完成率滑块
            // 百分比处理
            Text('Completion rate: ${(_completionRate * 100).toStringAsFixed(0)}%'),
            Slider(
              value: _completionRate,
              min: 0.0,
              max: 1.0,
              divisions: 10,  // 提供 0%, 10%, 20%...100% 共 11 个选项
              label: '${(_completionRate * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() => _completionRate = value);
              },
            ),

            // 番茄钟数据开关
            SwitchListTile(
              title: const Text('Include Pomodoro data'),
              subtitle: const Text('Add time tracking info to completed tasks'),
              value: _includePomodoros,
              // 模拟用户使用番茄钟功能的情况
              onChanged: (value) {
                setState(() => _includePomodoros = value);
              },
              contentPadding: EdgeInsets.zero,
            ),

            // 真实模式开关,开启后会模拟真实使用模式
            SwitchListTile(
              title: const Text('Realistic patterns'),
              subtitle: const Text('Vary task count by day of week'),
              // 周末任务较少,工作日任务较多,增加数据的真实性和多样性
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