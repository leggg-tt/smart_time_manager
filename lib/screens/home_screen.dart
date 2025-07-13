import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/time_block_provider.dart';
import 'calendar_screen.dart';
import 'task_list_screen.dart';
import 'analytics_screen.dart';  // 新增
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 更新页面列表，添加AnalyticsScreen
  List<Widget> get _screens => [
    const CalendarScreen(),
    const TaskListScreen(),
    const AnalyticsScreen(),  // 新增
    const SettingsScreen(),
  ];

  // 更新标题列表
  final List<String> _titles = const [
    'Calendar View',
    'Task List',
    'Analytics',  // 新增
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // 初始化加载数据
    Future.microtask(() {
      context.read<TaskProvider>().loadTasks();
      context.read<TimeBlockProvider>().loadTimeBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            selectedIcon: Icon(Icons.calendar_today, color: Colors.blue),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list, color: Colors.blue),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),  // 新增
            selectedIcon: Icon(Icons.analytics, color: Colors.blue),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings, color: Colors.blue),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}