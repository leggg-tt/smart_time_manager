import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_time_manager/services/ai_preferences_service.dart';
import 'package:smart_time_manager/models/ai_preferences.dart';

void main() {
  // 测试组设置
  group('AIPreferencesService Tests', () {
    // 在每个测试前清理SharedPreferences
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // 保存和加载偏好设置测试
    group('savePreferences and loadPreferences', () {
      // 完整保存和加载测试
      test('should save and load preferences correctly', () async {
        // 创建测试用的AIPreferences对象
        final testPrefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 25,
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
          nextWeekDefaultDay: 'tuesday',
          workTimePreference: 'morning',
          apiCallCount: 5,
          lastApiCallTime: DateTime(2024, 1, 15, 10, 30),
        );

        // 保存偏好设置
        await AIPreferencesService.savePreferences(testPrefs);

        // 加载偏好设置
        final loadedPrefs = await AIPreferencesService.loadPreferences();

        // 验证所有字段都正确保存和加载
        expect(loadedPrefs.meetingDefaultDuration, equals(testPrefs.meetingDefaultDuration));
        expect(loadedPrefs.creativeDefaultDuration, equals(testPrefs.creativeDefaultDuration));
        expect(loadedPrefs.routineDefaultDuration, equals(testPrefs.routineDefaultDuration));
        expect(loadedPrefs.analyticalDefaultDuration, equals(testPrefs.analyticalDefaultDuration));
        expect(loadedPrefs.meetingDefaultEnergy, equals(testPrefs.meetingDefaultEnergy));
        expect(loadedPrefs.meetingDefaultFocus, equals(testPrefs.meetingDefaultFocus));
        expect(loadedPrefs.creativeDefaultEnergy, equals(testPrefs.creativeDefaultEnergy));
        expect(loadedPrefs.creativeDefaultFocus, equals(testPrefs.creativeDefaultFocus));
        expect(loadedPrefs.routineDefaultEnergy, equals(testPrefs.routineDefaultEnergy));
        expect(loadedPrefs.routineDefaultFocus, equals(testPrefs.routineDefaultFocus));
        expect(loadedPrefs.analyticalDefaultEnergy, equals(testPrefs.analyticalDefaultEnergy));
        expect(loadedPrefs.analyticalDefaultFocus, equals(testPrefs.analyticalDefaultFocus));
        expect(loadedPrefs.tomorrowDefaultTime, equals(testPrefs.tomorrowDefaultTime));
        expect(loadedPrefs.nextWeekDefaultDay, equals(testPrefs.nextWeekDefaultDay));
        expect(loadedPrefs.workTimePreference, equals(testPrefs.workTimePreference));
        expect(loadedPrefs.apiCallCount, equals(testPrefs.apiCallCount));
        expect(loadedPrefs.lastApiCallTime?.year, equals(testPrefs.lastApiCallTime?.year));
        expect(loadedPrefs.lastApiCallTime?.month, equals(testPrefs.lastApiCallTime?.month));
        expect(loadedPrefs.lastApiCallTime?.day, equals(testPrefs.lastApiCallTime?.day));
      });

      // 测试无数据时返回默认值
      test('should return default preferences when no data exists', () async {
        // 不保存任何数据，直接加载
        final loadedPrefs = await AIPreferencesService.loadPreferences();

        // 应该返回默认设置
        expect(loadedPrefs.meetingDefaultDuration, equals(60));
        expect(loadedPrefs.creativeDefaultDuration, equals(90));
        expect(loadedPrefs.routineDefaultDuration, equals(30));
        expect(loadedPrefs.analyticalDefaultDuration, equals(60));
        expect(loadedPrefs.meetingDefaultEnergy, equals('medium'));
        expect(loadedPrefs.meetingDefaultFocus, equals('medium'));
        expect(loadedPrefs.creativeDefaultEnergy, equals('high'));
        expect(loadedPrefs.creativeDefaultFocus, equals('deep'));
        expect(loadedPrefs.routineDefaultEnergy, equals('low'));
        expect(loadedPrefs.routineDefaultFocus, equals('light'));
        expect(loadedPrefs.analyticalDefaultEnergy, equals('medium'));
        expect(loadedPrefs.analyticalDefaultFocus, equals('deep'));
        expect(loadedPrefs.tomorrowDefaultTime, equals('09:00'));
        expect(loadedPrefs.nextWeekDefaultDay, equals('monday'));
        expect(loadedPrefs.workTimePreference, equals('balanced'));
        expect(loadedPrefs.apiCallCount, equals(0));
        expect(loadedPrefs.lastApiCallTime, isNull);
      });

      // 测试数据损坏时的处理
      test('should return default preferences when data is corrupted', () async {
        // 模拟损坏的JSON数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_preferences', 'invalid json data');

        // 加载偏好设置
        final loadedPrefs = await AIPreferencesService.loadPreferences();

        // 应该返回默认设置
        expect(loadedPrefs.meetingDefaultDuration, equals(60));
        expect(loadedPrefs.workTimePreference, equals('balanced'));
      });
    });

    // API调用计数测试
    group('incrementApiCallCount', () {
      // 验证增加调用次数
      test('should increment API call count and update last call time', () async {
        // 设置初始偏好
        final initialPrefs = AIPreferences(
          apiCallCount: 10,
          lastApiCallTime: DateTime(2024, 1, 1),
        );
        await AIPreferencesService.savePreferences(initialPrefs);

        // 记录当前时间（用于验证）- 稍微提前一点以避免时间精度问题
        final beforeCall = DateTime.now().subtract(Duration(milliseconds: 100));

        // 增加API调用计数
        await AIPreferencesService.incrementApiCallCount();

        // 加载更新后的偏好
        final updatedPrefs = await AIPreferencesService.loadPreferences();

        // 验证计数增加了1
        expect(updatedPrefs.apiCallCount, equals(11));

        // 验证最后调用时间已更新
        expect(updatedPrefs.lastApiCallTime, isNotNull);
        expect(updatedPrefs.lastApiCallTime!.isAfter(beforeCall), isTrue);
        expect(updatedPrefs.lastApiCallTime!.difference(beforeCall).inSeconds, lessThanOrEqualTo(2));
      });

      // 验证次数增加之后其他设置不变
      test('should preserve other settings when incrementing count', () async {
        // 设置具有自定义值的初始偏好
        final initialPrefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          workTimePreference: 'night',
          tomorrowDefaultTime: '14:00',
          apiCallCount: 5,
        );
        await AIPreferencesService.savePreferences(initialPrefs);

        // 增加API调用计数
        await AIPreferencesService.incrementApiCallCount();

        // 验证其他设置没有改变
        final updatedPrefs = await AIPreferencesService.loadPreferences();
        expect(updatedPrefs.meetingDefaultDuration, equals(45));
        expect(updatedPrefs.creativeDefaultDuration, equals(120));
        expect(updatedPrefs.workTimePreference, equals('night'));
        expect(updatedPrefs.tomorrowDefaultTime, equals('14:00'));
        expect(updatedPrefs.apiCallCount, equals(6));
      });
    });

    // 月度API调用计数测试
    group('getMonthlyApiCallCount', () {
      // 同月调用
      test('should return current count when last call is in the same month', () async {
        // 设置本月的调用记录
        final now = DateTime.now();
        final prefs = AIPreferences(
          apiCallCount: 25,
          lastApiCallTime: DateTime(now.year, now.month, 1),
        );
        await AIPreferencesService.savePreferences(prefs);

        // 获取月度计数
        final monthlyCount = await AIPreferencesService.getMonthlyApiCallCount();

        // 应该返回当前计数
        expect(monthlyCount, equals(25));
      });

      // 测试跨月重置
      test('should return 0 when last call is from previous month', () async {
        // 设置上个月的调用记录
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);
        final prefs = AIPreferences(
          apiCallCount: 100,
          lastApiCallTime: lastMonth,
        );
        await AIPreferencesService.savePreferences(prefs);

        // 获取月度计数
        final monthlyCount = await AIPreferencesService.getMonthlyApiCallCount();

        // 应该返回0（新月份）
        expect(monthlyCount, equals(0));

        // 验证计数已被重置
        final updatedPrefs = await AIPreferencesService.loadPreferences();
        expect(updatedPrefs.apiCallCount, equals(0));
      });

      test('should return 0 when lastApiCallTime is null', () async {
        // 设置没有最后调用时间的偏好
        final prefs = AIPreferences(
          apiCallCount: 50,
          lastApiCallTime: null,
        );
        await AIPreferencesService.savePreferences(prefs);

        // 获取月度计数
        final monthlyCount = await AIPreferencesService.getMonthlyApiCallCount();

        // 应该返回 0
        expect(monthlyCount, equals(0));
      });
    });

    group('resetToDefault', () {
      // 重置为默认值测试
      test('should reset all preferences to default values', () async {
        // 先保存一些自定义设置
        final customPrefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 20,
          analyticalDefaultDuration: 90,
          meetingDefaultEnergy: 'high',
          creativeDefaultEnergy: 'low',
          workTimePreference: 'night',
          tomorrowDefaultTime: '15:00',
          nextWeekDefaultDay: 'friday',
          apiCallCount: 100,
          lastApiCallTime: DateTime.now(),
        );
        await AIPreferencesService.savePreferences(customPrefs);

        // 重置为默认设置
        await AIPreferencesService.resetToDefault();

        // 加载并验证是否为默认值
        final loadedPrefs = await AIPreferencesService.loadPreferences();
        expect(loadedPrefs.meetingDefaultDuration, equals(60));
        expect(loadedPrefs.creativeDefaultDuration, equals(90));
        expect(loadedPrefs.routineDefaultDuration, equals(30));
        expect(loadedPrefs.analyticalDefaultDuration, equals(60));
        expect(loadedPrefs.meetingDefaultEnergy, equals('medium'));
        expect(loadedPrefs.creativeDefaultEnergy, equals('high'));
        expect(loadedPrefs.workTimePreference, equals('balanced'));
        expect(loadedPrefs.tomorrowDefaultTime, equals('09:00'));
        expect(loadedPrefs.nextWeekDefaultDay, equals('monday'));
        expect(loadedPrefs.apiCallCount, equals(0));
        expect(loadedPrefs.lastApiCallTime, isNull);
      });
    });

    // API连接测试
    group('testApiConnection', () {
      test('should return true for valid Anthropic API key format', () async {
        // 验证Anthropic API密钥格式
        final isValid = await AIPreferencesService.testApiConnection('sk-ant-api03-valid-key');
        expect(isValid, isTrue);
      });

      test('should return false for empty API key', () async {
        // 验证空密钥
        final isValid = await AIPreferencesService.testApiConnection('');
        expect(isValid, isFalse);
      });

      test('should return false for invalid API key format', () async {
        // 验证是否拒绝无效格式
        final isValid = await AIPreferencesService.testApiConnection('invalid-key-format');
        expect(isValid, isFalse);
      });
    });

    // 解析规则生成测试
    group('generateParsingRules', () {
      // 默认规则生成
      test('should generate parsing rules with default values', () async {
        final prefs = AIPreferences.defaultPreferences;
        final rules = prefs.generateParsingRules();

        // 验证规则中包含默认值
        expect(rules.contains('60 minutes'), isTrue); // meeting duration
        expect(rules.contains('90 minutes'), isTrue); // creative duration
        expect(rules.contains('30 minutes'), isTrue); // routine duration
        expect(rules.contains('09:00'), isTrue); // tomorrow default time
        expect(rules.contains('monday'), isTrue); // next week default day
        expect(rules.contains('balanced'), isTrue); // work time preference
      });

      // 自定义规则生成
      test('should generate parsing rules with custom values', () async {
        final prefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          tomorrowDefaultTime: '14:00',
          nextWeekDefaultDay: 'wednesday',
          workTimePreference: 'night',
        );
        final rules = prefs.generateParsingRules();

        // 验证规则中包含自定义值
        expect(rules.contains('45 minutes'), isTrue);
        expect(rules.contains('120 minutes'), isTrue);
        expect(rules.contains('14:00'), isTrue);
        expect(rules.contains('wednesday'), isTrue);
        expect(rules.contains('night'), isTrue);
      });
    });

    // 集成测试
    group('Integration Tests', () {
      test('should handle complete workflow correctly', () async {
        // 1. 从默认设置开始
        final initialPrefs = await AIPreferencesService.loadPreferences();
        expect(initialPrefs.apiCallCount, equals(0));
        expect(initialPrefs.workTimePreference, equals('balanced'));

        // 2. 更新设置
        final customPrefs = initialPrefs.copyWith(
          meetingDefaultDuration: 45,
          workTimePreference: 'morning',
          tomorrowDefaultTime: '08:00',
        );
        await AIPreferencesService.savePreferences(customPrefs);

        // 3. 进行几次 API 调用
        await AIPreferencesService.incrementApiCallCount();
        await AIPreferencesService.incrementApiCallCount();
        await AIPreferencesService.incrementApiCallCount();

        // 4. 检查月度计数
        final monthlyCount = await AIPreferencesService.getMonthlyApiCallCount();
        expect(monthlyCount, equals(3));

        // 5. 验证完整的偏好设置
        final finalPrefs = await AIPreferencesService.loadPreferences();
        expect(finalPrefs.meetingDefaultDuration, equals(45));
        expect(finalPrefs.workTimePreference, equals('morning'));
        expect(finalPrefs.tomorrowDefaultTime, equals('08:00'));
        expect(finalPrefs.apiCallCount, equals(3));
        expect(finalPrefs.lastApiCallTime, isNotNull);

        // 6. 验证生成的解析规则包含自定义值
        final rules = finalPrefs.generateParsingRules();
        expect(rules.contains('45 minutes'), isTrue);
        expect(rules.contains('08:00'), isTrue);
        expect(rules.contains('morning'), isTrue);
      });

      // 所有设置保持测试
      test('should preserve all task-specific settings when updating API count', () async {
        // 设置所有任务类型的自定义值
        final initialPrefs = AIPreferences(
          meetingDefaultDuration: 45,
          creativeDefaultDuration: 120,
          routineDefaultDuration: 20,
          analyticalDefaultDuration: 90,
          meetingDefaultEnergy: 'high',
          meetingDefaultFocus: 'deep',
          creativeDefaultEnergy: 'low',
          creativeDefaultFocus: 'light',
          routineDefaultEnergy: 'medium',
          routineDefaultFocus: 'medium',
          analyticalDefaultEnergy: 'high',
          analyticalDefaultFocus: 'deep',
          workTimePreference: 'night',
          apiCallCount: 5,
        );
        await AIPreferencesService.savePreferences(initialPrefs);

        // 增加 API 计数
        await AIPreferencesService.incrementApiCallCount();

        // 验证所有任务特定的设置都没有改变
        final updatedPrefs = await AIPreferencesService.loadPreferences();
        expect(updatedPrefs.meetingDefaultDuration, equals(45));
        expect(updatedPrefs.creativeDefaultDuration, equals(120));
        expect(updatedPrefs.routineDefaultDuration, equals(20));
        expect(updatedPrefs.analyticalDefaultDuration, equals(90));
        expect(updatedPrefs.meetingDefaultEnergy, equals('high'));
        expect(updatedPrefs.meetingDefaultFocus, equals('deep'));
        expect(updatedPrefs.creativeDefaultEnergy, equals('low'));
        expect(updatedPrefs.creativeDefaultFocus, equals('light'));
        expect(updatedPrefs.routineDefaultEnergy, equals('medium'));
        expect(updatedPrefs.routineDefaultFocus, equals('medium'));
        expect(updatedPrefs.analyticalDefaultEnergy, equals('high'));
        expect(updatedPrefs.analyticalDefaultFocus, equals('deep'));
        expect(updatedPrefs.workTimePreference, equals('night'));
        expect(updatedPrefs.apiCallCount, equals(6)); // 只有这个改变了
      });
    });
  });
}