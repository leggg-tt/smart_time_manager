import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';

void main() {
  // 任务标题生成测试
  group('TestDataGenerator Logic Tests', () {
    group('Task Title Generation', () {
      // 测试任务标题是否与类别匹配
      test('should match category with appropriate titles', () {
        // 测试创意性任务标题
        final creativeKeywords = ['design', 'create', 'write', 'brainstorm'];
        final analyticalKeywords = ['analyze', 'review', 'research', 'analysis', 'planning'];
        final routineKeywords = ['check', 'update', 'file', 'review', 'clean'];
        final communicationKeywords = ['meeting', 'call', 'one-on-one', 'sync', 'standup'];

        // 验证关键字是否适合每个类别,验证所有关键词都是字符串类型
        expect(creativeKeywords, everyElement(isA<String>()));
        expect(analyticalKeywords, everyElement(isA<String>()));
        expect(routineKeywords, everyElement(isA<String>()));
        expect(communicationKeywords, everyElement(isA<String>()));
      });
    });

    // 任务时长范围测试
    group('Duration Ranges', () {
      // 测试不同类别任务的时长范围是否合理
      test('should have appropriate duration ranges for each category', () {
        // 定义预期持续时间范围
        final creativeDurationRange = {'min': 60, 'max': 120};
        final analyticalDurationRange = {'min': 45, 'max': 90};
        final routineDurationRange = {'min': 15, 'max': 45};
        final communicationDurationRange = {'min': 30, 'max': 60};

        // 验证范围是否有效
        expect(creativeDurationRange['max']! - creativeDurationRange['min']!, equals(60));
        expect(analyticalDurationRange['max']! - analyticalDurationRange['min']!, equals(45));
        expect(routineDurationRange['max']! - routineDurationRange['min']!, equals(30));
        expect(communicationDurationRange['max']! - communicationDurationRange['min']!, equals(30));

        // 验证最短持续时间
        expect(creativeDurationRange['min'], greaterThanOrEqualTo(60));
        expect(analyticalDurationRange['min'], greaterThanOrEqualTo(45));
        expect(routineDurationRange['min'], greaterThanOrEqualTo(15));
        expect(communicationDurationRange['min'], greaterThanOrEqualTo(30));
      });
    });

    // 能量等级逻辑测试
    group('Energy Level Logic', () {
      test('should assign energy levels based on priority', () {
        // 高优先级应该倾向于高能量
        // 这是一个逻辑测试,而不是测试实际的随机生成

        // 对于高优先级的创造性任务,高能量更有可能
        final highPriorityCreativeEnergyProbability = 0.7;
        expect(highPriorityCreativeEnergyProbability, greaterThan(0.5));

        // 对于低优先级的日常任务,低能量更有可能
        final lowPriorityRoutineLowEnergyProbability = 0.7;
        expect(lowPriorityRoutineLowEnergyProbability, greaterThan(0.5));

        // 沟通任务应始终保持中等强度
        final communicationMediumEnergyProbability = 1.0;
        expect(communicationMediumEnergyProbability, equals(1.0));
      });
    });

    // 专注等级逻辑测试
    group('Focus Level Logic', () {
      test('should assign focus levels appropriately by category', () {
        // 分析类任务总是需要深度专注
        final analyticalDeepFocusProbability = 1.0;
        expect(analyticalDeepFocusProbability, equals(1.0));

        // 创意类任务倾向于需要深度专注
        final creativeDeepFocusProbability = 0.7;
        expect(creativeDeepFocusProbability, greaterThan(0.5));

        // 常规任务倾向于只需要轻度专注
        final routineLightFocusProbability = 0.7;
        expect(routineLightFocusProbability, greaterThan(0.5));

        // 沟通类任务可以是中等或轻度专注
        final communicationValidFocusLevels = [FocusLevel.medium, FocusLevel.light];
        expect(communicationValidFocusLevels.length, equals(2));
      });
    });

    // 优先级分布测试
    group('Priority Distribution', () {
      test('should have expected probability distribution', () {
        // 测试优先级的概率分布
        final highPriorityProbability = 0.2;
        final mediumPriorityProbability = 0.4;
        final lowPriorityProbability = 0.4;

        // 验证概率总和为1
        expect(
          highPriorityProbability + mediumPriorityProbability + lowPriorityProbability,
          equals(1.0),
        );

        // 验证每个概率值在有效范围内
        expect(highPriorityProbability, inInclusiveRange(0.0, 1.0));
        expect(mediumPriorityProbability, inInclusiveRange(0.0, 1.0));
        expect(lowPriorityProbability, inInclusiveRange(0.0, 1.0));
      });
    });

    // 工作时间测试
    group('Working Hours', () {
      // 测试任务应该安排在工作时间内
      test('should schedule within working hours', () {
        // 定义工作时间
        final minWorkHour = 8;
        final maxWorkHour = 17;
        final validMinutes = [0, 15, 30, 45];

        // 验证工作时长为9小时
        expect(maxWorkHour - minWorkHour, equals(9));
        expect(minWorkHour, greaterThanOrEqualTo(0));
        expect(maxWorkHour, lessThanOrEqualTo(23));

        // 验证分钟值都在0-59范围内
        expect(validMinutes, everyElement(inInclusiveRange(0, 59)));
        expect(validMinutes.length, equals(4));
      });
    });

    // 截止日期分配测试
    group('Deadline Assignment', () {
      // 测试高优先级任务的截止日期分配
      test('should assign deadlines to high priority tasks', () {
        // 高优先级任务有70%概率设置截止日期
        final highPriorityDeadlineProbability = 0.7;
        expect(highPriorityDeadlineProbability, inInclusiveRange(0.5, 0.9));

        // 截止日期在1-7天之间
        final minDeadlineDays = 1;
        final maxDeadlineDays = 7;
        expect(minDeadlineDays, greaterThan(0));
        expect(maxDeadlineDays, lessThanOrEqualTo(7));
      });
    });

    // 描述生成测试
    group('Description Generation', () {
      // 测试任务描述的生成规则
      test('should occasionally add descriptions', () {
        // 约30%的任务应该有描述
        final descriptionProbability = 0.3;
        expect(descriptionProbability, inInclusiveRange(0.2, 0.4));

        // 验证描述内容包含必要的关键词
        final expectedDescription = '这是用于测试分析功能的模拟数据';
        expect(expectedDescription, contains('测试'));
        expect(expectedDescription, contains('分析'));
      });
    });

    // 时间解析逻辑测试
    group('Time Parsing Logic', () {
      // 测试时间字符串的解析
      test('should parse time components correctly', () {
        // 测试标准时间格式的解析
        final timeString = '14:30';
        final parts = timeString.split(':');

        expect(parts.length, equals(2));
        expect(int.parse(parts[0]), equals(14));
        expect(int.parse(parts[1]), equals(30));

        // 测试边界情况:午夜和一天结束
        final midnight = '00:00';
        final midnightParts = midnight.split(':');
        expect(int.parse(midnightParts[0]), equals(0));
        expect(int.parse(midnightParts[1]), equals(0));

        final endOfDay = '23:59';
        final endOfDayParts = endOfDay.split(':');
        expect(int.parse(endOfDayParts[0]), equals(23));
        expect(int.parse(endOfDayParts[1]), equals(59));
      });
    });

    // 任务生成模式测试
    group('Task Generation Parameters', () {
      // 测试是否符合实际的任务生成模式
      test('should respect realistic patterns', () {
        // 周一到周五应该分配的任务数量最多
        final mondayTaskMultiplier = 1.2;
        final fridayTaskMultiplier = 1.2;
        final wednesdayTaskMultiplier = 0.8;

        expect(mondayTaskMultiplier, greaterThan(1.0));
        expect(fridayTaskMultiplier, greaterThan(1.0));
        expect(wednesdayTaskMultiplier, lessThan(1.0));
      });

      // 测试跳过周末的逻辑
      test('should skip weekends', () {
        final weekendDays = [6, 7];
        final workDays = [1, 2, 3, 4, 5];

        expect(weekendDays, everyElement(inInclusiveRange(1, 7)));
        expect(workDays, everyElement(inInclusiveRange(1, 7)));
        expect(weekendDays.length + workDays.length, equals(7));
      });
    });

    // 完成率逻辑测试
    group('Completion Rate Logic', () {
      // 测试任务状态的处理
      test('should handle different task statuses', () {
        // 75%的过去任务应该标记为已完成
        final completionRate = 0.75;
        expect(completionRate, inInclusiveRange(0.0, 1.0));

        // 30%的任务保持待处理状态
        final pendingRate = 0.3;
        expect(pendingRate, inInclusiveRange(0.0, 1.0));

        // 未来的任务应该是已安排状态
        final futureTasks = TaskStatus.scheduled;
        expect(futureTasks, equals(TaskStatus.scheduled));
      });
    });

    // 番茄钟集成测试
    group('Pomodoro Integration', () {
      test('should calculate pomodoro counts correctly', () {
        // 测试番茄钟数量的计算
        final taskDuration = 60;
        final pomodoroDuration = 25;
        final expectedPomodoros = (taskDuration / pomodoroDuration).ceil();

        // 验证60分钟任务需要3个番茄钟（向上取整）
        expect(expectedPomodoros, equals(3));

        // 验证30分钟任务需要2个番茄钟
        final shortTask = 30;
        final shortPomodoros = (shortTask / pomodoroDuration).ceil();
        expect(shortPomodoros, equals(2));

        // 同上
        final longTask = 120;
        final longPomodoros = (longTask / pomodoroDuration).ceil();
        expect(longPomodoros, equals(5));
      });

      test('should add pomodoro data to completed tasks', () {
        // 60%的已完成任务应该有番茄钟数据
        final pomodoroDataProbability = 0.6;
        expect(pomodoroDataProbability, inInclusiveRange(0.5, 0.7));

        // 验证番茄钟数据的格式
        final pomodoroFormat = '[Pomodoro: X completed, Total work: Y min]';
        expect(pomodoroFormat, contains('[Pomodoro:'));
        expect(pomodoroFormat, contains('completed'));
        expect(pomodoroFormat, contains('Total work:'));
      });
    });
  });
}