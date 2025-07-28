import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/user_time_block.dart';
import 'package:smart_time_manager/models/enums.dart';
import 'dart:convert';

// 主测试组结构
void main() {
  group('UserTimeBlock Model Tests', () {
    group('Constructor Tests', () {
      // 验证是否自动生成UUID
      test('should create time block with auto-generated UUID when id is null', () {
        final timeBlock = UserTimeBlock(
          name: 'Morning Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1, 2, 3, 4, 5],  // 周一到周五
          energyLevel: EnergyLevel.high,
          focusLevel: FocusLevel.deep,
          suitableCategories: [TaskCategory.creative],
          suitablePriorities: [Priority.high],
          suitableEnergyLevels: [EnergyLevel.high],
        );

        // 验证ID不为空
        expect(timeBlock.id, isNotEmpty);
        // 验证标准长度
        expect(timeBlock.id.length, equals(36));
      });

      // 验证默认值设置
      test('should set default values correctly', () {
        final timeBlock = UserTimeBlock(
          // 设定必须参数
          name: 'Test Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );

        // 验证默认是否为蓝色
        expect(timeBlock.color, equals('#2196F3'));
        // 验证是否默认启用
        expect(timeBlock.isActive, isTrue);
        // 验证是否为非系统预设
        expect(timeBlock.isDefault, isFalse);
        // 验证描述是否可为空
        expect(timeBlock.description, isNull);
      });

      // 验证设置的时间是否为当前时间
      test('should set timestamps to current time by default', () {
        final beforeCreation = DateTime.now();
        final timeBlock = UserTimeBlock(
          name: 'Test Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
        final afterCreation = DateTime.now();

        // 验证创建时间在合理范围内
        expect(timeBlock.createdAt.isAfter(beforeCreation) ||
            timeBlock.createdAt.isAtSameMomentAs(beforeCreation), isTrue);
        expect(timeBlock.createdAt.isBefore(afterCreation) ||
            timeBlock.createdAt.isAtSameMomentAs(afterCreation), isTrue);
        // 确保创建和更新时间戳被正确初始化为当前时间
        expect(timeBlock.updatedAt, equals(timeBlock.createdAt));
      });
    });

    //  toMap()方法测试
    group('toMap() Tests', () {
      // 测试字段转换
      test('should convert all fields correctly', () {
        final now = DateTime.now();
        final timeBlock = UserTimeBlock(
          id: 'test-id',
          name: 'Morning Focus',
          startTime: '08:00',
          endTime: '10:30',
          daysOfWeek: [1, 2, 3, 4, 5],
          energyLevel: EnergyLevel.high,
          focusLevel: FocusLevel.deep,
          suitableCategories: [TaskCategory.creative, TaskCategory.analytical],
          suitablePriorities: [Priority.high, Priority.medium],
          suitableEnergyLevels: [EnergyLevel.high, EnergyLevel.medium],
          description: 'Best time for deep work',
          color: '#4CAF50',
          isActive: true,
          isDefault: false,
          createdAt: now,
          updatedAt: now,
        );

        final map = timeBlock.toMap();

        // 验证每个字段都正确转换
        expect(map['id'], equals('test-id'));
        expect(map['name'], equals('Morning Focus'));
        expect(map['startTime'], equals('08:00'));
        expect(map['endTime'], equals('10:30'));
        expect(map['daysOfWeek'], equals('[1,2,3,4,5]'));
        // 枚举转索引
        expect(map['energyLevel'], equals(EnergyLevel.high.index));
        expect(map['focusLevel'], equals(FocusLevel.deep.index));
        expect(map['description'], equals('Best time for deep work'));
        expect(map['color'], equals('#4CAF50'));
        // 布尔转整数
        expect(map['isActive'], equals(1));
        expect(map['isDefault'], equals(0));
        // 时间转时间戳
        expect(map['createdAt'], equals(now.millisecondsSinceEpoch));
        expect(map['updatedAt'], equals(now.millisecondsSinceEpoch));
      });

      // 验证列表是否可以正常转JSON字符串
      test('should convert lists to JSON strings correctly', () {
        final timeBlock = UserTimeBlock(
          name: 'Test Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1, 3, 5],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine, TaskCategory.communication],
          suitablePriorities: [Priority.low, Priority.medium, Priority.high],
          suitableEnergyLevels: [EnergyLevel.low],
        );

        final map = timeBlock.toMap();

        // 验证列表被正确序列化为JSON字符串
        expect(jsonDecode(map['daysOfWeek']), equals([1, 3, 5]));
        expect(jsonDecode(map['suitableCategories']),
            equals([TaskCategory.routine.index, TaskCategory.communication.index]));
        expect(jsonDecode(map['suitablePriorities']),
            equals([Priority.low.index, Priority.medium.index, Priority.high.index]));
        expect(jsonDecode(map['suitableEnergyLevels']),
            equals([EnergyLevel.low.index]));
      });

      // 验证布尔值是否正确转换
      test('should handle boolean conversions', () {
        // 创建isActive=true,isDefault=true的对象
        final activeBlock = UserTimeBlock(
          name: 'Active Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
          isActive: true,
          isDefault: true,
        );

        // 创建isActive=false,isDefault=false的对象(模型未定义CopyWith方法)
        final inactiveBlock = UserTimeBlock(
          name: 'Active Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
          isActive: false,
          isDefault: false,
        );

        // 验证布尔值转换为0/1
        expect(activeBlock.toMap()['isActive'], equals(1));
        expect(activeBlock.toMap()['isDefault'], equals(1));
        expect(inactiveBlock.toMap()['isActive'], equals(0));
        expect(inactiveBlock.toMap()['isDefault'], equals(0));
      });
    });

    // 测试fromMap()方法
    group('fromMap() Tests', () {
      // 测试是否可以正常从Map恢复对象
      test('should restore all fields correctly from map', () {
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'name': 'Afternoon Block',
          'startTime': '14:00',
          'endTime': '16:30',
          // JSON字符串
          'daysOfWeek': '[1,2,3,4,5]',
          // 索引值
          'energyLevel': EnergyLevel.medium.index,
          'focusLevel': FocusLevel.medium.index,
          'suitableCategories': '[${TaskCategory.analytical.index},${TaskCategory.communication.index}]',
          'suitablePriorities': '[${Priority.medium.index},${Priority.high.index}]',
          'suitableEnergyLevels': '[${EnergyLevel.medium.index},${EnergyLevel.high.index}]',
          'description': 'Post-lunch productive time',
          'color': '#9C27B0',
          // 整数表示布尔
          'isActive': 1,
          'isDefault': 0,
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
        };

        final timeBlock = UserTimeBlock.fromMap(map);

        // 验证恢复的对象字段正确
        expect(timeBlock.id, equals('test-id'));
        expect(timeBlock.name, equals('Afternoon Block'));
        expect(timeBlock.startTime, equals('14:00'));
        expect(timeBlock.endTime, equals('16:30'));
        // JSON转列表
        expect(timeBlock.daysOfWeek, equals([1, 2, 3, 4, 5]));
        // 索引转枚举
        expect(timeBlock.energyLevel, equals(EnergyLevel.medium));
        expect(timeBlock.focusLevel, equals(FocusLevel.medium));
        expect(timeBlock.suitableCategories,
            equals([TaskCategory.analytical, TaskCategory.communication]));
        expect(timeBlock.suitablePriorities,
            equals([Priority.medium, Priority.high]));
        expect(timeBlock.suitableEnergyLevels,
            equals([EnergyLevel.medium, EnergyLevel.high]));
        expect(timeBlock.description, equals('Post-lunch productive time'));
        expect(timeBlock.color, equals('#9C27B0'));
        // 整数转布尔
        expect(timeBlock.isActive, isTrue);
        expect(timeBlock.isDefault, isFalse);
      });

      // 验证是否可以正确处理null值
      test('should handle null description', () {
        final map = {
          'id': 'test-id',
          'name': 'Test Block',
          'startTime': '09:00',
          'endTime': '11:00',
          'daysOfWeek': '[1]',
          'energyLevel': EnergyLevel.medium.index,
          'focusLevel': FocusLevel.medium.index,
          'suitableCategories': '[${TaskCategory.routine.index}]',
          'suitablePriorities': '[${Priority.medium.index}]',
          'suitableEnergyLevels': '[${EnergyLevel.medium.index}]',
          'description': null,
          'color': '#2196F3',
          'isActive': 1,
          'isDefault': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        final timeBlock = UserTimeBlock.fromMap(map);
        // 验证描述字段是否为空
        expect(timeBlock.description, isNull);
      });

      // 验证序列化的可逆性
      test('toMap and fromMap should be reversible', () {
        final originalBlock = UserTimeBlock(
          name: 'Morning Routine',
          startTime: '07:00',
          endTime: '09:00',
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          energyLevel: EnergyLevel.low,
          focusLevel: FocusLevel.light,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.low, Priority.medium],
          suitableEnergyLevels: [EnergyLevel.low, EnergyLevel.medium],
          description: 'Morning routine tasks',
          color: '#FF9800',
          isActive: true,
          isDefault: false,
        );

        // 对象转map
        final map = originalBlock.toMap();
        // map转对象
        final restoredBlock = UserTimeBlock.fromMap(map);
        // 对象转map
        final finalMap = restoredBlock.toMap();

        // 验证转换是否可逆
        expect(finalMap['id'], equals(map['id']));
        expect(finalMap['name'], equals(map['name']));
        expect(finalMap['startTime'], equals(map['startTime']));
        expect(finalMap['endTime'], equals(map['endTime']));
        expect(finalMap['daysOfWeek'], equals(map['daysOfWeek']));
        expect(finalMap['color'], equals(map['color']));
      });
    });

    // containsTime()方法测试
    group('containsTime() Tests', () {
      late UserTimeBlock timeBlock;

      // 在每个测试前运行,创建一个标准的时间块用于测试
      setUp(() {
        timeBlock = UserTimeBlock(
          name: 'Work Hours',
          startTime: '09:00',
          endTime: '17:00',
          daysOfWeek: [1, 2, 3, 4, 5],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
      });

      // 测试有效时间范围内判断功能
      test('should return true for time within block on valid day', () {
        // 周一 10:30
        final testTime = DateTime(2024, 12, 23, 10, 30);
        // 验证是否为周一
        expect(testTime.weekday, equals(1));
        expect(timeBlock.containsTime(testTime), isTrue);
      });

      // 验证时间范围外
      test('should return false for time outside block on valid day', () {
        // 周一 8:00（开始前）
        final beforeTime = DateTime(2024, 12, 23, 8, 0);
        // 测试在时间范围外是否返回false
        expect(timeBlock.containsTime(beforeTime), isFalse);

        // 周一 18:00（结束后）
        final afterTime = DateTime(2024, 12, 23, 18, 0);
        // 测试在时间范围外是否返回false
        expect(timeBlock.containsTime(afterTime), isFalse);
      });

      // 测试无效日期
      test('should return false for time on invalid day', () {
        // 周六 10:00
        final saturdayTime = DateTime(2024, 12, 28, 10, 0);
        // 验证是否为周6
        expect(saturdayTime.weekday, equals(6));
        // 测试在未包含的星期数是否返回false
        expect(timeBlock.containsTime(saturdayTime), isFalse);

        // 周日 10:00
        final sundayTime = DateTime(2024, 12, 29, 10, 0);
        // 验证是否为周日
        expect(sundayTime.weekday, equals(7));
        // 测试在未包含的星期数是否返回false
        expect(timeBlock.containsTime(sundayTime), isFalse);
      });

      // 边界条件测试
      test('should handle boundary times correctly', () {
        // 正好在开始时间
        final startTime = DateTime(2024, 12, 23, 9, 0);
        expect(timeBlock.containsTime(startTime), isTrue);

        // 结束时间前一分钟
        final beforeEndTime = DateTime(2024, 12, 23, 16, 59);
        expect(timeBlock.containsTime(beforeEndTime), isTrue);

        // 正好在结束时间（不包含）
        final endTime = DateTime(2024, 12, 23, 17, 0);
        expect(timeBlock.containsTime(endTime), isFalse);
      });

      test('should handle time with seconds correctly', () {
        // 09:00:30是否仍在区块内
        final timeWithSeconds = DateTime(2024, 12, 23, 9, 0, 30);
        expect(timeBlock.containsTime(timeWithSeconds), isTrue);

        // 16:59:59是否仍在区块内
        final lateTimeWithSeconds = DateTime(2024, 12, 23, 16, 59, 59);
        expect(timeBlock.containsTime(lateTimeWithSeconds), isTrue);
      });

      // 验证containsTime方法能否正确处理单位数的小时和分钟
      test('should handle single-digit hours and minutes', () {
        final earlyBlock = UserTimeBlock(
          name: 'Early Block',
          startTime: '06:05',
          endTime: '09:30',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );

        // 测试用例
        // 6:05 AM,正好是时间块的开始时间
        final earlyTime = DateTime(2024, 12, 23, 6, 5);
        expect(earlyBlock.containsTime(earlyTime), isTrue);

        // 7:15 AM,
        final midTime = DateTime(2024, 12, 23, 7, 15);
        expect(earlyBlock.containsTime(midTime), isTrue);
      });
    });

    //  durationMinutes测试
    group('durationMinutes Tests', () {
      // 测试持续时间的计算是否正确
      test('should calculate duration correctly for same-day blocks', () {
        // 用例1
        final block1 = UserTimeBlock(
          name: 'Two Hour Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
        // 验证计算是否正确
        expect(block1.durationMinutes, equals(120));

        // 用例2
        final block2 = UserTimeBlock(
          name: 'Half Hour Block',
          startTime: '14:30',
          endTime: '15:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
        // 验证计算是否正确
        expect(block2.durationMinutes, equals(30));

        // 用例3
        final block3 = UserTimeBlock(
          name: 'Full Day Block',
          startTime: '00:00',
          endTime: '23:59',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
        // 验证计算是否正确
        expect(block3.durationMinutes, equals(1439));
      });

      // 同上,只不过测的是分钟
      test('should handle blocks with minutes correctly', () {
        final block = UserTimeBlock(
          name: 'Odd Time Block',
          startTime: '09:15',
          endTime: '11:45',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );
        expect(block.durationMinutes, equals(150));
      });
    });

    // TimeOfDay辅助类测试
    group('TimeOfDay Helper Class Tests', () {
      // 测试时间格式化,确保单位数字被正确补零
      test('should format time correctly', () {
        final time1 = TimeOfDay(hour: 9, minute: 5);
        expect(time1.toString(), equals('09:05'));

        final time2 = TimeOfDay(hour: 14, minute: 30);
        expect(time2.toString(), equals('14:30'));

        final time3 = TimeOfDay(hour: 0, minute: 0);
        expect(time3.toString(), equals('00:00'));

        final time4 = TimeOfDay(hour: 23, minute: 59);
        expect(time4.toString(), equals('23:59'));
      });
    });

    // 边缘案例测试
    group('Edge Cases and Validation', () {
      // 测试空列表的处理
      test('should handle empty lists', () {
        final timeBlock = UserTimeBlock(
          name: 'Empty Lists Block',
          startTime: '09:00',
          endTime: '11:00',
          daysOfWeek: [],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [],
          suitablePriorities: [],
          suitableEnergyLevels: [],
        );

        // 验证列表确实为空
        expect(timeBlock.daysOfWeek, isEmpty);
        expect(timeBlock.suitableCategories, isEmpty);

        // 因为daysOfWeek为空,任何日期都不应该匹配
        final monday = DateTime(2024, 12, 23, 10, 0);
        expect(timeBlock.containsTime(monday), isFalse);
      });

      // 全周测试
      test('should handle all weekdays', () {
        final timeBlock = UserTimeBlock(
          name: 'Every Day Block',
          startTime: '09:00',
          endTime: '17:00',
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          energyLevel: EnergyLevel.medium,
          focusLevel: FocusLevel.medium,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.medium],
          suitableEnergyLevels: [EnergyLevel.medium],
        );

        // 测试从12月23日到29日（刚好是一周）
        for (int day = 23; day <= 29; day++) {
          final testDate = DateTime(2024, 12, day, 10, 0);
          expect(timeBlock.containsTime(testDate), isTrue);
        }
      });

      // 逻辑问题,看情况修改
      test('should handle midnight crossing (if implemented)', () {
        final overnightBlock = UserTimeBlock(
          name: 'Night Shift',
          startTime: '22:00',
          endTime: '06:00',
          daysOfWeek: [1],
          energyLevel: EnergyLevel.low,
          focusLevel: FocusLevel.light,
          suitableCategories: [TaskCategory.routine],
          suitablePriorities: [Priority.low],
          suitableEnergyLevels: [EnergyLevel.low],
        );

        expect(overnightBlock.durationMinutes, isNegative);

      });
    });
  });
}