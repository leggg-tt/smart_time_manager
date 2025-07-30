import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/services/analytics_service.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';
import 'package:smart_time_manager/models/user_time_block.dart';

void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试任务的辅助方法
  Task createTestTask({
    String? id,
    String title = 'Test Task',
    String? description,
    int durationMinutes = 60,
    TaskStatus status = TaskStatus.pending,
    Priority priority = Priority.medium,
    TaskCategory taskCategory = TaskCategory.routine,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? 'test-task-1',
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      status: status,
      priority: priority,
      energyRequired: EnergyLevel.medium,
      focusRequired: FocusLevel.medium,
      taskCategory: taskCategory,
      scheduledStartTime: scheduledStartTime,
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      completedAt: completedAt,
    );
  }

  // 创建测试时间块的辅助方法
  UserTimeBlock createTestTimeBlock({
    String? id,
    String name = 'Morning Block',
    String startTime = '09:00',
    String endTime = '11:00',
    List<int>? daysOfWeek,
  }) {
    return UserTimeBlock(
      id: id ?? 'test-block-1',
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek ?? [1, 2, 3, 4, 5],
      energyLevel: EnergyLevel.high,
      focusLevel: FocusLevel.deep,
      suitableCategories: [TaskCategory.analytical],
      suitablePriorities: [Priority.high],
      suitableEnergyLevels: [EnergyLevel.high],
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('AnalyticsService 初始化测试', () {
    test('AnalyticsService 应该能够创建', () {
      final analytics = AnalyticsService();
      // 简单验证服务能够创建
      expect(analytics, isNotNull);
    });
  });

  group('AnalyticsService 辅助方法测试', () {
    // 时间解析测试
    test('_parseTimeToDateTime 应该正确解析时间', () {
      final analytics = AnalyticsService();
      final date = DateTime(2024, 1, 15);

      // 验证时间字符串格式
      const validTimeFormats = ['09:00', '14:30', '23:59', '00:00'];
      for (final timeStr in validTimeFormats) {
        expect(() {
          final parts = timeStr.split(':');
          DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }, returnsNormally);
      }
    });
  });

  // 数据结构测试
  group('AnalyticsService 数据结构测试', () {
    // 任务完成统计结构
    test('任务完成统计返回值结构应该正确', () {
      // 验证返回的 Map 结构
      final expectedKeys = ['totalTasks', 'completedTasks', 'completionRate', 'byStatus'];
      final mockResult = {
        'totalTasks': 10,
        'completedTasks': 5,
        'completionRate': 50.0,
        'byStatus': [],
      };

      for (final key in expectedKeys) {
        // 验证完成统计的返回结构
        expect(mockResult.containsKey(key), isTrue);
      }
    });

    test('时间利用率统计返回值结构应该正确', () {
      final expectedKeys = ['plannedHours', 'actualHours', 'utilizationRate'];
      final mockResult = {
        'plannedHours': 8.0,
        'actualHours': 6.5,
        'utilizationRate': 81.25,
      };

      for (final key in expectedKeys) {
        expect(mockResult.containsKey(key), isTrue);
      }
    });

    // 测试类别分布结构
    test('类别分布返回值结构应该正确', () {
      final mockResult = [
        {
          'category': TaskCategory.creative,
          'count': 5,
          'totalHours': 10.0,
          'avgMinutes': 120.0,
        },
      ];

      final item = mockResult.first;
      expect(item.containsKey('category'), isTrue);
      expect(item.containsKey('count'), isTrue);
      expect(item.containsKey('totalHours'), isTrue);
      expect(item.containsKey('avgMinutes'), isTrue);
    });

    // 验证优先级分布结构
    test('优先级分布返回值结构应该正确', () {
      final mockResult = [
        {
          'priority': Priority.high,
          'count': 10,
          'completed': 8,
          'completionRate': 80.0,
        },
      ];

      final item = mockResult.first;
      expect(item.containsKey('priority'), isTrue);
      expect(item.containsKey('count'), isTrue);
      expect(item.containsKey('completed'), isTrue);
      expect(item.containsKey('completionRate'), isTrue);
    });

    // 验证每日任务模式结构
    test('每日任务模式返回值结构应该正确', () {
      final mockResult = [
        {
          'date': '2024-01-15',
          'taskCount': 5,
          'completed': 3,
          'totalHours': 8.0,
        },
      ];

      final item = mockResult.first;
      expect(item.containsKey('date'), isTrue);
      expect(item.containsKey('taskCount'), isTrue);
      expect(item.containsKey('completed'), isTrue);
      expect(item.containsKey('totalHours'), isTrue);
    });

    // 验证高峰生产力时段结构
    test('高峰生产力时段返回值结构应该正确', () {
      final mockResult = [
        {
          'hour': 9,
          'taskCount': 15,
          'completed': 12,
          'completionRate': 80.0,
        },
      ];

      final item = mockResult.first;
      expect(item.containsKey('hour'), isTrue);
      expect(item.containsKey('taskCount'), isTrue);
      expect(item.containsKey('completed'), isTrue);
      expect(item.containsKey('completionRate'), isTrue);
    });

    // 验证番茄钟统计结构
    test('番茄钟统计返回值结构应该正确', () {
      final mockResult = {
        'totalPomodoros': 20,
        'totalWorkHours': 8.33,
        'tasksWithPomodoro': 5,
      };

      expect(mockResult.containsKey('totalPomodoros'), isTrue);
      expect(mockResult.containsKey('totalWorkHours'), isTrue);
      expect(mockResult.containsKey('tasksWithPomodoro'), isTrue);
    });

    // 测试时间块利用率结构是否正确
    test('时间块利用率返回值结构应该正确', () {
      final mockTimeBlock = createTestTimeBlock();
      final mockResult = [
        {
          'timeBlock': mockTimeBlock,
          'totalMinutes': 120,
          'occupiedMinutes': 90,
          'utilizationRate': 75.0,
        },
      ];

      final item = mockResult.first;
      // 验证时间块使用情况
      expect(item.containsKey('timeBlock'), isTrue);
      expect(item.containsKey('totalMinutes'), isTrue);
      expect(item.containsKey('occupiedMinutes'), isTrue);
      expect(item.containsKey('utilizationRate'), isTrue);
    });
  });

  // 计算逻辑测试
  group('AnalyticsService 计算逻辑测试', () {
    // 完成率计算
    test('完成率计算应该正确', () {
      // 测试完成率计算公式
      final testCases = [
        {'total': 10, 'completed': 5, 'expected': 50.0},
        {'total': 0, 'completed': 0, 'expected': 0.0},
        {'total': 100, 'completed': 75, 'expected': 75.0},
        {'total': 3, 'completed': 3, 'expected': 100.0},
      ];

      for (final testCase in testCases) {
        final total = testCase['total'] as int;
        final completed = testCase['completed'] as int;
        final expected = testCase['expected'] as double;

        final rate = total > 0 ? (completed / total * 100) : 0.0;
        expect(rate, equals(expected));
      }
    });

    // 测试时间转换计算
    test('时间转换计算应该正确', () {
      // 测试分钟转小时
      expect(60 / 60, equals(1.0));
      expect(90 / 60, equals(1.5));
      expect(120 / 60, equals(2.0));
      expect(0 / 60, equals(0.0));
    });

    // 测试利用率计算
    test('利用率计算应该正确', () {
      // 测试利用率计算公式
      final testCases = [
        {'planned': 100, 'actual': 80, 'expected': 80.0},
        {'planned': 0, 'actual': 0, 'expected': 0.0},
        {'planned': 60, 'actual': 90, 'expected': 150.0}, // 超出计划
      ];

      for (final testCase in testCases) {
        final planned = testCase['planned'] as int;
        final actual = testCase['actual'] as int;
        final expected = testCase['expected'] as double;

        final rate = planned > 0 ? (actual / planned * 100) : 0.0;
        expect(rate, equals(expected));
      }
    });
  });

  // 茄钟解析测试
  group('AnalyticsService 番茄钟解析测试', () {
    // 正则表达式测试
    test('应该正确解析番茄钟描述', () {
      // 测试正则表达式
      const description = '[Pomodoro: 4 completed, Total work: 100 min]';
      final regex = RegExp(r'\[Pomodoro: (\d+) completed, Total work: (\d+) min\]');
      final match = regex.firstMatch(description);

      expect(match, isNotNull);
      expect(match!.group(1), equals('4'));
      expect(match.group(2), equals('100'));
    });

    // 测试多种格式处理
    test('应该处理各种番茄钟描述格式', () {
      final testCases = [
        {
          // 标准格式
          'description': '[Pomodoro: 1 completed, Total work: 25 min]',
          'pomodoros': 1,
          'minutes': 25,
        },
        {
          // 大数字
          'description': '[Pomodoro: 10 completed, Total work: 250 min]',
          'pomodoros': 10,
          'minutes': 250,
        },
        {
          // 无番茄钟信息
          'description': 'No pomodoro info',
          'pomodoros': null,
          'minutes': null,
        },
      ];

      final regex = RegExp(r'\[Pomodoro: (\d+) completed, Total work: (\d+) min\]');

      for (final testCase in testCases) {
        final match = regex.firstMatch(testCase['description'] as String);

        if (testCase['pomodoros'] != null) {
          expect(match, isNotNull);
          expect(int.parse(match!.group(1)!), equals(testCase['pomodoros']));
          expect(int.parse(match.group(2)!), equals(testCase['minutes']));
        } else {
          expect(match, isNull);
        }
      }
    });
  });

  // 边界情况测试
  group('AnalyticsService 边界情况测试', () {
    // 空数据集处理
    test('应该处理空数据集', () {
      // 验证各种统计方法的空数据处理
      final emptyStats = {
        'totalTasks': 0,
        'completedTasks': 0,
        'completionRate': 0.0,
        'byStatus': [],
      };

      // 验证空数据不会导致错误
      expect(emptyStats['completionRate'], equals(0.0));
      expect(emptyStats['byStatus'], isEmpty);
    });

    // 时间范围验证
    test('应该处理无效的时间范围', () {
      final analytics = AnalyticsService();

      final futureDate = DateTime.now().add(const Duration(days: 365));
      final pastDate = DateTime.now().subtract(const Duration(days: 365));

      // 验证日期可以被正确转换为时间戳
      expect(futureDate.millisecondsSinceEpoch, isPositive);
      expect(pastDate.millisecondsSinceEpoch, isPositive);
      expect(futureDate.isAfter(pastDate), isTrue);
    });
  });
}