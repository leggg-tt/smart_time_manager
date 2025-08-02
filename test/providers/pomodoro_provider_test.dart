import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_time_manager/providers/pomodoro_provider.dart';
import 'package:smart_time_manager/providers/task_provider.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';
import 'package:smart_time_manager/services/pomodoro_settings_service.dart';
import 'package:smart_time_manager/services/scheduler_service.dart';
import 'package:smart_time_manager/services/task_template_service.dart';

// 模拟TaskProvider类
// 创建一个模拟的TaskProvider类,继承ChangeNotifier并实现TaskProvider接口
class MockTaskProvider extends ChangeNotifier implements TaskProvider {
  // 存储最后更新的任务
  Task? _lastUpdatedTask;
  // 存储所有任务的列表
  final List<Task> _tasks = [];
  // 存储模板列表
  final List<TaskTemplate> _templates = [];

  // getter方法,用于获取最后更新的任务
  Task? get lastUpdatedTask => _lastUpdatedTask;

  // 实现updateTask方法
  @override
  Future<void> updateTask(Task task) async {
    // 保存最后更新的任务
    _lastUpdatedTask = task;
    // 在任务列表中找到对应ID的任务并更新
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    // 通知所有监听器状态已改变
    notifyListeners();
  }

  // 返回所有任务
  @override
  List<Task> get tasks => _tasks;

  // 返回所有待处理状态的任务
  @override
  List<Task> get pendingTasks => _tasks.where((t) => t.status == TaskStatus.pending).toList();

  // 返回所有已完成的任务
  @override
  List<Task> get completedTasks => _tasks.where((t) => t.status == TaskStatus.completed).toList();

  // 筛选并返回所有已计划的任务
  @override
  List<Task> get scheduledTasks => _tasks.where((t) => t.status == TaskStatus.scheduled).toList();

  // 返回今天的任务,在测试中简化为返回空列表
  @override
  List<Task> get todayTasks => [];

  // 返回模板列表
  @override
  List<TaskTemplate> get templates => _templates;

  // 返回加载状态,测试中始终返回false表示不在加载中
  @override
  bool get isLoading => false;

  // 返回错误信息，测试中始终返回null表示没有错误
  @override
  String? get error => null;

  // 加载任务的方法,在测试中为空实现,因为任务已经在内存中
  @override
  Future<void> loadTasks() async {}

  // 加载今天任务的方法,测试中为空实现
  @override
  Future<void> loadTodayTasks() async {}

  // 加载模板的方法,测试中为空实现
  @override
  Future<void> loadTemplates() async {}

  // 保存任务为模板的方法
  @override
  Future<void> saveTaskAsTemplate(Task task) async {
    final template = TaskTemplate.fromTask(task);
    _templates.add(template);
    notifyListeners();
  }

  // 从模板创建任务的方法
  @override
  Future<void> createTaskFromTemplate(TaskTemplate template) async {
    final task = template.toTask();
    await addTask(task);
  }

  // 删除模板的方法
  @override
  Future<void> deleteTemplate(String templateId) async {
    _templates.removeWhere((t) => t.id == templateId);
    notifyListeners();
  }

  // 添加新任务
  @override
  Future<void> addTask(Task task) async {
    // 将任务添加到列表末尾
    _tasks.add(task);
    // 通知监听器更新UI
    notifyListeners();
  }

  // 删除任务
  @override
  Future<void> deleteTask(String id) async {
    // 删除所有满足条件的元素,删除ID匹配的任务
    _tasks.removeWhere((t) => t.id == id);
    // 通知更新
    notifyListeners();
  }


  // 切换任务状态的方法,测试中为空实现
  @override
  Future<void> toggleTaskStatus(Task task) async {}

  // 完成任务的方法
  @override
  Future<void> completeTask(String taskId) async {
    // 找到第一个匹配ID的任务
    final task = _tasks.firstWhere((t) => t.id == taskId);
    // 创建任务的副本并修改部分属性
    await updateTask(task.copyWith(
      // 设置状态为已完成
      status: TaskStatus.completed,
      // 设置完成时间为当前时间
      completedAt: DateTime.now(),
    ));
  }

  // 重新排序任务的方法
  @override
  Future<void> reorderTasks(int oldIndex, int newIndex) async {}

  // 获取特定日期的任务
  @override
  List<Task> getTasksForDate(DateTime date) => [];

  // 安排任务的方法,测试中始终返回true表示成功
  @override
  Future<bool> scheduleTask(Task task, DateTime scheduledTime) async => true;

  // 检查是否可以安排任务,测试中始终返回true
  @override
  Future<bool> canScheduleTask(Task task, DateTime startTime) async => true;

  // 获取推荐时间段,测试中返回空列表
  @override
  Future<List<TimeSlot>> getRecommendedSlots(Task task, DateTime date) async => [];

  // 获取时间分析数据,测试中返回空Map
  @override
  Future<Map<String, dynamic>> getTimeAnalysis(DateTime date) async => {};

  // 清除错误信息的方法
  @override
  void clearError() {}
}

// 主函数
void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 设置SharedPreferences的测试值
  setUpAll(() async {
    // 设置默认的番茄钟配置
    SharedPreferences.setMockInitialValues({
      'pomo_work_duration': 25,  // 25分钟工作时长
      'pomo_short_break': 5,     // 5分钟短休息
      'pomo_long_break': 15,     // 15分钟长休息
      'pomo_until_long': 4,      // 4个番茄钟后长休息
    });
  });

  // 创建测试任务的辅助方法
  Task createTestTask({
    String? id,
    String title = 'Test Task',
    int durationMinutes = 60,
    TaskStatus status = TaskStatus.pending,
    DateTime? actualStartTime,
  }) {
    return Task(
      id: id ?? 'test-task-1',
      title: title,
      durationMinutes: durationMinutes,
      priority: Priority.medium,
      energyRequired: EnergyLevel.medium,
      focusRequired: FocusLevel.medium,
      taskCategory: TaskCategory.routine,
      status: status,
      actualStartTime: actualStartTime,
    );
  }

  group('PomodoroProvider 初始化测试', () {
    test('初始状态应该正确', () {
      // 创建一个新的PomodoroProvider实例进行测试
      final provider = PomodoroProvider();

      // 验证初始状态是idle
      expect(provider.state, equals(PomodoroState.idle));
      // 验证当前没有进行中的任务
      expect(provider.currentTask, isNull);
      // 验证完成的番茄钟数量为0
      expect(provider.completedPomodoros, equals(0));
      // 验证总工作时间为0分钟
      expect(provider.totalWorkMinutes, equals(0));
      // 验证剩余秒数为1500秒（25分钟）
      expect(provider.remainingSeconds, equals(25 * 60));
    });

    // 测试时间格式化功能
    test('格式化时间应该正确显示', () {
      // 创建新的provider
      final provider = PomodoroProvider();

      // 验证格式化时间显示为"25:00"
      expect(provider.formattedTime, equals('25:00'));
    });
  });

  // 会话管理测试
  group('PomodoroProvider 会话管理测试', () {
    // 使用async异步测试
    test('开始会话应该正确初始化状态', () async {
      // 准备测试所需的三个对象
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 调用startSession方法开始番茄钟会话
      provider.startSession(task, mockTaskProvider);

      // 再次等待,确保startSession中的异步操作完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 当前任务不为空
      expect(provider.currentTask, isNotNull);
      // 当前任务ID匹配
      expect(provider.currentTask?.id, equals(task.id));
      // 状态变为working（工作中）
      expect(provider.state, equals(PomodoroState.working));
      // 完成的番茄钟数仍为0
      expect(provider.completedPomodoros, equals(0));
      // 总工作时间仍为0
      expect(provider.totalWorkMinutes, equals(0));
    });

    // 创建一个没有开始时间的任务
    test('开始会话应该更新任务状态', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask(actualStartTime: null);

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);

      // 等待异步操作完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 检查任务是否被更新
      // 有任务被更新
      expect(mockTaskProvider.lastUpdatedTask, isNotNull);
      // 状态变为inProgress
      expect(mockTaskProvider.lastUpdatedTask?.status, equals(TaskStatus.inProgress));
      // 设置了实际开始时间
      expect(mockTaskProvider.lastUpdatedTask?.actualStartTime, isNotNull);
    });
  });

  // 控制功能测试
  group('PomodoroProvider 控制功能测试', () {
    // 测试暂停功能
    test('暂停功能应该正确工作', () async {
      // 准备测试环境
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 暂停
      provider.pause();

      // 验证状态变为paused
      expect(provider.state, equals(PomodoroState.paused));
    });

    // 测试恢复功能
    test('恢复功能应该正确工作', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 暂停然后恢复
      provider.pause();
      // 验证暂停状态
      expect(provider.state, equals(PomodoroState.paused));

      // 调用start恢复
      provider.start();
      // 验证回到working状态
      expect(provider.state, equals(PomodoroState.working));
    });

    // 测试放弃功能
    test('放弃番茄钟应该重置状态', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 调用abandon方法
      provider.abandon();

      // 验证状态重置为idle
      expect(provider.state, equals(PomodoroState.idle));
    });

    // 测试跳过休息功能
    test('跳过休息功能测试', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask(durationMinutes: 50);

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于无法直接设置state为休息状态,这个测试跳过具体验证
      // 只测试方法可以被调用
      provider.skipBreak();

      // 如果不在休息状态,skipBreak不应该改变状态
      expect(provider.state, equals(PomodoroState.working));
    });
  });

  // 进度计算测试
  group('PomodoroProvider 进度计算测试', () {
    // 验证空闲状态下进度为0
    test('空闲状态进度应该为0', () {
      final provider = PomodoroProvider();
      expect(provider.progress, equals(0.0));
    });

    // 验证刚开始工作时进度为0
    test('工作状态进度初始应该为0', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 刚开始时进度应该为0
      expect(provider.progress, equals(0.0));
    });
  });

  // 任务完成测试
  group('PomodoroProvider 任务完成测试', () {
    test('完成任务应该更新任务状态', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 调用completeTask方法完成当前任务
      provider.completeTask(mockTaskProvider);

      // 检查任务是否被更新
      // 任务确实被更新了
      expect(mockTaskProvider.lastUpdatedTask, isNotNull);
      // 状态变为completed
      expect(mockTaskProvider.lastUpdatedTask?.status, equals(TaskStatus.completed));
      // 设置了实际结束时间
      expect(mockTaskProvider.lastUpdatedTask?.actualEndTime, isNotNull);
      // 设置了完成时间
      expect(mockTaskProvider.lastUpdatedTask?.completedAt, isNotNull);

      // 检查描述是否包含番茄钟统计
      expect(mockTaskProvider.lastUpdatedTask?.description, contains('Pomodoro: 0 completed'));
      expect(mockTaskProvider.lastUpdatedTask?.description, contains('Total work: 0 min'));

      // 检查状态是否重置
      expect(provider.state, equals(PomodoroState.idle));
      expect(provider.currentTask, isNull);
    });
  });

  // 番茄钟估算测试
  group('PomodoroProvider 番茄钟估算测试', () {
    test('估算番茄钟数量应该正确', () async {
      final provider = PomodoroProvider();

      // 等待初始化和设置加载
      await Future.delayed(const Duration(milliseconds: 200));

      // 25分钟任务需要1个番茄钟
      var task = createTestTask(durationMinutes: 25);
      expect(provider.getEstimatedPomodoros(task), equals(1));

      // 30分钟任务需要2个番茄钟
      task = createTestTask(durationMinutes: 30);
      expect(provider.getEstimatedPomodoros(task), equals(2));

      // 50分钟任务需要2个番茄钟
      task = createTestTask(durationMinutes: 50);
      expect(provider.getEstimatedPomodoros(task), equals(2));

      // 60分钟任务需要3个番茄钟
      task = createTestTask(durationMinutes: 60);
      expect(provider.getEstimatedPomodoros(task), equals(3));
    });
  });

  // 设置更新测试
  group('PomodoroProvider 设置更新测试', () {
    test('更新设置应该应用到当前状态', () async {
      final provider = PomodoroProvider();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 创建新设置
      final newSettings = PomodoroSettings(
        workDuration: 30,
        shortBreakDuration: 10,
        longBreakDuration: 20,
        pomodorosUntilLongBreak: 3,
      );

      await provider.updateSettings(newSettings);

      // 验证设置是否被保存
      expect(provider.settings, isNotNull);
      expect(provider.settings?.workDuration, equals(30));

      // 由于是空闲状态,remainingSeconds应该更新为新的工作时长
      expect(provider.remainingSeconds, equals(30 * 60));
    });
  });

  // 剩余工作时间测试
  group('PomodoroProvider 剩余工作时间测试', () {
    test('获取剩余工作分钟数应该正确', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();

      // 等待设置加载完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 测试不同的场景

      // 场景1：任务时长小于一个番茄钟
      var task = createTestTask(durationMinutes: 20);
      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      var remainingMinutes = provider.getRemainingWorkMinutes();
      expect(remainingMinutes, equals(20)); // 应该返回任务的全部时长

      provider.abandon(); // 重置状态

      // 场景2：任务时长大于一个番茄钟
      task = createTestTask(durationMinutes: 75);
      provider.startSession(task, mockTaskProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      remainingMinutes = provider.getRemainingWorkMinutes();
      // 应该被限制在一个番茄钟的时长内
      final workDurationMinutes = provider.remainingSeconds ~/ 60;
      expect(remainingMinutes, equals(workDurationMinutes));

      provider.abandon(); // 清理
    });

    test('没有任务时剩余工作分钟数应该为0', () {
      final provider = PomodoroProvider();
      expect(provider.getRemainingWorkMinutes(), equals(0));
    });
  });

  group('PomodoroProvider 定时器测试', () {
    test('开始会话应该启动定时器', () async {
      final provider = PomodoroProvider();
      final mockTaskProvider = MockTaskProvider();
      final task = createTestTask();

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      final initialSeconds = provider.remainingSeconds;
      provider.startSession(task, mockTaskProvider);

      // 等待1秒多一点，确保定时器执行
      await Future.delayed(const Duration(milliseconds: 1100));

      // remainingSeconds应该减少
      expect(provider.remainingSeconds, lessThan(initialSeconds));

      // 清理：停止定时器
      provider.abandon();
    });
  });
}