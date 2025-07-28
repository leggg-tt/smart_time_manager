import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/time_block_templates.dart';
import 'package:smart_time_manager/models/user_time_block.dart';
import 'package:smart_time_manager/models/enums.dart';

// 主测试函数
void main() {
  group('TimeBlockTemplates Tests', () {
    late List<UserTimeBlock> templates;

    // 在每个测试运行前执行,这里获取默认时间块模板列表
    setUp(() {
      templates = TimeBlockTemplates.defaultTemplates;
    });

    // 默认模板结构测试
    group('Default Templates Structure', () {
      // 测试默认应该有5个时间块模板
      test('should have exactly 5 default templates', () {
        expect(templates.length, equals(5));
      });

      // 测试每个默认模板是否都为isDefault
      test('all templates should be marked as default', () {
        // 遍历所有模板
        for (final template in templates) {
          // 确保每个都标记为默认模板
          expect(template.isDefault, isTrue);
        }
      });

      // 检验每个默认模板都是激活状态
      test('all templates should be active by default', () {
        // 遍历所有模板
        for (final template in templates) {
          // 模板都是激活状态
          expect(template.isActive, isTrue);
        }
      });

      // 验证每个默认模板都有独特的姓名
      test('all templates should have unique names', () {
        // 提取所有模板名称并转为Set
        final names = templates.map((t) => t.name).toSet();
        // 如果Set的长度等于模板数量
        expect(names.length, equals(templates.length));
      });

      // 验证每个默认模板都有独特的颜色
      test('all templates should have unique colors', () {
        final colors = templates.map((t) => t.color).toSet();
        expect(colors.length, equals(templates.length));
      });

      // 验证模板名称是否与预期的5个名称完全匹配
      test('expected template names should exist', () {
        final expectedNames = [
          'Morning Golden Hours',
          'Late Morning Work',
          'Post-Lunch Recovery',
          'Afternoon Focus Time',
          'Evening Flex Time',
        ];

        final actualNames = templates.map((t) => t.name).toList();
        expect(actualNames, equals(expectedNames));
      });
    });

    // 时间覆盖测试
    group('Template Time Coverage', () {
      // 验证每个时间块的具体开始和结束时间
      test('templates should cover main working hours', () {
        // 检查每一个设定时间块的具体时间
        expect(templates[0].startTime, equals('08:00'));
        expect(templates[0].endTime, equals('11:00'));

        expect(templates[1].startTime, equals('11:00'));
        expect(templates[1].endTime, equals('12:00'));

        expect(templates[2].startTime, equals('14:00'));
        expect(templates[2].endTime, equals('15:30'));

        expect(templates[3].startTime, equals('15:30'));
        expect(templates[3].endTime, equals('17:30'));

        expect(templates[4].startTime, equals('19:00'));
        expect(templates[4].endTime, equals('21:00'));
      });

      // 验证模板时间不能重叠
      test('templates should not overlap in time', () {
        // 按开始时间排序
        final sortedTemplates = List.from(templates)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        for (int i = 0; i < sortedTemplates.length - 1; i++) {
          final current = sortedTemplates[i];
          final next = sortedTemplates[i + 1];

          // 检查相邻时间块不重叠,当前块的结束时间应该≤下一块的开始时间
          expect(current.endTime.compareTo(next.startTime) <= 0, isTrue,
              reason: '${current.name} (${current.startTime}-${current.endTime}) '
                  'overlaps with ${next.name} (${next.startTime}-${next.endTime})');
        }
      });

      // 验证每一个默认时间块都包含周一到周五
      test('all templates should apply to weekdays', () {
        final weekdays = [1, 2, 3, 4, 5];

        for (final template in templates) {
          expect(template.daysOfWeek, equals(weekdays),
              reason: '${template.name} should apply to all weekdays');
        }
      });
    });

    // 能量和专注度测试
    group('Template Energy and Focus Levels', () {
      // 验证早晨黄金时间应该是高能量和深度专注
      test('Morning Golden Hours should have high energy and deep focus', () {
        final morningBlock = templates[0];
        expect(morningBlock.name, equals('Morning Golden Hours'));
        expect(morningBlock.energyLevel, equals(EnergyLevel.high));
        expect(morningBlock.focusLevel, equals(FocusLevel.deep));
      });

      // 验证午饭后恢复应保持低能量和低注意力
      test('Post-Lunch Recovery should have low energy and light focus', () {
        final postLunchBlock = templates[2];
        expect(postLunchBlock.name, equals('Post-Lunch Recovery'));
        expect(postLunchBlock.energyLevel, equals(EnergyLevel.low));
        expect(postLunchBlock.focusLevel, equals(FocusLevel.light));
      });

      // 验证能量水平符合人体生理节律
      test('energy levels should follow typical daily pattern', () {
        // Morning: high energy
        expect(templates[0].energyLevel, equals(EnergyLevel.high));
        // Late morning: medium energy
        expect(templates[1].energyLevel, equals(EnergyLevel.medium));
        // Post-lunch: low energy
        expect(templates[2].energyLevel, equals(EnergyLevel.low));
        // Afternoon: medium energy
        expect(templates[3].energyLevel, equals(EnergyLevel.medium));
        // Evening: medium energy
        expect(templates[4].energyLevel, equals(EnergyLevel.medium));
      });
    });

    // 任务适配性测试
    group('Template Task Suitability', () {
      // 验证早晨适合创造性和分析性任务
      test('Morning Golden Hours should suit creative and analytical tasks', () {
        final morningBlock = templates[0];
        expect(morningBlock.suitableCategories,
            contains(TaskCategory.creative));
        expect(morningBlock.suitableCategories,
            contains(TaskCategory.analytical));
        expect(morningBlock.suitablePriorities,
            contains(Priority.high));
        expect(morningBlock.suitableEnergyLevels,
            containsAll([EnergyLevel.high, EnergyLevel.medium]));
      });

      // 验证午饭后恢复应适合日常工作和沟通任务
      test('Post-Lunch Recovery should suit routine and communication tasks', () {
        final postLunchBlock = templates[2];
        expect(postLunchBlock.suitableCategories,
            containsAll([TaskCategory.routine, TaskCategory.communication]));
        expect(postLunchBlock.suitablePriorities,
            containsAll([Priority.low, Priority.medium]));
        expect(postLunchBlock.suitableEnergyLevels,
            contains(EnergyLevel.low));
      });

      // 验证所有模板都应至少有一个合适的类别
      test('all templates should have at least one suitable category', () {
        for (final template in templates) {
          expect(template.suitableCategories.isNotEmpty, isTrue,
              reason: '${template.name} should have at least one suitable category');
        }
      });

      // 验证所有模板都应至少有一个合适的优先级
      test('all templates should have at least one suitable priority', () {
        for (final template in templates) {
          expect(template.suitablePriorities.isNotEmpty, isTrue,
              reason: '${template.name} should have at least one suitable priority');
        }
      });

      // 验证所有模板都应至少有一个合适的能量级别
      test('all templates should have at least one suitable energy level', () {
        for (final template in templates) {
          expect(template.suitableEnergyLevels.isNotEmpty, isTrue,
              reason: '${template.name} should have at least one suitable energy level');
        }
      });
    });

    // 时间块描述测试
    group('Template Descriptions', () {
      // 检验所有模板时间块都有描述
      test('all templates should have descriptions', () {
        for (final template in templates) {
          expect(template.description, isNotNull);
          expect(template.description!.isNotEmpty, isTrue);
        }
      });

      // 描述需要有意义,没啥用说实话
      test('descriptions should be meaningful', () {
        expect(templates[0].description,
            contains('High energy period'));
        expect(templates[2].description,
            contains('Post-meal drowsiness'));
        expect(templates[3].description,
            contains('Energy recovery'));
      });
    });

    // 模板颜色测试
    group('Template Colors', () {
      // 验证十六进制颜色代码格式
      test('all templates should have valid hex color codes', () {
        // 正则表达式,验证颜色格式
        final hexColorPattern = RegExp(r'^#[0-9A-F]{6}$');

        for (final template in templates) {
          // 检查字符串是否匹配正则表达式
          expect(template.color, matches(hexColorPattern),
              reason: '${template.name} should have a valid hex color');
        }
      });

      // 验证具体颜色分配
      test('expected colors should be assigned', () {
        expect(templates[0].color, equals('#4CAF50')); // Green
        expect(templates[1].color, equals('#2196F3')); // Blue
        expect(templates[2].color, equals('#FF9800')); // Orange
        expect(templates[3].color, equals('#9C27B0')); // Purple
        expect(templates[4].color, equals('#607D8B')); // Blue Grey
      });
    });

    // 模板持续时间计算测试
    group('Template Duration Calculations', () {
      // 验证所有模板都是有效持续时间
      test('all templates should have valid durations', () {
        // 遍历所有模板
        for (final template in templates) {
          // 确保持续时间大于0
          expect(template.durationMinutes > 0, isTrue,
              reason: '${template.name} should have positive duration');
        }
      });

      // 验证具体的持续时间
      test('specific duration calculations', () {
        expect(templates[0].durationMinutes, equals(180)); // 3 hours
        expect(templates[1].durationMinutes, equals(60));  // 1 hour
        expect(templates[2].durationMinutes, equals(90));  // 1.5 hours
        expect(templates[3].durationMinutes, equals(120)); // 2 hours
        expect(templates[4].durationMinutes, equals(120)); // 2 hours
      });

      // 验证总工作时长的合理性
      test('total template duration should be reasonable', () {
        final totalMinutes = templates.fold(0,
                (sum, template) => sum + template.durationMinutes);
        final totalHours = totalMinutes / 60;

        // 验证总时长在8-12小时之间
        expect(totalHours >= 8 && totalHours <= 12, isTrue,
            reason: 'Total template duration should be 8-12 hours, but was $totalHours hours');
      });
    });

    // 模板一致性测试
    group('Template Consistency', () {
      // 验证能量等级的逻辑一致性
      test('suitable energy levels should include own energy level', () {
        for (final template in templates) {
          if (template.energyLevel == EnergyLevel.high) {
            // 高能量块应该接受高能量任务
            expect(template.suitableEnergyLevels.contains(EnergyLevel.high), isTrue,
                reason: '${template.name} with high energy should accept high energy tasks');
          }
          if (template.energyLevel == EnergyLevel.medium) {
            // 中等能量块应该接受中等能量任务
            expect(template.suitableEnergyLevels.contains(EnergyLevel.medium), isTrue,
                reason: '${template.name} with medium energy should accept medium energy tasks');
          }
          if (template.energyLevel == EnergyLevel.low) {
            // 低能量块应该接受低能量任务
            expect(template.suitableEnergyLevels.contains(EnergyLevel.low), isTrue,
                reason: '${template.name} with low energy should accept low energy tasks');
          }
        }
      });

      // 验证高能量时段不应只接受低能量任务
      test('high energy blocks should not only accept low energy tasks', () {
        // 过滤出高能量时间块
        final highEnergyBlocks = templates.where((t) => t.energyLevel == EnergyLevel.high);

        for (final block in highEnergyBlocks) {
          // 检查是否至少有一个元素满足条件
          final hasHighOrMedium = block.suitableEnergyLevels.any((level) =>
          level == EnergyLevel.high || level == EnergyLevel.medium);
          expect(hasHighOrMedium, isTrue,
              // 确保高能量时段不会浪费
              reason: '${block.name} with high energy should accept high or medium energy tasks');
        }
      });

      // 验证UUID的有效性
      test('all templates should have valid IDs', () {
        for (final template in templates) {
          expect(template.id, isNotEmpty);
          expect(template.id.length, equals(36));
        }
      });

      // 验证每个模板都有自己独特的ID
      test('all templates should have unique IDs', () {
        final ids = templates.map((t) => t.id).toSet();
        expect(ids.length, equals(templates.length));
      });
    });

    // 模板使用模式测试
    group('Template Usage Patterns', () {
      // 验证任务类别的全覆盖
      test('should cover different task categories throughout the day', () {
        final allCategories = <TaskCategory>{};

        for (final template in templates) {
          allCategories.addAll(template.suitableCategories);
        }

        // 确保所有任务种类都涵盖其中
        expect(allCategories, containsAll(TaskCategory.values),
            reason: 'Templates should collectively cover all task categories');
      });

      // 确保应全天支持所有优先级
      test('should support all priority levels throughout the day', () {
        final allPriorities = <Priority>{};

        for (final template in templates) {
          allPriorities.addAll(template.suitablePriorities);
        }

        // 应涵盖所有优先级别
        expect(allPriorities, containsAll(Priority.values),
            reason: 'Templates should collectively support all priority levels');
      });

      // 验证早晨的时间段应该支持高优先级的任务
      test('morning blocks should support high priority tasks', () {
        // 前两个区块（8-12）应支持高优先级
        expect(templates[0].suitablePriorities.contains(Priority.high), isTrue);

        // 午餐后不应该主要支持高优先级
        expect(templates[2].suitablePriorities.contains(Priority.high), isFalse);
      });

      // 应在精力充沛的时期支持创造性任务
      test('creative tasks should be supported in high energy periods', () {
        for (final template in templates) {
          if (template.suitableCategories.contains(TaskCategory.creative)) {
            // 创意块至少应具有中等能量
            expect(template.energyLevel == EnergyLevel.high ||
                template.energyLevel == EnergyLevel.medium, isTrue,
                reason: '${template.name} supports creative tasks so should have medium or high energy');
          }
        }
      });
    });

    // 模板序列化测试
    group('Template Serialization', () {
      test('all templates should serialize and deserialize correctly', () {
        for (final template in templates) {
          // 对象→Map
          final map = template.toMap();
          // Map→对象
          final restored = UserTimeBlock.fromMap(map);

          // 验证转换过程中所有属性都保持不变
          expect(restored.name, equals(template.name));
          expect(restored.startTime, equals(template.startTime));
          expect(restored.endTime, equals(template.endTime));
          expect(restored.daysOfWeek, equals(template.daysOfWeek));
          expect(restored.energyLevel, equals(template.energyLevel));
          expect(restored.focusLevel, equals(template.focusLevel));
          expect(restored.suitableCategories, equals(template.suitableCategories));
          expect(restored.suitablePriorities, equals(template.suitablePriorities));
          expect(restored.suitableEnergyLevels, equals(template.suitableEnergyLevels));
          expect(restored.description, equals(template.description));
          expect(restored.color, equals(template.color));
          expect(restored.isActive, equals(template.isActive));
          expect(restored.isDefault, equals(template.isDefault));
        }
      });
    });

    // 业务逻辑验证
    group('Business Logic Validation', () {
      // 验证午餐时间
      test('lunch break should exist between morning and afternoon blocks', () {
        // 上午晚些时候的工作于12:00结束
        expect(templates[1].endTime, equals('12:00'));
        // 午餐后恢复时间从14:00开始
        expect(templates[2].startTime, equals('14:00'));

        // 2小时午休时间
        final lunchBreakHours = 2;
        expect(lunchBreakHours, equals(2));
      });

      // 验证晚间时间块的灵活性
      test('evening block should be more flexible', () {
        final eveningBlock = templates[4];
        expect(eveningBlock.name, equals('Evening Flex Time'));

        // 应该支持创造性任务和常规任务
        expect(eveningBlock.suitableCategories,
            containsAll([TaskCategory.creative, TaskCategory.routine]));

        // 不需要深度聚焦
        expect(eveningBlock.focusLevel, equals(FocusLevel.light));
      });

      // 工作日应该有均衡的能量分配
      test('work day should have balanced energy distribution', () {
        final energyLevels = templates.map((t) => t.energyLevel).toList();

        // 应该至少有一个高能量期
        expect(energyLevels.contains(EnergyLevel.high), isTrue);

        // 应该至少有一个低能量期
        expect(energyLevels.contains(EnergyLevel.low), isTrue);

        // 应该有多个中等能量周期
        final mediumCount = energyLevels.where((e) => e == EnergyLevel.medium).length;
        expect(mediumCount >= 2, isTrue);
      });
    });
  });
}