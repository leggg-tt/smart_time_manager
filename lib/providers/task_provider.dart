import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/scheduler_service.dart';

//定义TaskProvider类
class TaskProvider with ChangeNotifier {
  //数据库服务的单例实例
  final DatabaseService _db = DatabaseService.instance;
  //调度服务实例
  final SchedulerService _scheduler = SchedulerService();

  List<Task> _tasks = [];  // 所有任务列表
  List<Task> _todayTasks = [];  // 今日任务列表
  bool _isLoading = false;  // 加载状态标志
  String? _error;  // 错误信息(可以为空)

  // 提供对私有变量的只读访问
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取未安排的任务(where过滤出pending)
  List<Task> get pendingTasks => _tasks
      .where((task) => task.status == TaskStatus.pending)
      .toList();

  // 获取已完成的任务(同上)
  List<Task> get completedTasks => _tasks
      .where((task) => task.status == TaskStatus.completed)
      .toList();

  // 加载任务
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 数据库查询(异步获取任务,用await等待结果)
    try {
      _tasks = await _db.getAllTasks();

      // 方便检查数据库任务信息用来调试,项目最后阶段需要删除
      print('\n========== 数据库所有任务 ==========');
      print('总共 ${_tasks.length} 个任务\n');

      for (var i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        print('【任务 ${i + 1}】');
        print('  id: ${task.id}');
        print('  title: ${task.title}');
        print('  description: ${task.description}');
        print('  status: ${task.status}');
        print('  priority: ${task.priority}');
        print('  durationMinutes: ${task.durationMinutes}');
        print('  deadline: ${task.deadline}');
        print('  scheduledStartTime: ${task.scheduledStartTime}');
        print('  actualStartTime: ${task.actualStartTime}');
        print('  actualEndTime: ${task.actualEndTime}');
        print('  completedAt: ${task.completedAt}');
        print('  energyRequired: ${task.energyRequired}');
        print('  focusRequired: ${task.focusRequired}');
        print('  taskCategory: ${task.taskCategory}');
        print('  createdAt: ${task.createdAt}');
        print('  updatedAt: ${task.updatedAt}');
        print('  preferredTimeBlockIds: ${task.preferredTimeBlockIds}');
        print('  avoidTimeBlockIds: ${task.avoidTimeBlockIds}');
        print('----------------------------\n');
      }
      print('====================================\n');

      await loadTodayTasks();
    } catch (e) {
      _error = '加载任务失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // 加载今日任务
  Future<void> loadTodayTasks() async {
    try {
      _todayTasks = await _db.getTasksByDate(DateTime.now());
      notifyListeners();
    } catch (e) {
      _error = '加载今日任务失败: $e';
      notifyListeners();
    }
  }

  // 添加新任务
  Future<void> addTask(Task task) async {
    try {
      await _db.insertTask(task);
      // 插入到本地列表开头
      _tasks.insert(0, task);

      // 检查新任务是否安排在今天,按开始时间排序
      if (task.scheduledStartTime != null &&
          _isSameDay(task.scheduledStartTime!, DateTime.now())) {
        _todayTasks.add(task);
        _todayTasks.sort((a, b) =>
            a.scheduledStartTime!.compareTo(b.scheduledStartTime!));
      }

      notifyListeners();
    } catch (e) {
      _error = '添加任务失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 更新任务
  Future<void> updateTask(Task task) async {
    try {
      // 更新数据库
      await _db.updateTask(task);

      // 找到本地列表任务位置并替换(indexWhere用来查找索引)
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }

      await loadTodayTasks();
      notifyListeners();
    } catch (e) {
      _error = '更新任务失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 检查任务是否可以安排到指定时间（用于手动安排时的冲突检测）
  Future<bool> canScheduleTask(Task task, DateTime startTime) async {
    try {
      return await _scheduler.canScheduleTask(task, startTime);
    } catch (e) {
      _error = '检查时间冲突失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 删除任务(从数据库,以及两个列表中移除.使用的是removeWhere)
  Future<void> deleteTask(String taskId) async {
    try {
      await _db.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _todayTasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = '删除任务失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 标记任务完成(使用copyWith方法)
  Future<void> completeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      actualEndTime: DateTime.now(),
    );

    await updateTask(updatedTask);
  }

  // 安排任务到指定时间
  Future<bool> scheduleTask(
      Task task,
      DateTime startTime,
      ) async {
    try {
      // 检查是否可以安排(是否有时间冲突)
      final canSchedule = await _scheduler.canScheduleTask(task, startTime);
      if (!canSchedule) {
        _error = '该时间段已有其他安排';
        notifyListeners();
        return false;
      }

      // 更新任务
      final updatedTask = task.copyWith(
        // 设置开始时间
        scheduledStartTime: startTime,
        // 更改任务状态
        status: TaskStatus.scheduled,
      );

      await updateTask(updatedTask);
      return true;
    } catch (e) {
      _error = '安排任务失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 获取任务的推荐时间段
  Future<List<TimeSlot>> getRecommendedSlots(
      Task task,
      DateTime date,
      ) async {
    try {
      // 调用智能调度服务获取推荐
      return await _scheduler.recommendTimeSlots(task, date);
    } catch (e) {
      _error = '获取推荐时间失败: $e';
      notifyListeners();
      return [];
    }
  }

  // 获取时间碎片化分析
  Future<Map<String, dynamic>> getTimeAnalysis(DateTime date) async {
    try {
      return await _scheduler.analyzeTimeFragmentation(date);
    } catch (e) {
      _error = '分析失败: $e';
      notifyListeners();
      return {};
    }
  }

  // 工具方法：判断是否同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}