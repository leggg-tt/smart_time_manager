import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/ai_preferences.dart';

// 主函数
void main() {
  group('AIPreferences Tests', () {
    // 构造函数测试
    group('Constructor Tests', () {
      // 默认值测试
      test('should create preferences with default values', () {
        final prefs = AIPreferences();

        // 测试任务默认时长
        expect(prefs.meetingDefaultDuration, equals(60));
        expect(prefs.creativeDefaultDuration, equals(90));
        expect(prefs.routineDefaultDuration, equals(30));
        expect(prefs.analyticalDefaultDuration, equals(60));

        // 测试能量和专注度默认值
        expect(prefs.meetingDefaultEnergy, equals('medium'));
        expect(prefs.meetingDefaultFocus, equals('medium'));
        expect(prefs.creativeDefaultEnergy, equals('high'));
        expect(prefs.creativeDefaultFocus, equals('deep'));
        expect(prefs.routineDefaultEnergy, equals('low'));
        expect(prefs.routineDefaultFocus, equals('light'));
        expect(prefs.analyticalDefaultEnergy, equals('medium'));
        expect(prefs.analyticalDefaultFocus, equals('deep'));

        // 测试时间解析偏好
        expect(prefs.tomorrowDefaultTime, equals('09:00'));
        expect(prefs.nextWeekDefaultDay, equals('monday'));
        expect(prefs.workTimePreference, equals('balanced'));

        // 测试API统计
        expect(prefs.apiCallCount, equals(0));
        expect(prefs.lastApiCallTime, isNull);
      });

      // 自定义值测试
      test('should create preferences with custom values', () {
        final testTime = DateTime.now();
        final prefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 15,
          analyticalDefaultDuration: 90,
          meetingDefaultEnergy: 'high',
          meetingDefaultFocus: 'deep',
          creativeDefaultEnergy: 'medium',
          creativeDefaultFocus: 'medium',
          routineDefaultEnergy: 'medium',
          routineDefaultFocus: 'medium',
          analyticalDefaultEnergy: 'high',
          analyticalDefaultFocus: 'deep',
          tomorrowDefaultTime: '10:00',
          nextWeekDefaultDay: 'wednesday',
          workTimePreference: 'morning',
          apiCallCount: 5,
          lastApiCallTime: testTime,
        );

        // 测试构造函数是否正确接受和保存自定义参数
        expect(prefs.meetingDefaultDuration, equals(45));
        expect(prefs.creativeDefaultDuration, equals(120));
        expect(prefs.routineDefaultDuration, equals(15));
        expect(prefs.analyticalDefaultDuration, equals(90));
        expect(prefs.meetingDefaultEnergy, equals('high'));
        expect(prefs.meetingDefaultFocus, equals('deep'));
        expect(prefs.creativeDefaultEnergy, equals('medium'));
        expect(prefs.creativeDefaultFocus, equals('medium'));
        expect(prefs.routineDefaultEnergy, equals('medium'));
        expect(prefs.routineDefaultFocus, equals('medium'));
        expect(prefs.analyticalDefaultEnergy, equals('high'));
        expect(prefs.analyticalDefaultFocus, equals('deep'));
        expect(prefs.tomorrowDefaultTime, equals('10:00'));
        expect(prefs.nextWeekDefaultDay, equals('wednesday'));
        expect(prefs.workTimePreference, equals('morning'));
        expect(prefs.apiCallCount, equals(5));
        expect(prefs.lastApiCallTime, equals(testTime));
      });
    });

    // 默认偏好设置
    group('Default Preferences Tests', () {
      // 验证是否返回正确的默认偏好设置
      test('should return correct default preferences', () {
        final defaultPrefs = AIPreferences.defaultPreferences;

        expect(defaultPrefs.meetingDefaultDuration, equals(60));
        expect(defaultPrefs.creativeDefaultDuration, equals(90));
        expect(defaultPrefs.routineDefaultDuration, equals(30));
        expect(defaultPrefs.analyticalDefaultDuration, equals(60));
        expect(defaultPrefs.meetingDefaultEnergy, equals('medium'));
        expect(defaultPrefs.meetingDefaultFocus, equals('medium'));
        expect(defaultPrefs.creativeDefaultEnergy, equals('high'));
        expect(defaultPrefs.creativeDefaultFocus, equals('deep'));
        expect(defaultPrefs.routineDefaultEnergy, equals('low'));
        expect(defaultPrefs.routineDefaultFocus, equals('light'));
        expect(defaultPrefs.analyticalDefaultEnergy, equals('medium'));
        expect(defaultPrefs.analyticalDefaultFocus, equals('deep'));
        expect(defaultPrefs.tomorrowDefaultTime, equals('09:00'));
        expect(defaultPrefs.nextWeekDefaultDay, equals('monday'));
        expect(defaultPrefs.workTimePreference, equals('balanced'));
        expect(defaultPrefs.apiCallCount, equals(0));
        expect(defaultPrefs.lastApiCallTime, isNull);
      });
    });

    // JSON序列化测试
    group('JSON Serialization Tests', () {
      // 验证是否正确转换为JSON
      test('should convert to JSON correctly', () {
        // 创建一个测试用的时间
        final testTime = DateTime(2024, 1, 15, 10, 30);
        // 创建一个包含所有自定义值的AIPreferences对象
        final prefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 15,
          analyticalDefaultDuration: 90,
          meetingDefaultEnergy: 'high',
          meetingDefaultFocus: 'deep',
          creativeDefaultEnergy: 'medium',
          creativeDefaultFocus: 'medium',
          routineDefaultEnergy: 'medium',
          routineDefaultFocus: 'medium',
          analyticalDefaultEnergy: 'high',
          analyticalDefaultFocus: 'deep',
          tomorrowDefaultTime: '10:00',
          nextWeekDefaultDay: 'wednesday',
          workTimePreference: 'morning',
          apiCallCount: 5,
          lastApiCallTime: testTime,
        );

        // 转换为JSON
        final json = prefs.toJson();

        // 验证每个字段都正确转换到JSON
        expect(json['meetingDefaultDuration'], equals(45));
        expect(json['creativeDefaultDuration'], equals(120));
        expect(json['routineDefaultDuration'], equals(15));
        expect(json['analyticalDefaultDuration'], equals(90));
        expect(json['meetingDefaultEnergy'], equals('high'));
        expect(json['meetingDefaultFocus'], equals('deep'));
        expect(json['creativeDefaultEnergy'], equals('medium'));
        expect(json['creativeDefaultFocus'], equals('medium'));
        expect(json['routineDefaultEnergy'], equals('medium'));
        expect(json['routineDefaultFocus'], equals('medium'));
        expect(json['analyticalDefaultEnergy'], equals('high'));
        expect(json['analyticalDefaultFocus'], equals('deep'));
        expect(json['tomorrowDefaultTime'], equals('10:00'));
        expect(json['nextWeekDefaultDay'], equals('wednesday'));
        expect(json['workTimePreference'], equals('morning'));
        expect(json['apiCallCount'], equals(5));
        expect(json['lastApiCallTime'], equals(testTime.toIso8601String()));
      });

      // 测试空值处理
      test('should handle null lastApiCallTime in JSON', () {
        // 创建默认对象（lastApiCallTime为null）
        final prefs = AIPreferences();
        final json = prefs.toJson();

        // 验证null值在JSON中仍为null
        expect(json['lastApiCallTime'], isNull);
      });

      // 测试能否从JSON数据正确创建对象
      test('should create from JSON correctly', () {
        final testTime = DateTime(2024, 1, 15, 10, 30);
        final json = {
          'meetingDefaultDuration': 45,
          'creativeDefaultDuration': 120,
          'routineDefaultDuration': 15,
          'analyticalDefaultDuration': 90,
          'meetingDefaultEnergy': 'high',
          'meetingDefaultFocus': 'deep',
          'creativeDefaultEnergy': 'medium',
          'creativeDefaultFocus': 'medium',
          'routineDefaultEnergy': 'medium',
          'routineDefaultFocus': 'medium',
          'analyticalDefaultEnergy': 'high',
          'analyticalDefaultFocus': 'deep',
          'tomorrowDefaultTime': '10:00',
          'nextWeekDefaultDay': 'wednesday',
          'workTimePreference': 'morning',
          'apiCallCount': 5,
          'lastApiCallTime': testTime.toIso8601String(),
        };

        // 使用fromJson工厂方法创建对象
        final prefs = AIPreferences.fromJson(json);

        // 验证所有字段都正确解析
        expect(prefs.meetingDefaultDuration, equals(45));
        expect(prefs.creativeDefaultDuration, equals(120));
        expect(prefs.routineDefaultDuration, equals(15));
        expect(prefs.analyticalDefaultDuration, equals(90));
        expect(prefs.meetingDefaultEnergy, equals('high'));
        expect(prefs.meetingDefaultFocus, equals('deep'));
        expect(prefs.creativeDefaultEnergy, equals('medium'));
        expect(prefs.creativeDefaultFocus, equals('medium'));
        expect(prefs.routineDefaultEnergy, equals('medium'));
        expect(prefs.routineDefaultFocus, equals('medium'));
        expect(prefs.analyticalDefaultEnergy, equals('high'));
        expect(prefs.analyticalDefaultFocus, equals('deep'));
        expect(prefs.tomorrowDefaultTime, equals('10:00'));
        expect(prefs.nextWeekDefaultDay, equals('wednesday'));
        expect(prefs.workTimePreference, equals('morning'));
        expect(prefs.apiCallCount, equals(5));
        expect(prefs.lastApiCallTime, equals(testTime));
      });

      // 验证是否能处理缺失字段
      test('should use default values for missing JSON fields', () {
        // 空JSON
        final json = <String, dynamic>{};
        final prefs = AIPreferences.fromJson(json);

        // 验证所有字段都使用了默认值
        expect(prefs.meetingDefaultDuration, equals(60));
        expect(prefs.creativeDefaultDuration, equals(90));
        expect(prefs.routineDefaultDuration, equals(30));
        expect(prefs.analyticalDefaultDuration, equals(60));
        expect(prefs.meetingDefaultEnergy, equals('medium'));
        expect(prefs.meetingDefaultFocus, equals('medium'));
        expect(prefs.creativeDefaultEnergy, equals('high'));
        expect(prefs.creativeDefaultFocus, equals('deep'));
        expect(prefs.routineDefaultEnergy, equals('low'));
        expect(prefs.routineDefaultFocus, equals('light'));
        expect(prefs.analyticalDefaultEnergy, equals('medium'));
        expect(prefs.analyticalDefaultFocus, equals('deep'));
        expect(prefs.tomorrowDefaultTime, equals('09:00'));
        expect(prefs.nextWeekDefaultDay, equals('monday'));
        expect(prefs.workTimePreference, equals('balanced'));
        expect(prefs.apiCallCount, equals(0));
        expect(prefs.lastApiCallTime, isNull);
      });

      // 验证部分JSON处理
      test('should handle partial JSON correctly', () {
        // 只包含部分字段的JSON
        final json = {
          'meetingDefaultDuration': 45,
          'creativeDefaultEnergy': 'low',
          'workTimePreference': 'night',
        };

        final prefs = AIPreferences.fromJson(json);

        // 验证指定的字段使用了JSON中的值
        expect(prefs.meetingDefaultDuration, equals(45));
        expect(prefs.creativeDefaultEnergy, equals('low'));
        expect(prefs.workTimePreference, equals('night'));
        // 其他字段应使用默认值
        expect(prefs.creativeDefaultDuration, equals(90));
        expect(prefs.routineDefaultDuration, equals(30));
      });
    });

    // CopyWith 测试
    group('CopyWith Tests', () {
      // 测试部分字段修改
      test('should copy with some values changed', () {
        // 创建原始对象,只设置了部分字段
        final original = AIPreferences(
          meetingDefaultDuration: 60,
          apiCallCount: 10,
          lastApiCallTime: DateTime(2024, 1, 1),
        );

        // 使用copyWith创建修改后的副本
        final modified = original.copyWith(
          meetingDefaultDuration: 90,
          creativeDefaultEnergy: 'low',
          apiCallCount: 15,
        );

        // 验证修改的字段确实被更新了
        expect(modified.meetingDefaultDuration, equals(90));
        expect(modified.creativeDefaultEnergy, equals('low'));
        expect(modified.apiCallCount, equals(15));
        // 未修改的字段应保持原值
        expect(modified.creativeDefaultDuration, equals(original.creativeDefaultDuration));
        expect(modified.lastApiCallTime, equals(original.lastApiCallTime));
      });

      // 测试无参数复制
      test('should preserve all values when no parameters passed', () {
        final testTime = DateTime.now();
        // 创建一个包含所有自定义值的完整对象
        final original = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 15,
          analyticalDefaultDuration: 90,
          meetingDefaultEnergy: 'high',
          meetingDefaultFocus: 'deep',
          creativeDefaultEnergy: 'medium',
          creativeDefaultFocus: 'medium',
          routineDefaultEnergy: 'medium',
          routineDefaultFocus: 'medium',
          analyticalDefaultEnergy: 'high',
          analyticalDefaultFocus: 'deep',
          tomorrowDefaultTime: '10:00',
          nextWeekDefaultDay: 'wednesday',
          workTimePreference: 'morning',
          apiCallCount: 5,
          lastApiCallTime: testTime,
        );

        // 调用copyWith()但不传递任何参数
        final copied = original.copyWith();

        // 逐一验证所有字段都保持原值
        expect(copied.meetingDefaultDuration, equals(original.meetingDefaultDuration));
        expect(copied.creativeDefaultDuration, equals(original.creativeDefaultDuration));
        expect(copied.routineDefaultDuration, equals(original.routineDefaultDuration));
        expect(copied.analyticalDefaultDuration, equals(original.analyticalDefaultDuration));
        expect(copied.meetingDefaultEnergy, equals(original.meetingDefaultEnergy));
        expect(copied.meetingDefaultFocus, equals(original.meetingDefaultFocus));
        expect(copied.creativeDefaultEnergy, equals(original.creativeDefaultEnergy));
        expect(copied.creativeDefaultFocus, equals(original.creativeDefaultFocus));
        expect(copied.routineDefaultEnergy, equals(original.routineDefaultEnergy));
        expect(copied.routineDefaultFocus, equals(original.routineDefaultFocus));
        expect(copied.analyticalDefaultEnergy, equals(original.analyticalDefaultEnergy));
        expect(copied.analyticalDefaultFocus, equals(original.analyticalDefaultFocus));
        expect(copied.tomorrowDefaultTime, equals(original.tomorrowDefaultTime));
        expect(copied.nextWeekDefaultDay, equals(original.nextWeekDefaultDay));
        expect(copied.workTimePreference, equals(original.workTimePreference));
        expect(copied.apiCallCount, equals(original.apiCallCount));
        expect(copied.lastApiCallTime, equals(original.lastApiCallTime));
      });
    });

    // GenerateParsingRules测试
    group('GenerateParsingRules Tests', () {
      // 测试默认值规则生成
      test('should generate parsing rules with default values', () {
        // 创建使用默认值的对象
        final prefs = AIPreferences();
        // 生成解析规则字符串
        final rules = prefs.generateParsingRules();

        // 验证规则包含正确的默认时长
        expect(rules.contains('Meetings/calls: 60 minutes'), isTrue);
        expect(rules.contains('Creative work: 90 minutes'), isTrue);
        expect(rules.contains('Routine tasks: 30 minutes'), isTrue);
        expect(rules.contains('Analytical tasks: 60 minutes'), isTrue);
        // 验证时间相关规则
        expect(rules.contains('"tomorrow" should default to 09:00'), isTrue);
        expect(rules.contains('"next week" should default to monday'), isTrue);
        expect(rules.contains('Work time preference: balanced'), isTrue);
        // 验证能量和专注度规则
        expect(rules.contains('meetings/calls, default to medium energy and medium focus'), isTrue);
        expect(rules.contains('creative work, default to high energy and deep focus'), isTrue);
        expect(rules.contains('routine tasks, default to low energy and light focus'), isTrue);
        expect(rules.contains('analytical tasks, default to medium energy and deep focus'), isTrue);
      });

      // 测试自定义值规则生成
      test('should generate parsing rules with custom values', () {
        // 创建包含自定义值的对象
        final prefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 15,
          analyticalDefaultDuration: 75,
          meetingDefaultEnergy: 'high',
          meetingDefaultFocus: 'deep',
          creativeDefaultEnergy: 'medium',
          creativeDefaultFocus: 'medium',
          routineDefaultEnergy: 'medium',
          routineDefaultFocus: 'medium',
          analyticalDefaultEnergy: 'high',
          analyticalDefaultFocus: 'deep',
          tomorrowDefaultTime: '10:00',
          nextWeekDefaultDay: 'wednesday',
          workTimePreference: 'morning',
        );

        final rules = prefs.generateParsingRules();

        // 验证规则反映了自定义值
        expect(rules.contains('Meetings/calls: 45 minutes'), isTrue);
        expect(rules.contains('Creative work: 120 minutes'), isTrue);
        expect(rules.contains('Routine tasks: 15 minutes'), isTrue);
        expect(rules.contains('Analytical tasks: 75 minutes'), isTrue);
        expect(rules.contains('"tomorrow" should default to 10:00'), isTrue);
        expect(rules.contains('"next week" should default to wednesday'), isTrue);
        expect(rules.contains('Work time preference: morning'), isTrue);
        // 验证自定义的能量和专注度规则
        expect(rules.contains('meetings/calls, default to high energy and deep focus'), isTrue);
        expect(rules.contains('creative work, default to medium energy and medium focus'), isTrue);
        expect(rules.contains('routine tasks, default to medium energy and medium focus'), isTrue);
        expect(rules.contains('analytical tasks, default to high energy and deep focus'), isTrue);
      });

      // 测试规则完整性
      test('should include all parsing rule sections', () {
        final prefs = AIPreferences();
        final rules = prefs.generateParsingRules();

        // 检查是否包含所有主要部分
        expect(rules.contains('Parsing rules:'), isTrue);
        expect(rules.contains('1. If duration is not specified'), isTrue);
        expect(rules.contains('2. If priority is not mentioned'), isTrue);
        expect(rules.contains('3. Infer appropriate category'), isTrue);
        expect(rules.contains('4. If relative time'), isTrue);
        expect(rules.contains('5. If no specific time is mentioned'), isTrue);
        expect(rules.contains('6. For meetings/calls'), isTrue);
        expect(rules.contains('7. For creative work'), isTrue);
        expect(rules.contains('8. For routine tasks'), isTrue);
        expect(rules.contains('9. For analytical tasks'), isTrue);
      });
    });

    // 业务逻辑验证
    group('Business Logic Validation', () {
      // 默认时长合理性测试
      test('default durations should be reasonable', () {
        // 获取默认偏好设置
        final prefs = AIPreferences.defaultPreferences;

        // 验证会议默认时长在合理范围内（15-120分钟）
        expect(prefs.meetingDefaultDuration >= 15, isTrue);
        expect(prefs.meetingDefaultDuration <= 120, isTrue);
        // 验证创意工作时长范围（30-180分钟）
        expect(prefs.creativeDefaultDuration >= 30, isTrue);
        expect(prefs.creativeDefaultDuration <= 180, isTrue);
        // 验证日常任务时长范围（10-60分钟）
        expect(prefs.routineDefaultDuration >= 10, isTrue);
        expect(prefs.routineDefaultDuration <= 60, isTrue);
        // 验证分析任务时长范围（30-120分钟）
        expect(prefs.analyticalDefaultDuration >= 30, isTrue);
        expect(prefs.analyticalDefaultDuration <= 120, isTrue);
      });

      // 能量和专注度级别验证
      test('energy and focus levels should be valid', () {
        final prefs = AIPreferences.defaultPreferences;
        // 定义有效的能量级别
        final validEnergy = ['low', 'medium', 'high'];
        // 定义有效的专注度级别
        final validFocus = ['light', 'medium', 'deep'];

        // 验证会议的能量和专注度设置
        expect(validEnergy.contains(prefs.meetingDefaultEnergy), isTrue);
        expect(validFocus.contains(prefs.meetingDefaultFocus), isTrue);
        // 验证创意工作的能量和专注度设置
        expect(validEnergy.contains(prefs.creativeDefaultEnergy), isTrue);
        expect(validFocus.contains(prefs.creativeDefaultFocus), isTrue);
        // 验证日常任务的能量和专注度设置
        expect(validEnergy.contains(prefs.routineDefaultEnergy), isTrue);
        expect(validFocus.contains(prefs.routineDefaultFocus), isTrue);
        // 验证分析任务的能量和专注度设置
        expect(validEnergy.contains(prefs.analyticalDefaultEnergy), isTrue);
        expect(validFocus.contains(prefs.analyticalDefaultFocus), isTrue);
      });

      // 工作时间偏好验证
      test('work time preference should be valid', () {
        final prefs = AIPreferences.defaultPreferences;
        // 定义有效的工作时间偏好
        final validPreferences = ['morning', 'balanced', 'night'];

        // 验证工作时间偏好是有效值之一
        expect(validPreferences.contains(prefs.workTimePreference), isTrue);
      });

      // 时间格式验证
      test('time format should be valid', () {
        final prefs = AIPreferences.defaultPreferences;

        // 使用正则表达式验证时间格式为HH:mm
        expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(prefs.tomorrowDefaultTime), isTrue);
      });

      // 默认任务特征逻辑验证
      test('default task characteristics should make sense', () {
        final prefs = AIPreferences.defaultPreferences;

        // 创意工作应该需要更多能量和专注度
        expect(prefs.creativeDefaultEnergy, equals('high'));
        expect(prefs.creativeDefaultFocus, equals('deep'));

        // 日常任务应该需要较少能量和专注度
        expect(prefs.routineDefaultEnergy, equals('low'));
        expect(prefs.routineDefaultFocus, equals('light'));

        // 分析工作应该需要深度专注
        expect(prefs.analyticalDefaultFocus, equals('deep'));
      });
    });

    // API使用追踪测试
    group('API Usage Tracking Tests', () {
      // 创建初始对象,API调用次数为0
      test('should track API call count', () {
        final prefs1 = AIPreferences(apiCallCount: 0);
        // 使用copyWith增加调用次数
        final prefs2 = prefs1.copyWith(apiCallCount: prefs1.apiCallCount + 1);

        // 验证计数器增加了
        expect(prefs2.apiCallCount, equals(1));
      });

      // 最后调用时间追踪
      test('should track last API call time', () {
        // 获取当前时间
        final now = DateTime.now();
        // 创建初始对象
        final prefs1 = AIPreferences();
        // 更新最后调用时间
        final prefs2 = prefs1.copyWith(lastApiCallTime: now);

        // 验证时间被正确记录
        expect(prefs2.lastApiCallTime, equals(now));
      });

      // API追踪数据的持久化
      test('should serialize and deserialize API tracking data correctly', () {
        // 创建测试时间
        final testTime = DateTime(2024, 1, 15, 10, 30);
        // 创建包含API追踪数据的对象
        final prefs = AIPreferences(
          apiCallCount: 42,
          lastApiCallTime: testTime,
        );

        // 序列化为JSON
        final json = prefs.toJson();
        // 从JSON恢复
        final restored = AIPreferences.fromJson(json);

        // 验证数据完整恢复
        expect(restored.apiCallCount, equals(42));
        expect(restored.lastApiCallTime, equals(testTime));
      });
    });
  });
}