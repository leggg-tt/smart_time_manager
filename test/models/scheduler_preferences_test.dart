import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/scheduler_preferences.dart';

void main() {
  group('SchedulerPreferences Tests', () {
    // 构造函数测试组
    group('Constructor Tests', () {
      // 测试构造函数是否正确创建对象
      test('should create preferences with all parameters', () {
        // 创建一个包含所有参数的偏好设置对象
        final prefs = SchedulerPreferences(
          energyMatchWeight: 30,
          focusMatchWeight: 25,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: true,
          avoidFragmentation: true,
          groupSimilarTasks: false,
          minBreakBetweenTasks: 10,
        );

        // 验证每个属性是否正确设置
        expect(prefs.energyMatchWeight, equals(30));
        expect(prefs.focusMatchWeight, equals(25));
        expect(prefs.categoryMatchWeight, equals(20));
        expect(prefs.priorityMatchWeight, equals(15));
        expect(prefs.timeUtilizationWeight, equals(5));
        expect(prefs.morningBoostWeight, equals(5));
        expect(prefs.preferMorningForHighPriority, isTrue);
        expect(prefs.avoidFragmentation, isTrue);
        expect(prefs.groupSimilarTasks, isFalse);
        expect(prefs.minBreakBetweenTasks, equals(10));
      });

      // 测试只提供必需参数时,可选参数是否使用默认值
      test('should use default values for behavior preferences', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 25,
          focusMatchWeight: 25,
          categoryMatchWeight: 25,
          priorityMatchWeight: 25,
          timeUtilizationWeight: 0,
          morningBoostWeight: 0,
        );

        expect(prefs.preferMorningForHighPriority, isTrue);
        expect(prefs.avoidFragmentation, isTrue);
        expect(prefs.groupSimilarTasks, isFalse);
        expect(prefs.minBreakBetweenTasks, equals(5));
      });
    });

    // 默认偏好设置测试
    group('Default Preferences Tests', () {
      // 测试静态默认偏好设置是否正确
      test('should have correct default values', () {
        final defaultPrefs = SchedulerPreferences.defaultPreferences;

        expect(defaultPrefs.energyMatchWeight, equals(25));
        expect(defaultPrefs.focusMatchWeight, equals(25));
        expect(defaultPrefs.categoryMatchWeight, equals(25));
        expect(defaultPrefs.priorityMatchWeight, equals(25));
        expect(defaultPrefs.timeUtilizationWeight, equals(0));
        expect(defaultPrefs.morningBoostWeight, equals(0));
        expect(defaultPrefs.minBreakBetweenTasks, equals(15));
      });

      // 验证所有权重之和是否为100
      test('default weights should sum to 100', () {
        final defaultPrefs = SchedulerPreferences.defaultPreferences;

        final totalWeight = defaultPrefs.energyMatchWeight +
            defaultPrefs.focusMatchWeight +
            defaultPrefs.categoryMatchWeight +
            defaultPrefs.priorityMatchWeight +
            defaultPrefs.timeUtilizationWeight +
            defaultPrefs.morningBoostWeight;

        expect(totalWeight, equals(100));
      });
    });

    // 预设配置测试
    group('Preset Configurations Tests', () {
      // 验证是否包含所有预期的预设方案
      test('should have all expected presets', () {
        final presets = SchedulerPreferences.presets;

        expect(presets.containsKey('balanced'), isTrue);
        expect(presets.containsKey('energy_focused'), isTrue);
        expect(presets.containsKey('priority_focused'), isTrue);
        expect(presets.containsKey('efficiency_focused'), isTrue);
        expect(presets.length, equals(4));
      });

      // 验证"平衡"预设的各项权重是否相等（各占25%）
      test('balanced preset should have equal main weights', () {
        final balanced = SchedulerPreferences.presets['balanced']!;

        expect(balanced.energyMatchWeight, equals(25));
        expect(balanced.focusMatchWeight, equals(25));
        expect(balanced.categoryMatchWeight, equals(25));
        expect(balanced.priorityMatchWeight, equals(25));
        expect(balanced.timeUtilizationWeight, equals(0));
        expect(balanced.morningBoostWeight, equals(0));
      });

      // 验证"能量优先"预设是否确实将能量匹配权重设置最高
      test('energy_focused preset should prioritize energy matching', () {
        final energyFocused = SchedulerPreferences.presets['energy_focused']!;

        expect(energyFocused.energyMatchWeight, equals(40));
        expect(energyFocused.energyMatchWeight > energyFocused.focusMatchWeight, isTrue);
        expect(energyFocused.energyMatchWeight > energyFocused.categoryMatchWeight, isTrue);
        expect(energyFocused.energyMatchWeight > energyFocused.priorityMatchWeight, isTrue);
      });

      // 验证"优先度优先"预设是否确实将优先度匹配权重设置最高
      test('priority_focused preset should prioritize priority matching', () {
        final priorityFocused = SchedulerPreferences.presets['priority_focused']!;

        expect(priorityFocused.priorityMatchWeight, equals(40));
        expect(priorityFocused.priorityMatchWeight > priorityFocused.energyMatchWeight, isTrue);
        expect(priorityFocused.priorityMatchWeight > priorityFocused.focusMatchWeight, isTrue);
        expect(priorityFocused.priorityMatchWeight > priorityFocused.categoryMatchWeight, isTrue);
      });

      // 验证效率重点预设应具有特定特征
      test('efficiency_focused preset should have specific characteristics', () {
        final efficiencyFocused = SchedulerPreferences.presets['efficiency_focused']!;

        expect(efficiencyFocused.timeUtilizationWeight, equals(15));
        expect(efficiencyFocused.morningBoostWeight, equals(5));
        expect(efficiencyFocused.groupSimilarTasks, isTrue);
        expect(efficiencyFocused.minBreakBetweenTasks, equals(5));

        // 应该减少休息时间以提高效率
        expect(efficiencyFocused.minBreakBetweenTasks <
            SchedulerPreferences.presets['balanced']!.minBreakBetweenTasks, isTrue);
      });

      // 验证所有预设都应具有有效的总重量
      test('all presets should have valid weight totals', () {
        for (final entry in SchedulerPreferences.presets.entries) {
          final preset = entry.value;
          final total = preset.energyMatchWeight +
              preset.focusMatchWeight +
              preset.categoryMatchWeight +
              preset.priorityMatchWeight +
              preset.timeUtilizationWeight +
              preset.morningBoostWeight;

          expect(total, equals(100),
              reason: '${entry.key} preset weights should sum to 100, but got $total');
        }
      });
    });

    //  归一化测试
    group('Normalization Tests', () {
      // 测试权重归一化功能（确保总和为100）
      test('should normalize weights to sum to 100', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 10,
          focusMatchWeight: 10,
          categoryMatchWeight: 10,
          priorityMatchWeight: 10,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
        );

        // 调用normalize()方法后,验证权重总和是否为100
        final normalized = prefs.normalize();

        final total = normalized.energyMatchWeight +
            normalized.focusMatchWeight +
            normalized.categoryMatchWeight +
            normalized.priorityMatchWeight +
            normalized.timeUtilizationWeight +
            normalized.morningBoostWeight;

        expect(total, equals(100));
      });

      // 验证归一化后权重比例是否保持不变
      test('should maintain weight proportions after normalization', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 40,
          focusMatchWeight: 20,
          categoryMatchWeight: 20,
          priorityMatchWeight: 10,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
        );

        final normalized = prefs.normalize();

        expect(normalized.energyMatchWeight / normalized.focusMatchWeight,
            closeTo(2.0, 0.1));

        expect(normalized.focusMatchWeight / normalized.priorityMatchWeight,
            closeTo(2.0, 0.1));
      });

      // 测试边界情况:当所有权重为0时的处理
      test('should return default preferences when total weight is zero', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 0,
          focusMatchWeight: 0,
          categoryMatchWeight: 0,
          priorityMatchWeight: 0,
          timeUtilizationWeight: 0,
          morningBoostWeight: 0,
        );

        final normalized = prefs.normalize();

        expect(normalized.energyMatchWeight, equals(25));
        expect(normalized.focusMatchWeight, equals(25));
        expect(normalized.categoryMatchWeight, equals(25));
        expect(normalized.priorityMatchWeight, equals(25));
      });

      // 验证是否在规范化过程中保留非权重属性
      test('should preserve non-weight properties during normalization', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 30,
          focusMatchWeight: 20,
          categoryMatchWeight: 20,
          priorityMatchWeight: 20,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: false,
          avoidFragmentation: false,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 20,
        );

        final normalized = prefs.normalize();

        expect(normalized.preferMorningForHighPriority, equals(prefs.preferMorningForHighPriority));
        expect(normalized.avoidFragmentation, equals(prefs.avoidFragmentation));
        expect(normalized.groupSimilarTasks, equals(prefs.groupSimilarTasks));
        expect(normalized.minBreakBetweenTasks, equals(prefs.minBreakBetweenTasks));
      });
    });

    // JSON序列化测试
    group('JSON Serialization Tests', () {
      // 测试对象转JSON功能
      test('should convert to JSON correctly', () {
        final prefs = SchedulerPreferences(
          energyMatchWeight: 30,
          focusMatchWeight: 25,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: false,
          avoidFragmentation: true,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 10,
        );

        final json = prefs.toJson();

        // 验证每个字段是否正确序列化
        expect(json['energyMatchWeight'], equals(30));
        expect(json['focusMatchWeight'], equals(25));
        expect(json['categoryMatchWeight'], equals(20));
        expect(json['priorityMatchWeight'], equals(15));
        expect(json['timeUtilizationWeight'], equals(5));
        expect(json['morningBoostWeight'], equals(5));
        expect(json['preferMorningForHighPriority'], isFalse);
        expect(json['avoidFragmentation'], isTrue);
        expect(json['groupSimilarTasks'], isTrue);
        expect(json['minBreakBetweenTasks'], equals(10));
      });

      // 测试从JSON创建对象功能
      test('should create from JSON correctly', () {
        final json = {
          'energyMatchWeight': 30,
          'focusMatchWeight': 25,
          'categoryMatchWeight': 20,
          'priorityMatchWeight': 15,
          'timeUtilizationWeight': 5,
          'morningBoostWeight': 5,
          'preferMorningForHighPriority': false,
          'avoidFragmentation': true,
          'groupSimilarTasks': true,
          'minBreakBetweenTasks': 10,
        };

        final prefs = SchedulerPreferences.fromJson(json);

        // 验证反序列化是否正确
        expect(prefs.energyMatchWeight, equals(30));
        expect(prefs.focusMatchWeight, equals(25));
        expect(prefs.categoryMatchWeight, equals(20));
        expect(prefs.priorityMatchWeight, equals(15));
        expect(prefs.timeUtilizationWeight, equals(5));
        expect(prefs.morningBoostWeight, equals(5));
        expect(prefs.preferMorningForHighPriority, isFalse);
        expect(prefs.avoidFragmentation, isTrue);
        expect(prefs.groupSimilarTasks, isTrue);
        expect(prefs.minBreakBetweenTasks, equals(10));
      });

      // 测试容错性:JSON缺少字段时是否使用默认值
      test('should use default values for missing JSON fields', () {
        final json = <String, dynamic>{};
        final prefs = SchedulerPreferences.fromJson(json);

        expect(prefs.energyMatchWeight, equals(25));
        expect(prefs.focusMatchWeight, equals(25));
        expect(prefs.categoryMatchWeight, equals(25));
        expect(prefs.priorityMatchWeight, equals(25));
        expect(prefs.timeUtilizationWeight, equals(5));
        expect(prefs.morningBoostWeight, equals(5));
        expect(prefs.preferMorningForHighPriority, isTrue);
        expect(prefs.avoidFragmentation, isTrue);
        expect(prefs.groupSimilarTasks, isFalse);
        expect(prefs.minBreakBetweenTasks, equals(5));
      });
    });

    // CopyWith测试
    group('CopyWith Tests', () {
      // 测试创建对象副本并修改部分属性
      test('should copy with some values changed', () {
        final original = SchedulerPreferences(
          energyMatchWeight: 25,
          focusMatchWeight: 25,
          categoryMatchWeight: 25,
          priorityMatchWeight: 25,
          timeUtilizationWeight: 0,
          morningBoostWeight: 0,
        );

        final modified = original.copyWith(
          energyMatchWeight: 40,
          minBreakBetweenTasks: 10,
        );

        // 验证只有指定属性被修改,其他保持不变
        expect(modified.energyMatchWeight, equals(40));
        expect(modified.focusMatchWeight, equals(25));
        expect(modified.categoryMatchWeight, equals(25));
        expect(modified.priorityMatchWeight, equals(25));
        expect(modified.minBreakBetweenTasks, equals(10));
      });

      // 测试当没有传递参数时应该保留所有值
      test('should preserve all values when no parameters passed', () {
        final original = SchedulerPreferences(
          energyMatchWeight: 30,
          focusMatchWeight: 25,
          categoryMatchWeight: 20,
          priorityMatchWeight: 15,
          timeUtilizationWeight: 5,
          morningBoostWeight: 5,
          preferMorningForHighPriority: false,
          avoidFragmentation: false,
          groupSimilarTasks: true,
          minBreakBetweenTasks: 20,
        );

        final copied = original.copyWith();

        expect(copied.energyMatchWeight, equals(original.energyMatchWeight));
        expect(copied.focusMatchWeight, equals(original.focusMatchWeight));
        expect(copied.categoryMatchWeight, equals(original.categoryMatchWeight));
        expect(copied.priorityMatchWeight, equals(original.priorityMatchWeight));
        expect(copied.timeUtilizationWeight, equals(original.timeUtilizationWeight));
        expect(copied.morningBoostWeight, equals(original.morningBoostWeight));
        expect(copied.preferMorningForHighPriority, equals(original.preferMorningForHighPriority));
        expect(copied.avoidFragmentation, equals(original.avoidFragmentation));
        expect(copied.groupSimilarTasks, equals(original.groupSimilarTasks));
        expect(copied.minBreakBetweenTasks, equals(original.minBreakBetweenTasks));
      });
    });

    // 业务逻辑验证
    group('Business Logic Validation', () {
      // 验证业务规则:休息时间应在合理范围内
      test('minimum break should be reasonable in all presets', () {
        for (final entry in SchedulerPreferences.presets.entries) {
          final preset = entry.value;
          expect(preset.minBreakBetweenTasks >= 5, isTrue,
              reason: '${entry.key}: Minimum break should be at least 5 minutes');
          expect(preset.minBreakBetweenTasks <= 30, isTrue,
              reason: '${entry.key}: Minimum break should not exceed 30 minutes');
        }
      });

      // 早晨高优先级偏好测试
      test('all presets should prefer morning for high priority', () {
        for (final preset in SchedulerPreferences.presets.values) {
          expect(preset.preferMorningForHighPriority, isTrue);
        }
      });

      // 避免时间碎片化测试
      test('all presets should avoid fragmentation', () {
        for (final preset in SchedulerPreferences.presets.values) {
          expect(preset.avoidFragmentation, isTrue);
        }
      });

      // 验证只有"效率优先"预设才会分组相似任务
      test('only efficiency preset should group similar tasks', () {
        expect(SchedulerPreferences.presets['balanced']!.groupSimilarTasks, isFalse);
        expect(SchedulerPreferences.presets['energy_focused']!.groupSimilarTasks, isFalse);
        expect(SchedulerPreferences.presets['priority_focused']!.groupSimilarTasks, isFalse);
        expect(SchedulerPreferences.presets['efficiency_focused']!.groupSimilarTasks, isTrue);
      });
    });
  });
}