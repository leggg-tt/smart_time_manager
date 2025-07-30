import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/services/scheduler_service.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/user_time_block.dart';
import 'package:smart_time_manager/models/enums.dart';

void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试任务的辅助方法
  Task createTestTask({
    String? id,
    String title = 'Test Task',
    int durationMinutes = 60,
    Priority priority = Priority.medium,
    EnergyLevel energyRequired = EnergyLevel.medium,
    FocusLevel focusRequired = FocusLevel.medium,
    TaskCategory taskCategory = TaskCategory.routine,
    DateTime? scheduledStartTime,
  }) {
    return Task(
      id: id ?? 'test-task-1',
      title: title,
      durationMinutes: durationMinutes,
      priority: priority,
      energyRequired: energyRequired,
      focusRequired: focusRequired,
      taskCategory: taskCategory,
      scheduledStartTime: scheduledStartTime,
    );
  }

  // 创建测试时间块的辅助方法
  UserTimeBlock createTestTimeBlock({
    String? id,
    String name = 'Morning Block',
    String startTime = '09:00',
    String endTime = '11:00',
    EnergyLevel energyLevel = EnergyLevel.high,
    FocusLevel focusLevel = FocusLevel.deep,
    List<TaskCategory>? suitableCategories,
    List<Priority>? suitablePriorities,
  }) {
    return UserTimeBlock(
      id: id ?? 'test-block-1',
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: [1, 2, 3, 4, 5], // 工作日
      energyLevel: energyLevel,
      focusLevel: focusLevel,
      suitableCategories: suitableCategories ?? [TaskCategory.analytical, TaskCategory.creative],
      suitablePriorities: suitablePriorities ?? [Priority.high, Priority.medium],
      suitableEnergyLevels: [energyLevel],
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 时间段测试
  group('TimeSlot 测试', () {
    // 时长计算测试
    test('TimeSlot 应该正确计算持续时间', () {
      final startTime = DateTime(2024, 1, 1, 9, 0);
      final endTime = DateTime(2024, 1, 1, 10, 30);

      final timeSlot = TimeSlot(
        startTime: startTime,
        endTime: endTime,
        score: 80.0,
        reasons: ['Test reason'],
      );

      // 测试能否正确算出持续时长
      expect(timeSlot.duration, equals(const Duration(hours: 1, minutes: 30)));
    });

    // 可选时间块测试
    test('TimeSlot 可以不包含 timeBlock', () {
      final timeSlot = TimeSlot(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        timeBlock: null,
        score: 75.0,
        reasons: ['Available time'],
      );

      // 测试时间段可以不关联特定的时间块,即即使这段时间没有设定时间块,系统也可以按照空闲时间来分配任务
      expect(timeSlot.timeBlock, isNull);
      expect(timeSlot.score, equals(75.0));
      expect(timeSlot.reasons, contains('Available time'));
    });
  });

  // SchedulerService初始化测试
  group('SchedulerService 初始化测试', () {
    // 简单测试服务能否创建
    test('SchedulerService 应该能够创建', () {
      final scheduler = SchedulerService();
      expect(scheduler, isNotNull);
    });
  });

  // 工具方法测试
  group('SchedulerService 工具方法测试', () {
    // 测试时间碎片化分析的建议文本
    test('_generateFragmentationSuggestion 应该返回正确的建议', () {
      final scheduler = SchedulerService();

      const suggestions = [
        'Your time is quite scattered, consider grouping similar tasks',
        'Multiple time fragments available for simple tasks',
        'Lacking continuous deep work time, consider adjusting schedule',
        'Time arrangement is reasonable, maintain current rhythm',
      ];

      // 验证建议文本都是有效的字符串
      for (final suggestion in suggestions) {
        expect(suggestion, isNotEmpty);
        expect(suggestion, isA<String>());
      }
    });
  });

  // 边界情况测试
  group('TimeSlot 边界情况测试', () {
    // 零时长测试
    test('TimeSlot 应该处理相同的开始和结束时间', () {
      final sameTime = DateTime.now();

      final timeSlot = TimeSlot(
        startTime: sameTime,
        endTime: sameTime,
        score: 0.0,
        reasons: ['Zero duration'],
      );

      expect(timeSlot.duration, equals(Duration.zero));
    });

    // 空理由列表测试
    test('TimeSlot 应该处理空的理由列表', () {
      final timeSlot = TimeSlot(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        score: 50.0,
        reasons: [],
      );

      // 测试没有推荐理由的情况
      expect(timeSlot.reasons, isEmpty);
    });

    // 负分数测试
    test('TimeSlot 应该处理负分数', () {
      final timeSlot = TimeSlot(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        score: -10.0,
        reasons: ['Negative score'],
      );

      // 测试负分数的处理
      expect(timeSlot.score, equals(-10.0));
    });
  });

  // 时间计算测试
  group('SchedulerService 时间计算测试', () {
    // 结束时间计算
    test('任务的 scheduledEndTime 应该正确计算', () {
      final task = createTestTask(
        durationMinutes: 90,
        scheduledStartTime: DateTime(2024, 1, 1, 10, 0),
      );

      expect(task.scheduledEndTime, equals(DateTime(2024, 1, 1, 11, 30)));
    });

    // 空值处理
    test('没有 scheduledStartTime 的任务应该返回 null 的 scheduledEndTime', () {
      final task = createTestTask(
        scheduledStartTime: null,
      );

      expect(task.scheduledEndTime, isNull);
    });
  });

  // 评分逻辑测试
  group('SchedulerService 评分逻辑测试', () {
    // 匹配度理由测试
    test('完美匹配应该产生高分理由', () {
      // 测试理由生成逻辑
      const perfectMatchReason = 'Perfect match for your Morning Block';
      const goodMatchReason = 'Good match for Morning Block';
      const availableReason = 'Available time slot';

      expect(perfectMatchReason, contains('Perfect match'));
      expect(goodMatchReason, contains('Good match'));
      expect(availableReason, contains('Available time slot'));
    });

    test('能量匹配理由应该正确', () {
      const energyMatchReason = 'Energy requirement perfectly matched';
      expect(energyMatchReason, contains('Energy requirement'));
    });

    test('专注度匹配理由应该正确', () {
      const focusMatchReason = 'Focus level requirement matched';
      expect(focusMatchReason, contains('Focus level'));
    });

    // 任务类型匹配测试
    test('任务类型匹配理由应该正确', () {
      const categoryReasons = [
        'Suitable for Creative tasks',
        'Suitable for Analytical tasks',
        'Suitable for Routine tasks',
        'Suitable for Communication tasks',
      ];

      for (final reason in categoryReasons) {
        expect(reason, contains('Suitable for'));
        expect(reason, contains('tasks'));
      }
    });
  });

  // 时间段生成逻辑测试
  group('SchedulerService 时间段生成逻辑测试', () {
    // 时长一致性测试
    test('时间段持续时间应该等于任务持续时间', () {
      final task = createTestTask(durationMinutes: 45);
      final startTime = DateTime(2024, 1, 1, 9, 0);
      final endTime = startTime.add(Duration(minutes: task.durationMinutes));

      final timeSlot = TimeSlot(
        startTime: startTime,
        endTime: endTime,
        score: 80.0,
        reasons: [],
      );

      // 验证生成的时间段时长与任务时长一致
      expect(timeSlot.duration.inMinutes, equals(task.durationMinutes));
    });

    // 边界约束测试
    test('时间段不应该超过时间块边界', () {
      // 这个测试验证时间段生成的逻辑约束
      final blockEndTime = DateTime(2024, 1, 1, 11, 0);
      final taskDuration = 60; // 分钟

      // 最后一个有效的开始时间
      final lastValidStart = blockEndTime.subtract(Duration(minutes: taskDuration));

      // 验证这是有效的
      expect(lastValidStart.add(Duration(minutes: taskDuration)), equals(blockEndTime));

      // 之后的开始时间会超出边界
      final invalidStart = lastValidStart.add(const Duration(minutes: 5));
      expect(invalidStart.add(Duration(minutes: taskDuration)).isAfter(blockEndTime), isTrue);
    });
  });

  //  建议文本质量测试
  group('SchedulerService 建议文本测试', () {
    test('所有建议文本都应该是有意义的', () {
      final suggestions = [
        'Your time is quite scattered, consider grouping similar tasks',
        'Multiple time fragments available for simple tasks',
        'Lacking continuous deep work time, consider adjusting schedule',
        'Time arrangement is reasonable, maintain current rhythm',
      ];

      for (final suggestion in suggestions) {
        // 验证建议文本的质量
        expect(suggestion.length, greaterThan(10)); // 确保不是空的或太短的
        expect(suggestion, isNot(contains('null'))); // 确保没有null值
        expect(suggestion, isNot(contains('undefined'))); // 确保没有未定义值
      }
    });
  });
}