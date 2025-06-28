import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/time_block_provider.dart';
import 'calendar_screen.dart';
import 'task_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});  // 添加 const 构造函数

  @override
  State<HomeScreen> createState() => _HomeScreenState();  // 使用 State<HomeScreen>
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 这些列表移到 build 方法内或者改为 getter
  List<Widget> get _screens => [
    const CalendarScreen(),  // 如果这些 Screen 支持 const，也加上
    const TaskListScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Calendar View',  // 原来是 '日历视图'
    'Task List',      // 原来是 '任务列表'
    'Settings',       // 原来是 '设置'
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
            label: 'Calendar',  // 原来是 '日历'
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list, color: Colors.blue),
            label: 'Tasks',     // 原来是 '任务'
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings, color: Colors.blue),
            label: 'Settings',  // 原来是 '设置'
          ),
        ],
      ),
    );
  }
}