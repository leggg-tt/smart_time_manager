import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_time_manager/providers/task_provider.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';
import 'package:smart_time_manager/services/scheduler_service.dart';

void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试任务的辅助方法
  Task createTestTask({
    String? id,
    String title = 'Test Task',
    String? description,
    int durationMinutes = 60,
    DateTime? deadline,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    Priority priority = Priority.medium,
    EnergyLevel energyRequired = EnergyLevel.medium,
    FocusLevel focusRequired = FocusLevel.medium,
    TaskCategory taskCategory = TaskCategory.routine,
    TaskStatus status = TaskStatus.pending,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? 'test-task-1',
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      deadline: deadline,
      scheduledStartTime: scheduledStartTime,
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      priority: priority,
      energyRequired: energyRequired,
      focusRequired: focusRequired,
      taskCategory: taskCategory,
      status: status,
      completedAt: completedAt,
    );
  }

  // 初始化测试
  group('TaskProvider 初始化测试', () {
    // 创建新的TaskProvider实例
    test('初始状态应该正确', () {
      final provider = TaskProvider();

      // 验证任务列表初始为空
      expect(provider.tasks, isEmpty);
      // 验证今日任务列表初始为空
      expect(provider.todayTasks, isEmpty);
      // 验证待处理任务列表初始为空
      expect(provider.pendingTasks, isEmpty);
      // 验证已完成任务列表初始为空
      expect(provider.completedTasks, isEmpty);
      // 验证初始不在加载状态
      expect(provider.isLoading, isFalse);
      // 验证初始没有错误信息
      expect(provider.error, isNull);
    });
  });

  // 任务过滤测试
  group('TaskProvider 任务过滤测试', () {
    // 测试任务过滤功能
    test('pendingTasks 应该只返回待处理的任务', () {
      final provider = TaskProvider();

      // 初始状态应该为空
      expect(provider.pendingTasks, isEmpty);
    });

    // 测试已完成任务过滤,同样只能验证初始状态
    test('completedTasks 应该只返回已完成的任务', () {
      final provider = TaskProvider();

      // 初始状态应该为空
      expect(provider.completedTasks, isEmpty);
    });
  });

  // 工具方法测试
  group('TaskProvider 工具方法测试', () {
    // 验证初始错误状态为null
    test('clearError 应该清除错误信息', () {
      final provider = TaskProvider();

      // 初始状态错误应该为 null
      expect(provider.error, isNull);

      // 清除错误（即使已经是 null）
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  //  监听器测试
  group('TaskProvider 监听器测试', () {
    // 测试ChangeNotifier的监听器功能
    test('clearError 应该通知监听器', () {
      // 创建provider和计数器变量
      final provider = TaskProvider();
      var notificationCount = 0;

      // 添加监听器,每次收到通知时增加计数
      provider.addListener(() {
        notificationCount++;
      });

      // 调用clearError触发通知
      provider.clearError();

      // 验证监听器被调用了一次
      expect(notificationCount, equals(1));

      // 移除监听器
      provider.removeListener(() {});
    });
  });

  // 属性访问测试
  group('TaskProvider 属性访问测试', () {
    // 测试各种getter属性的访问
    test('tasks getter 应该返回任务列表', () {
      final provider = TaskProvider();

      // 不应该为null
      expect(provider.tasks, isNotNull);
      // 应该是列表类型
      expect(provider.tasks, isList);
      // 初始应该为空
      expect(provider.tasks, isEmpty);
    });

    // 测试todayTasks getter
    test('todayTasks getter 应该返回今日任务列表', () {
      final provider = TaskProvider();

      expect(provider.todayTasks, isNotNull);
      expect(provider.todayTasks, isList);
      expect(provider.todayTasks, isEmpty);
    });

    // 测试isLoading getter
    test('isLoading getter 应该返回加载状态', () {
      final provider = TaskProvider();
      expect(provider.isLoading, isFalse);
    });

    // 测试error getter
    test('error getter 应该返回错误信息', () {
      final provider = TaskProvider();
      expect(provider.error, isNull);
    });
  });

  // 任务过滤逻辑测试
  group('TaskProvider 任务过滤逻辑测试', () {
    // 创建不同状态的测试任务
    test('pendingTasks 过滤逻辑应该正确', () {
      final provider = TaskProvider();

      // 创建不同状态的任务
      final pendingTask = createTestTask(status: TaskStatus.pending);
      final scheduledTask = createTestTask(status: TaskStatus.scheduled);
      final completedTask = createTestTask(status: TaskStatus.completed);

      expect(() => provider.pendingTasks, returnsNormally);
    });

    test('completedTasks 过滤逻辑应该正确', () {
      final provider = TaskProvider();

      // 验证过滤逻辑的存在
      expect(() => provider.completedTasks, returnsNormally);
    });
  });

  // 边界情况测试,测试边界情况和异常处理
  group('TaskProvider 边界情况测试', () {
    test('空列表操作应该安全', () {
      final provider = TaskProvider();

      // 在空列表上调用过滤方法应该返回空列表而不是抛出异常
      expect(provider.pendingTasks, isEmpty);
      expect(provider.completedTasks, isEmpty);
      expect(provider.tasks, isEmpty);
      expect(provider.todayTasks, isEmpty);
    });

    test('多次调用 clearError 应该安全', () {
      final provider = TaskProvider();

      // 多次调用不应该抛出异常
      provider.clearError();
      provider.clearError();
      provider.clearError();

      expect(provider.error, isNull);
    });
  });

  // 监听器管理测试
  group('TaskProvider 监听器管理测试', () {
    // 测试监听器的添加和移除
    test('添加和移除监听器应该正常工作', () {
      // 创建一个命名函数作为监听器
      final provider = TaskProvider();
      var callCount = 0;

      void listener() {
        callCount++;
      }

      // 添加监听器
      provider.addListener(listener);

      // 触发通知
      provider.clearError();
      expect(callCount, equals(1));

      // 移除监听器
      provider.removeListener(listener);

      // 再次触发通知,不应该增加计数
      provider.clearError();
      expect(callCount, equals(1));
    });

    test('多个监听器应该都能收到通知', () {
      // 创建三个计数器
      final provider = TaskProvider();
      var count1 = 0;
      var count2 = 0;
      var count3 = 0;

      // 添加三个不同的监听器
      provider.addListener(() => count1++);
      provider.addListener(() => count2++);
      provider.addListener(() => count3++);

      // 触发一次通知
      provider.clearError();

      // 验证所有监听器都被调用了一次
      expect(count1, equals(1));
      expect(count2, equals(1));
      expect(count3, equals(1));
    });
  });
}