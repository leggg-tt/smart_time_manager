import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_time_manager/services/ai_service.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';

void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // 设置SharedPreferences的模拟初始值
    SharedPreferences.setMockInitialValues({});
  });

  // API密钥管理测试
  group('AITaskParser API Key 管理测试', () {
    // 初始状态测试
    test('初始状态下 API Key 应该为 null', () async {
      final parser = AITaskParser();
      final apiKey = await parser.getApiKey();

      // 验证新创建的解析器没有API密钥
      expect(apiKey, isNull);
    });

    // 保存和获取测试
    test('保存和获取 API Key 应该正常工作', () async {
      final parser = AITaskParser();
      const testApiKey = 'test-api-key-123';

      // 保存 API Key
      await parser.saveApiKey(testApiKey);

      // 获取 API Key
      final retrievedKey = await parser.getApiKey();
      // 测试API密钥的持久化存储功能
      expect(retrievedKey, equals(testApiKey));
    });

    // 内存缓存测试
    test('API Key 应该被缓存在内存中', () async {
      final parser = AITaskParser();
      const testApiKey = 'cached-api-key-456';

      // 保存 API Key
      await parser.saveApiKey(testApiKey);

      // 第一次获取（从SharedPreferences）
      final firstCall = await parser.getApiKey();
      expect(firstCall, equals(testApiKey));

      // 清除SharedPreferences来测试缓存
      SharedPreferences.setMockInitialValues({});

      // 第二次获取应该仍然返回缓存的值
      final secondCall = await parser.getApiKey();
      // 验证API密钥在内存中缓存,减少对存储的访问
      expect(secondCall, equals(testApiKey));
    });

    // 实例间共享测试
    test('多个 AITaskParser 实例应该共享存储的 API Key', () async {
      const sharedApiKey = 'shared-api-key-789';

      // 第一个实例保存API Key
      final parser1 = AITaskParser();
      await parser1.saveApiKey(sharedApiKey);

      // 第二个实例应该能获取到相同的API Key
      final parser2 = AITaskParser();
      final retrievedKey = await parser2.getApiKey();

      // 确保API密钥在整个应用中共享
      expect(retrievedKey, equals(sharedApiKey));
    });
  });

  // ParsedTaskData数据解析测试
  group('ParsedTaskData 测试', () {
    // 测试完整JSON解析
    test('ParsedTaskData 应该正确解析完整的 JSON', () {
      final json = {
        'title': 'Test Task',
        'description': 'Test Description',
        'durationMinutes': 90,
        'priority': 'high',
        'energyRequired': 'high',
        'focusRequired': 'deep',
        'taskCategory': 'creative',
        'deadline': '2024-12-31',
        'suggestedDate': '2024-01-15',
        'suggestedTime': '14:30',
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 测试所有字段的解析
      expect(parsedData.title, equals('Test Task'));
      expect(parsedData.description, equals('Test Description'));
      expect(parsedData.durationMinutes, equals(90));
      expect(parsedData.priority, equals(Priority.high));
      expect(parsedData.energyRequired, equals(EnergyLevel.high));
      expect(parsedData.focusRequired, equals(FocusLevel.deep));
      expect(parsedData.taskCategory, equals(TaskCategory.creative));
      expect(parsedData.deadline, equals(DateTime(2024, 12, 31)));
      expect(parsedData.suggestedDate, equals(DateTime(2024, 1, 15)));
      expect(parsedData.suggestedTime, equals('14:30'));
    });

    // 测试可选字段处理
    test('ParsedTaskData 应该处理缺失的可选字段', () {
      final json = {
        'title': 'Minimal Task',
        'durationMinutes': 60,
        'priority': 'medium',
        'energyRequired': 'medium',
        'focusRequired': 'medium',
        'taskCategory': 'routine',
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 验证可选字段缺失时返回null
      expect(parsedData.title, equals('Minimal Task'));
      expect(parsedData.description, isNull);
      expect(parsedData.deadline, isNull);
      expect(parsedData.suggestedDate, isNull);
      expect(parsedData.suggestedTime, isNull);
    });

    // 默认值处理
    test('ParsedTaskData 应该使用默认值处理缺失的必需字段', () {
      final json = <String, dynamic>{};

      final parsedData = ParsedTaskData.fromJson(json);

      // 测试默认值
      expect(parsedData.title, equals('Untitled Task'));
      expect(parsedData.durationMinutes, equals(60));
      expect(parsedData.priority, equals(Priority.medium));
      expect(parsedData.energyRequired, equals(EnergyLevel.medium));
      expect(parsedData.focusRequired, equals(FocusLevel.medium));
      expect(parsedData.taskCategory, equals(TaskCategory.routine));
    });

    // 枚举解析测试
    test('枚举解析应该不区分大小写', () {
      final json = {
        'title': 'Case Test',
        'priority': 'HIGH',
        'energyRequired': 'Low',
        'focusRequired': 'DEEP',
        'taskCategory': 'Creative',
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 验证枚举解析支持各种大小写格式
      expect(parsedData.priority, equals(Priority.high));
      expect(parsedData.energyRequired, equals(EnergyLevel.low));
      expect(parsedData.focusRequired, equals(FocusLevel.deep));
      expect(parsedData.taskCategory, equals(TaskCategory.creative));
    });

    // 验证无效值处理
    test('无效的枚举值应该返回默认值', () {
      final json = {
        'title': 'Invalid Enum Test',
        'priority': 'invalid',
        'energyRequired': 'unknown',
        'focusRequired': 'wrong',
        'taskCategory': 'nonexistent',
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 验证无效的枚举值应是否返回默认的medium级别
      expect(parsedData.priority, equals(Priority.medium));
      expect(parsedData.energyRequired, equals(EnergyLevel.medium));
      expect(parsedData.focusRequired, equals(FocusLevel.medium));
      expect(parsedData.taskCategory, equals(TaskCategory.routine));
    });

    // 任务创建测试
    test('toTask 应该创建正确的 Task 对象', () {
      final parsedData = ParsedTaskData(
        title: 'Test Task',
        description: 'Test Description',
        durationMinutes: 120,
        priority: Priority.high,
        energyRequired: EnergyLevel.high,
        focusRequired: FocusLevel.deep,
        taskCategory: TaskCategory.analytical,
        deadline: DateTime(2024, 12, 31),
      );

      final task = parsedData.toTask();

      // 验证ParsedTaskData能正确转换为Task对象
      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Test Description'));
      expect(task.durationMinutes, equals(120));
      expect(task.priority, equals(Priority.high));
      expect(task.energyRequired, equals(EnergyLevel.high));
      expect(task.focusRequired, equals(FocusLevel.deep));
      expect(task.taskCategory, equals(TaskCategory.analytical));
      expect(task.deadline, equals(DateTime(2024, 12, 31)));
    });

    // 日期时间组合测试
    test('getSuggestedDateTime 应该正确组合日期和时间', () {
      final parsedData = ParsedTaskData(
        title: 'Test',
        durationMinutes: 60,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.routine,
        suggestedDate: DateTime(2024, 1, 15),
        suggestedTime: '14:30',
      );

      final suggestedDateTime = parsedData.getSuggestedDateTime();

      // 测试日期和时间字符串的组合
      expect(suggestedDateTime, isNotNull);
      expect(suggestedDateTime!.year, equals(2024));
      expect(suggestedDateTime.month, equals(1));
      expect(suggestedDateTime.day, equals(15));
      expect(suggestedDateTime.hour, equals(14));
      expect(suggestedDateTime.minute, equals(30));
    });

    // 部分信息处理
    test('getSuggestedDateTime 应该处理只有日期没有时间的情况', () {
      final parsedData = ParsedTaskData(
        title: 'Test',
        durationMinutes: 60,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.routine,
        suggestedDate: DateTime(2024, 1, 15),
        suggestedTime: null,
      );

      final suggestedDateTime = parsedData.getSuggestedDateTime();

      // 只有日期时返回日期的零点时间
      expect(suggestedDateTime, equals(DateTime(2024, 1, 15)));
    });

    test('getSuggestedDateTime 应该返回 null 如果没有建议日期', () {
      final parsedData = ParsedTaskData(
        title: 'Test',
        durationMinutes: 60,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.routine,
        suggestedDate: null,
        suggestedTime: '14:30',
      );

      final suggestedDateTime = parsedData.getSuggestedDateTime();

      // 验证没有日期时返回null
      expect(suggestedDateTime, isNull);
    });
  });

  // 边界情况测试
  group('ParsedTaskData 边界情况测试', () {
    // 测试无效日期格式
    test('应该处理无效的日期格式', () {
      final json = {
        'title': 'Invalid Date Test',
        'deadline': 'invalid-date',
        'suggestedDate': 'not-a-date',
      };

      expect(
            () => ParsedTaskData.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    // 时间格式边界测试
    test('应该处理无效的时间格式', () {
      final parsedData = ParsedTaskData(
        title: 'Test',
        durationMinutes: 60,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.routine,
        suggestedDate: DateTime(2024, 1, 15),
        suggestedTime: 'invalid:time:format',
      );

      expect(
            () => parsedData.getSuggestedDateTime(),
        throwsA(isA<FormatException>()),
      );
    });

    test('应该处理边界时间格式', () {
      // 测试各种时间格式
      final testCases = [
        {'time': '00:00', 'hour': 0, 'minute': 0},    // 午夜
        {'time': '23:59', 'hour': 23, 'minute': 59},  // 一天最后一分钟
        {'time': '12:00', 'hour': 12, 'minute': 0},   // 中午
        {'time': '09:05', 'hour': 9, 'minute': 5},    // 单位数分钟
      ];

      for (final testCase in testCases) {
        final parsedData = ParsedTaskData(
          title: 'Test',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
          suggestedDate: DateTime(2024, 1, 15),
          suggestedTime: testCase['time'] as String,
        );

        final dateTime = parsedData.getSuggestedDateTime();
        expect(dateTime!.hour, equals(testCase['hour']));
        expect(dateTime.minute, equals(testCase['minute']));
      }
    });

    // 空值和null值处理
    test('应该处理空字符串的枚举值', () {
      final json = {
        'title': 'Empty Enum Test',
        'priority': '',
        'energyRequired': '',
        'focusRequired': '',
        'taskCategory': '',
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 验证空字符串是否返回默认值
      expect(parsedData.priority, equals(Priority.medium));
      expect(parsedData.energyRequired, equals(EnergyLevel.medium));
      expect(parsedData.focusRequired, equals(FocusLevel.medium));
      expect(parsedData.taskCategory, equals(TaskCategory.routine));
    });

    // 验证null是否返回默认值
    test('应该处理 null 枚举值', () {
      final json = {
        'title': 'Null Enum Test',
        'priority': null,
        'energyRequired': null,
        'focusRequired': null,
        'taskCategory': null,
      };

      final parsedData = ParsedTaskData.fromJson(json);

      // 测试null值是否返回默认值
      expect(parsedData.priority, equals(Priority.medium));
      expect(parsedData.energyRequired, equals(EnergyLevel.medium));
      expect(parsedData.focusRequired, equals(FocusLevel.medium));
      expect(parsedData.taskCategory, equals(TaskCategory.routine));
    });
  });
}