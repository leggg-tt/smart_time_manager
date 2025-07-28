import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/enums.dart';

// 主测试组
void main() {
  // 枚举扩展测试
  group('Enums Extension Tests', () {
    // 优先级扩展测试
    group('Priority Extension Tests', () {
      // 测试displayName扩展方法是否返回正确的显示名称
      test('displayName should return correct values', () {
        expect(Priority.low.displayName, equals('Low'));
        expect(Priority.medium.displayName, equals('Medium'));
        expect(Priority.high.displayName, equals('High'));
      });

      // 测试value扩展方法是否返回正确的数值
      test('value should return correct numeric values', () {
        expect(Priority.low.value, equals(1));
        expect(Priority.medium.value, equals(2));
        expect(Priority.high.value, equals(3));
      });

      // 测试优先级的数值是否是递增的
      test('values should be in ascending order', () {
        expect(Priority.low.value < Priority.medium.value, isTrue);
        expect(Priority.medium.value < Priority.high.value, isTrue);
      });

      // 测试每个优先级的数值是否都是唯一的
      test('all priorities should have unique values', () {
        // 使用Set来检查重复
        final values = Priority.values.map((p) => p.value).toSet();
        expect(values.length, equals(Priority.values.length));
      });
    });

    // 任务状态扩展测试
    group('TaskStatus Extension Tests', () {
      // 测试每个状态的索引值是否都是唯一的
      test('all statuses should have unique index values', () {
        final indices = TaskStatus.values.map((s) => s.index).toSet();
        expect(indices.length, equals(TaskStatus.values.length));
      });

      // 测试枚举索引是否是从0开始连续的
      test('status indices should be sequential starting from 0', () {
        for (int i = 0; i < TaskStatus.values.length; i++) {
          expect(TaskStatus.values[i].index, equals(i));
        }
      });

      // 测试每个状态的索引值
      test('specific status values', () {
        expect(TaskStatus.pending.index, equals(0));
        expect(TaskStatus.scheduled.index, equals(1));
        expect(TaskStatus.inProgress.index, equals(2));
        expect(TaskStatus.completed.index, equals(3));
        expect(TaskStatus.cancelled.index, equals(4));
      });
    });

    // 能量等级扩展测试
    group('EnergyLevel Extension Tests', () {
      // 测试能量等级的显示名称
      test('displayName should return correct values', () {
        expect(EnergyLevel.low.displayName, equals('Low'));
        expect(EnergyLevel.medium.displayName, equals('Medium'));
        expect(EnergyLevel.high.displayName, equals('High'));
      });

      // 测试能量等级的数值
      test('value should return correct numeric values', () {
        expect(EnergyLevel.low.value, equals(1));
        expect(EnergyLevel.medium.value, equals(2));
        expect(EnergyLevel.high.value, equals(3));
      });

      // 测试能量等级的数值是否是递增的
      test('values should be in ascending order', () {
        expect(EnergyLevel.low.value < EnergyLevel.medium.value, isTrue);
        expect(EnergyLevel.medium.value < EnergyLevel.high.value, isTrue);
      });

      // 测试每个能量等级的数值是否都是唯一的
      test('all energy levels should have unique values', () {
        final values = EnergyLevel.values.map((e) => e.value).toSet();
        expect(values.length, equals(EnergyLevel.values.length));
      });
    });

    // 专注度扩展测试
    group('FocusLevel Extension Tests', () {
      // 测试专注度等级的显示名称
      test('displayName should return correct values', () {
        expect(FocusLevel.light.displayName, equals('Light'));
        expect(FocusLevel.medium.displayName, equals('Medium'));
        expect(FocusLevel.deep.displayName, equals('Deep'));
      });

      // 测试专注度的数值
      test('value should return correct numeric values', () {
        expect(FocusLevel.light.value, equals(1));
        expect(FocusLevel.medium.value, equals(2));
        expect(FocusLevel.deep.value, equals(3));
      });

      // 测试专注度的数值是否是递增的
      test('values should be in ascending order', () {
        expect(FocusLevel.light.value < FocusLevel.medium.value, isTrue);
        expect(FocusLevel.medium.value < FocusLevel.deep.value, isTrue);
      });

      // 测试每个专注度的数值是否都是唯一的
      test('all focus levels should have unique values', () {
        final values = FocusLevel.values.map((f) => f.value).toSet();
        expect(values.length, equals(FocusLevel.values.length));
      });
    });

    // 任务类别扩展测试
    group('TaskCategory Extension Tests', () {
      // 测试任务类别的显示名称
      test('displayName should return correct values', () {
        expect(TaskCategory.creative.displayName, equals('Creative'));
        expect(TaskCategory.analytical.displayName, equals('Analytical'));
        expect(TaskCategory.routine.displayName, equals('Routine'));
        expect(TaskCategory.communication.displayName, equals('Communication'));
      });

      // 测试任务类别的图标
      test('icon should return correct emoji icons', () {
        expect(TaskCategory.creative.icon, equals('🎨'));
        expect(TaskCategory.analytical.icon, equals('📊'));
        expect(TaskCategory.routine.icon, equals('📝'));
        expect(TaskCategory.communication.icon, equals('👥'));
      });

      // 测试所有类别的显示名称是否都是唯一
      test('all categories should have unique display names', () {
        final names = TaskCategory.values.map((c) => c.displayName).toSet();
        expect(names.length, equals(TaskCategory.values.length));
      });

      // 测试所有类别的图标是否都是唯一的
      test('all categories should have unique icons', () {
        final icons = TaskCategory.values.map((c) => c.icon).toSet();
        expect(icons.length, equals(TaskCategory.values.length));
      });

      // 测试所有类别的索引值是否都是唯一的
      test('all categories should have unique index values', () {
        final indices = TaskCategory.values.map((c) => c.index).toSet();
        expect(indices.length, equals(TaskCategory.values.length));
      });
    });

    // 枚举一致性测试
    group('Enum Consistency Tests', () {
      // 验证优先级和能量等级有相同数量的级别
      test('Priority and EnergyLevel should have same number of levels', () {
        expect(Priority.values.length, equals(EnergyLevel.values.length));
      });

      // 验证所有枚举的"中等"级别是否都使用数值2
      test('Medium values should have consistent numeric value', () {
        expect(Priority.medium.value, equals(2));
        expect(EnergyLevel.medium.value, equals(2));
        expect(FocusLevel.medium.value, equals(2));
      });

      // 验证是否所有显示名称都以大写字母开头
      test('Display names should follow consistent capitalization', () {
        for (final priority in Priority.values) {
          expect(priority.displayName[0], equals(priority.displayName[0].toUpperCase()));
        }

        for (final energy in EnergyLevel.values) {
          expect(energy.displayName[0], equals(energy.displayName[0].toUpperCase()));
        }

        for (final focus in FocusLevel.values) {
          expect(focus.displayName[0], equals(focus.displayName[0].toUpperCase()));
        }

        for (final category in TaskCategory.values) {
          expect(category.displayName[0], equals(category.displayName[0].toUpperCase()));
        }
      });
    });

    // 枚举比较使用测试
    group('Enum Usage in Comparisons', () {
      // 测试使用value属性进行优先级比较
      test('Priority comparison using values', () {
        final highPriorityTask = Priority.high;
        final lowPriorityTask = Priority.low;

        expect(highPriorityTask.value > lowPriorityTask.value, isTrue);

        // 模拟按优先级排序任务的场景
        final priorities = [Priority.low, Priority.high, Priority.medium];
        priorities.sort((a, b) => b.value.compareTo(a.value)); // 降序排列

        expect(priorities[0], equals(Priority.high));
        expect(priorities[1], equals(Priority.medium));
        expect(priorities[2], equals(Priority.low));
      });

      test('EnergyLevel comparison using values', () {
        // 模拟匹配能量需求的场景,任务需要的能量高于用户当前能量
        final highEnergy = EnergyLevel.high;
        final lowEnergy = EnergyLevel.low;

        expect(highEnergy.value > lowEnergy.value, isTrue);

        // 模拟匹配的能源需求
        final taskEnergy = EnergyLevel.high;
        final userEnergy = EnergyLevel.medium;

        expect(taskEnergy.value > userEnergy.value, isTrue); // 任务需要更多能量
      });

      // 同上
      test('FocusLevel comparison using values', () {
        final deepFocus = FocusLevel.deep;
        final lightFocus = FocusLevel.light;

        expect(deepFocus.value > lightFocus.value, isTrue);
      });
    });

    // 枚举序列化测试
    group('Enum Serialization Tests', () {
      // 测试使用枚举的index属性存储到数据库,然后通过index恢复原始枚举值
      test('Enum index can be used for database storage', () {
        // 模拟存储到数据库
        final priorityIndex = Priority.high.index;
        final energyIndex = EnergyLevel.low.index;
        final focusIndex = FocusLevel.deep.index;
        final categoryIndex = TaskCategory.analytical.index;
        final statusIndex = TaskStatus.completed.index;

        // 模拟从数据库检索
        expect(Priority.values[priorityIndex], equals(Priority.high));
        expect(EnergyLevel.values[energyIndex], equals(EnergyLevel.low));
        expect(FocusLevel.values[focusIndex], equals(FocusLevel.deep));
        expect(TaskCategory.values[categoryIndex], equals(TaskCategory.analytical));
        expect(TaskStatus.values[statusIndex], equals(TaskStatus.completed));
      });

      // 测试所有枚举值的"往返"序列化
      test('All enums should handle round-trip serialization', () {
        // Priority
        for (final priority in Priority.values) {
          expect(Priority.values[priority.index], equals(priority));
        }

        // EnergyLevel
        for (final energy in EnergyLevel.values) {
          expect(EnergyLevel.values[energy.index], equals(energy));
        }

        // FocusLevel
        for (final focus in FocusLevel.values) {
          expect(FocusLevel.values[focus.index], equals(focus));
        }

        // TaskCategory
        for (final category in TaskCategory.values) {
          expect(TaskCategory.values[category.index], equals(category));
        }

        // TaskStatus
        for (final status in TaskStatus.values) {
          expect(TaskStatus.values[status.index], equals(status));
        }
      });
    });
  });
}