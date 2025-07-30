import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_time_manager/services/scheduler_preferences_service.dart';
import 'package:smart_time_manager/models/scheduler_preferences.dart';
import 'dart:convert';

// 测试初始化
void main() {
  group('SchedulerPreferencesService Tests', () {
    // 在每个测试前清理SharedPreferences
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('savePreferences and loadPreferences', () {
      // 保存和加载测试
      test('should save and load preferences correctly', () async {
        // 创建测试用的SchedulerPreferences对象
        final testPrefs = SchedulerPreferences(
          energyMatchWeight: 30,
          focusMatchWeight: 25,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: false,
          avoidFragmentation: false,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 10,
        );

        // 保存偏好设置
        await SchedulerPreferencesService.savePreferences(testPrefs);

        // 加载偏好设置
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();

        // 验证所有字段都正确保存和加载
        expect(loadedPrefs.energyMatchWeight, equals(30));
        expect(loadedPrefs.focusMatchWeight, equals(25));
        expect(loadedPrefs.categoryMatchWeight, equals(20));
        expect(loadedPrefs.priorityMatchWeight, equals(15));
        expect(loadedPrefs.timeUtilizationWeight, equals(5));
        expect(loadedPrefs.morningBoostWeight, equals(5));
        expect(loadedPrefs.preferMorningForHighPriority, isFalse);
        expect(loadedPrefs.avoidFragmentation, isFalse);
        expect(loadedPrefs.groupSimilarTasks, isTrue);
        expect(loadedPrefs.minBreakBetweenTasks, equals(10));
      });

      // 权重不归一化测试
      test('should save weights as provided without normalization', () async {
        // 创建权重总和不等于100的偏好设置
        final testPrefs = SchedulerPreferences(
          energyMatchWeight: 40,
          focusMatchWeight: 40,
          categoryMatchWeight: 40,
          priorityMatchWeight: 40,
          timeUtilizationWeight: 20,
          morningBoostWeight: 20,
          preferMorningForHighPriority: true,
          avoidFragmentation: true,
          groupSimilarTasks: false,
          minBreakBetweenTasks: 15,
        );

        // 保存偏好设置
        await SchedulerPreferencesService.savePreferences(testPrefs);

        // 加载偏好设置
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();

        // 验证权重按原样保存
        expect(loadedPrefs.energyMatchWeight, equals(40));
        expect(loadedPrefs.focusMatchWeight, equals(40));
        expect(loadedPrefs.categoryMatchWeight, equals(40));
        expect(loadedPrefs.priorityMatchWeight, equals(40));
        expect(loadedPrefs.timeUtilizationWeight, equals(20));
        expect(loadedPrefs.morningBoostWeight, equals(20));
      });

      // 无数据时返回默认值
      test('should return default preferences when no data exists', () async {
        // 不保存任何数据,直接加载
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();

        // 应该返回默认设置
        expect(loadedPrefs.energyMatchWeight, equals(25));
        expect(loadedPrefs.focusMatchWeight, equals(25));
        expect(loadedPrefs.categoryMatchWeight, equals(25));
        expect(loadedPrefs.priorityMatchWeight, equals(25));
        expect(loadedPrefs.timeUtilizationWeight, equals(0));
        expect(loadedPrefs.morningBoostWeight, equals(0));
        expect(loadedPrefs.preferMorningForHighPriority, isTrue);
        expect(loadedPrefs.avoidFragmentation, isTrue);
        expect(loadedPrefs.groupSimilarTasks, isFalse);
        expect(loadedPrefs.minBreakBetweenTasks, equals(15));
      });

      // 测试数据损坏处理
      test('should return default preferences when data is corrupted', () async {
        // 模拟损坏的 JSON 数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('scheduler_preferences', 'invalid json data');

        // 加载偏好设置
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();

        // 应该返回默认设置
        expect(loadedPrefs.energyMatchWeight, equals(25));
        expect(loadedPrefs.minBreakBetweenTasks, equals(15));
      });

      // 测试部分数据处理
      test('should handle partial JSON data', () async {
        // 创建部分数据的 JSON
        final partialJson = jsonEncode({
          'energyMatchWeight': 35,
          'focusMatchWeight': 30,
          // 缺少其他字段
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('scheduler_preferences', partialJson);

        // 加载偏好设置
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();

        // 已提供的字段应该使用提供的值
        expect(loadedPrefs.energyMatchWeight, equals(35));
        expect(loadedPrefs.focusMatchWeight, equals(30));

        // 缺失的字段应该使用 fromJson 中的默认值
        expect(loadedPrefs.preferMorningForHighPriority, isTrue);
        expect(loadedPrefs.minBreakBetweenTasks, equals(5));
      });
    });

    group('resetToDefault', () {
      // 重置功能测试
      test('should reset all preferences to default values', () async {
        // 先保存一些自定义设置
        final customPrefs = SchedulerPreferences(
          energyMatchWeight: 40,
          focusMatchWeight: 20,
          categoryMatchWeight: 20,
          priorityMatchWeight: 10,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: false,
          avoidFragmentation: false,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 20,
        );
        await SchedulerPreferencesService.savePreferences(customPrefs);

        // 验证自定义设置已保存
        var loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        expect(loadedPrefs.energyMatchWeight, equals(40));
        expect(loadedPrefs.minBreakBetweenTasks, equals(20));

        // 重置为默认设置
        await SchedulerPreferencesService.resetToDefault();

        // 加载并验证是否为默认值
        loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        expect(loadedPrefs.energyMatchWeight, equals(25));
        expect(loadedPrefs.focusMatchWeight, equals(25));
        expect(loadedPrefs.categoryMatchWeight, equals(25));
        expect(loadedPrefs.priorityMatchWeight, equals(25));
        expect(loadedPrefs.timeUtilizationWeight, equals(0));
        expect(loadedPrefs.morningBoostWeight, equals(0));
        expect(loadedPrefs.preferMorningForHighPriority, isTrue);
        expect(loadedPrefs.avoidFragmentation, isTrue);
        expect(loadedPrefs.groupSimilarTasks, isFalse);
        expect(loadedPrefs.minBreakBetweenTasks, equals(15));
      });
    });

    // 预设模式测试
    group('applyPreset', () {
      // 平衡模式
      test('should apply balanced preset correctly', () async {
        // 应用平衡模式预设
        await SchedulerPreferencesService.applyPreset('balanced');

        // 加载并验证
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        final expectedPreset = SchedulerPreferences.presets['balanced']!;

        expect(loadedPrefs.energyMatchWeight, equals(expectedPreset.energyMatchWeight));
        expect(loadedPrefs.focusMatchWeight, equals(expectedPreset.focusMatchWeight));
        expect(loadedPrefs.categoryMatchWeight, equals(expectedPreset.categoryMatchWeight));
        expect(loadedPrefs.priorityMatchWeight, equals(expectedPreset.priorityMatchWeight));
        expect(loadedPrefs.timeUtilizationWeight, equals(expectedPreset.timeUtilizationWeight));
        expect(loadedPrefs.morningBoostWeight, equals(expectedPreset.morningBoostWeight));
        expect(loadedPrefs.preferMorningForHighPriority, equals(expectedPreset.preferMorningForHighPriority));
        expect(loadedPrefs.avoidFragmentation, equals(expectedPreset.avoidFragmentation));
        expect(loadedPrefs.groupSimilarTasks, equals(expectedPreset.groupSimilarTasks));
        expect(loadedPrefs.minBreakBetweenTasks, equals(expectedPreset.minBreakBetweenTasks));
      });

      // 能量优先模式
      test('should apply energy_focused preset correctly', () async {
        // 应用能量优先模式预设
        await SchedulerPreferencesService.applyPreset('energy_focused');

        // 加载并验证
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        final expectedPreset = SchedulerPreferences.presets['energy_focused']!;

        expect(loadedPrefs.energyMatchWeight, equals(expectedPreset.energyMatchWeight));
        expect(loadedPrefs.focusMatchWeight, equals(expectedPreset.focusMatchWeight));
        expect(loadedPrefs.categoryMatchWeight, equals(expectedPreset.categoryMatchWeight));
        expect(loadedPrefs.priorityMatchWeight, equals(expectedPreset.priorityMatchWeight));
      });

      // 优先级优先模式
      test('should apply priority_focused preset correctly', () async {
        // 应用优先级优先模式预设
        await SchedulerPreferencesService.applyPreset('priority_focused');

        // 加载并验证
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        final expectedPreset = SchedulerPreferences.presets['priority_focused']!;

        expect(loadedPrefs.priorityMatchWeight, equals(expectedPreset.priorityMatchWeight));
        expect(loadedPrefs.energyMatchWeight, equals(expectedPreset.energyMatchWeight));
      });

      // 测试效率优先模式
      test('should apply efficiency_focused preset correctly', () async {
        // 应用效率优先模式预设
        await SchedulerPreferencesService.applyPreset('efficiency_focused');

        // 加载并验证
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        final expectedPreset = SchedulerPreferences.presets['efficiency_focused']!;

        expect(loadedPrefs.timeUtilizationWeight, equals(expectedPreset.timeUtilizationWeight));
        expect(loadedPrefs.groupSimilarTasks, equals(expectedPreset.groupSimilarTasks));
        expect(loadedPrefs.minBreakBetweenTasks, equals(expectedPreset.minBreakBetweenTasks));
      });

      // 验证无效预设处理
      test('should handle invalid preset name gracefully', () async {
        // 先保存一个自定义设置
        final customPrefs = SchedulerPreferences(
          energyMatchWeight: 35,
          focusMatchWeight: 25,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 3,
          morningBoostWeight: 2,
          preferMorningForHighPriority: true,
          avoidFragmentation: true,
          groupSimilarTasks: false,
          minBreakBetweenTasks: 10,
        );
        await SchedulerPreferencesService.savePreferences(customPrefs);

        // 尝试应用不存在的预设
        await SchedulerPreferencesService.applyPreset('non_existent_preset');

        // 设置应该保持不变
        final loadedPrefs = await SchedulerPreferencesService.loadPreferences();
        expect(loadedPrefs.energyMatchWeight, equals(35));
        expect(loadedPrefs.focusMatchWeight, equals(25));
        expect(loadedPrefs.minBreakBetweenTasks, equals(10));
      });

      // 验证所有预设存在
      test('should verify all expected presets exist', () {
        // 验证所有预期的预设都存在
        expect(SchedulerPreferences.presets.containsKey('balanced'), isTrue);
        expect(SchedulerPreferences.presets.containsKey('energy_focused'), isTrue);
        expect(SchedulerPreferences.presets.containsKey('priority_focused'), isTrue);
        expect(SchedulerPreferences.presets.containsKey('efficiency_focused'), isTrue);
      });
    });

    // 集成测试
    group('Integration Tests', () {
      test('should handle complete workflow correctly', () async {
        // 1. 从默认设置开始
        var prefs = await SchedulerPreferencesService.loadPreferences();
        expect(prefs.energyMatchWeight, equals(25));

        // 2. 应用一个预设
        await SchedulerPreferencesService.applyPreset('energy_focused');
        prefs = await SchedulerPreferencesService.loadPreferences();
        expect(prefs.energyMatchWeight, equals(40)); // Energy focused preset value

        // 3. 修改设置
        final modifiedPrefs = prefs.copyWith(
          minBreakBetweenTasks: 20,
          groupSimilarTasks: true,
        );
        await SchedulerPreferencesService.savePreferences(modifiedPrefs);

        // 4. 验证修改
        prefs = await SchedulerPreferencesService.loadPreferences();
        expect(prefs.minBreakBetweenTasks, equals(20));
        expect(prefs.groupSimilarTasks, isTrue);
        expect(prefs.energyMatchWeight, equals(40)); // 保持不变

        // 5. 应用另一个预设
        await SchedulerPreferencesService.applyPreset('balanced');
        prefs = await SchedulerPreferencesService.loadPreferences();
        expect(prefs.energyMatchWeight, equals(25)); // Balanced preset value
        expect(prefs.minBreakBetweenTasks, equals(15)); // Balanced preset value

        // 6. 重置为默认
        await SchedulerPreferencesService.resetToDefault();
        prefs = await SchedulerPreferencesService.loadPreferences();
        expect(prefs.energyMatchWeight, equals(25));
      });

      // 测试数据完整性测试
      test('should maintain data integrity through multiple operations', () async {
        // 测试多次保存和加载的数据完整性
        final testPrefs = SchedulerPreferences(
          energyMatchWeight: 33,
          focusMatchWeight: 22,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 7,
          morningBoostWeight: 3,
          preferMorningForHighPriority: true,
          avoidFragmentation: false,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 12,
        );

        // 多次保存和加载
        for (int i = 0; i < 5; i++) {
          await SchedulerPreferencesService.savePreferences(testPrefs);
          final loaded = await SchedulerPreferencesService.loadPreferences();

          expect(loaded.energyMatchWeight, equals(33));
          expect(loaded.focusMatchWeight, equals(22));
          expect(loaded.categoryMatchWeight, equals(20));
          expect(loaded.priorityMatchWeight, equals(15));
          expect(loaded.timeUtilizationWeight, equals(7));
          expect(loaded.morningBoostWeight, equals(3));
          expect(loaded.preferMorningForHighPriority, isTrue);
          expect(loaded.avoidFragmentation, isFalse);
          expect(loaded.groupSimilarTasks, isTrue);
          expect(loaded.minBreakBetweenTasks, equals(12));
        }
      });

      // 预设切换测试
      test('should correctly switch between different presets', () async {
        // 测试在不同预设间切换
        final presetNames = ['balanced', 'energy_focused', 'priority_focused', 'efficiency_focused'];

        for (final presetName in presetNames) {
          await SchedulerPreferencesService.applyPreset(presetName);
          final loaded = await SchedulerPreferencesService.loadPreferences();
          final expected = SchedulerPreferences.presets[presetName]!;

          // 验证加载的设置与预设匹配
          expect(loaded.energyMatchWeight, equals(expected.energyMatchWeight));
          expect(loaded.focusMatchWeight, equals(expected.focusMatchWeight));
          expect(loaded.categoryMatchWeight, equals(expected.categoryMatchWeight));
          expect(loaded.priorityMatchWeight, equals(expected.priorityMatchWeight));
          expect(loaded.timeUtilizationWeight, equals(expected.timeUtilizationWeight));
          expect(loaded.morningBoostWeight, equals(expected.morningBoostWeight));
          expect(loaded.preferMorningForHighPriority, equals(expected.preferMorningForHighPriority));
          expect(loaded.avoidFragmentation, equals(expected.avoidFragmentation));
          expect(loaded.groupSimilarTasks, equals(expected.groupSimilarTasks));
          expect(loaded.minBreakBetweenTasks, equals(expected.minBreakBetweenTasks));
        }
      });
    });
  });
}