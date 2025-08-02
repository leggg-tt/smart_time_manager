import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/time_block_provider.dart';
import 'calendar_screen.dart';
import 'task_list_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../widgets/example_tasks_dialog.dart';  // 【新增导入】

class HomeScreen extends StatefulWidget {  // 定义HomeScreen类,继承自有状态组件
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;  // 记录当前选中底部导航栏索引

  // 页面列表
  List<Widget> get _screens => [
    const CalendarScreen(),  // 日历界面
    const TaskListScreen(),  // 任务列表界面
    const AnalyticsScreen(),  // 分析统计界面
    const SettingsScreen(),  // 设置界面
  ];

  // 标题列表,用于AppBar显示
  final List<String> _titles = const [
    'Calendar View',
    'Task List',
    'Analytics',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // 初始化加载数据
    Future.microtask(() {  // 等界面渲染好了,再加载数据
      // 读取Provider实例并使用其中的加载方法
      context.read<TaskProvider>().loadTasks();
      context.read<TimeBlockProvider>().loadTimeBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 返回页面基础结构,Scaffold:顶部栏,主题内容,底部栏
    return Scaffold(
      // 顶部栏
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),  // 动态显示当前页面标题
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,  // 背景色
        // 【新增开始】- 添加 actions
        actions: [
          // 只在日历和任务页显示帮助按钮
          if (_currentIndex == 0 || _currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'View Examples',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ExampleTasksDialog(),
                );
              },
            ),
        ],
        // 【新增结束】
      ),
      // 主体内容
      body: IndexedStack(  // 保持所以界面的堆栈式布局
        index: _currentIndex,  // 只显示当前索引对应的页面
        children: _screens,
      ),
      //底部导航栏
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        // 点击回调,更新当前索引
        onDestinationSelected: (index) {
          // 触发界面重建
          setState(() {
            _currentIndex = index;
          });
        },
        // 导航项
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),  // 未选中时的图标
            selectedIcon: Icon(Icons.calendar_today, color: Colors.blue),  // 选中时的样子
            label: 'Calendar',  //标签文本
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list, color: Colors.blue),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
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