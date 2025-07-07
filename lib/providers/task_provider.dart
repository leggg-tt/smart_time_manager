import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/scheduler_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final SchedulerService _scheduler = SchedulerService();

  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取未安排的任务
  List<Task> get pendingTasks => _tasks
      .where((task) => task.status == TaskStatus.pending)
      .toList();

  // 获取已完成的任务
  List<Task> get completedTasks => _tasks
      .where((task) => task.status == TaskStatus.completed)
      .toList();

  // 找到这个已存在的方法
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _db.getAllTasks();

      // 在这里添加打印语句
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
      _tasks.insert(0, task);

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
      await _db.updateTask(task);

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

  // 删除任务
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

  // 标记任务完成
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
      // 检查是否可以安排
      final canSchedule = await _scheduler.canScheduleTask(task, startTime);
      if (!canSchedule) {
        _error = '该时间段已有其他安排';
        notifyListeners();
        return false;
      }

      // 更新任务
      final updatedTask = task.copyWith(
        scheduledStartTime: startTime,
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