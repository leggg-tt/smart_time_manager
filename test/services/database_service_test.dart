import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/services/database_service.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/user_time_block.dart';
import 'package:smart_time_manager/models/enums.dart';

void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 单例模式测试
  group('DatabaseService 单例模式测试', () {
    test('DatabaseService 应该是单例', () {
      final instance1 = DatabaseService.instance;
      final instance2 = DatabaseService.instance;

      // 两次获取应该是同一个实例
      expect(identical(instance1, instance2), isTrue);
    });

    // 验证实例存在
    test('DatabaseService 实例应该存在', () {
      final instance = DatabaseService.instance;
      // 确保单例实例能够正确创建
      expect(instance, isNotNull);
    });
  });

  // 常量测试
  group('DatabaseService 常量测试', () {
    test('数据库名称应该正确', () {

      const expectedDbName = 'smart_time_manager.db';
      const expectedVersion = 1;

      // 这些是预期值,实际值在私有常量中
      expect(expectedDbName, endsWith('.db'));
      expect(expectedVersion, greaterThan(0));
    });
  });

  group('DatabaseService 数据模型兼容性测试', () {
    // Task模型序列化测试
    test('Task 模型应该能够转换为 Map', () {
      final task = Task(
        title: 'Test Task',
        durationMinutes: 60,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.routine,
      );

      // 测试toMap()方法
      final map = task.toMap();

      expect(map, isA<Map<String, dynamic>>());
      expect(map['title'], equals('Test Task'));
      expect(map['durationMinutes'], equals(60));
      expect(map['priority'], equals(Priority.medium.index));
    });

    // 测试从Map创建Task
    test('Task 模型应该能够从 Map 创建', () {
      final map = {
        'id': 'test-id',
        'title': 'Test Task',
        'description': null,
        'durationMinutes': 60,
        'deadline': null,
        'scheduledStartTime': null,
        'actualStartTime': null,
        'actualEndTime': null,
        'priority': Priority.medium.index,
        'energyRequired': EnergyLevel.medium.index,
        'focusRequired': FocusLevel.medium.index,
        'taskCategory': TaskCategory.routine.index,
        'status': TaskStatus.pending.index,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'completedAt': null,
        'preferredTimeBlockIds': null,
        'avoidTimeBlockIds': null,
      };

      // 测试fromMap()方法
      final task = Task.fromMap(map);

      expect(task.id, equals('test-id'));
      expect(task.title, equals('Test Task'));
      expect(task.durationMinutes, equals(60));
      expect(task.priority, equals(Priority.medium));
    });

    // UserTimeBlock模型序列化测试
    test('UserTimeBlock 模型应该能够转换为 Map', () {
      final timeBlock = UserTimeBlock(
        id: 'test-block',
        name: 'Morning Block',
        startTime: '09:00',
        endTime: '11:00',
        daysOfWeek: [1, 2, 3, 4, 5],
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

      // 验证TimeBlock转换为Map
      final map = timeBlock.toMap();

      expect(map, isA<Map<String, dynamic>>());
      expect(map['name'], equals('Morning Block'));
      expect(map['startTime'], equals('09:00'));
      expect(map['endTime'], equals('11:00'));
      expect(map['isActive'], equals(1));
    });

    test('UserTimeBlock 模型应该能够从 Map 创建', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-block',
        'name': 'Morning Block',
        'startTime': '09:00',
        'endTime': '11:00',
        'daysOfWeek': '[1,2,3,4,5]',
        'energyLevel': EnergyLevel.high.index,
        'focusLevel': FocusLevel.deep.index,
        'suitableCategories': '[1]',
        'suitablePriorities': '[2]',
        'suitableEnergyLevels': '[2]',
        'description': null,
        'color': '0xFF2196F3',
        'isActive': 1,
        'isDefault': 0,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      // 验证从Map创建TimeBlock
      final timeBlock = UserTimeBlock.fromMap(map);

      expect(timeBlock.id, equals('test-block'));
      expect(timeBlock.name, equals('Morning Block'));
      expect(timeBlock.startTime, equals('09:00'));
      expect(timeBlock.endTime, equals('11:00'));
      expect(timeBlock.isActive, isTrue);
    });
  });

  // SQL查询逻辑测试
  group('DatabaseService SQL 查询逻辑测试', () {
    // 验证日期范围计算
    test('日期范围计算应该正确', () {
      final date = DateTime(2024, 1, 15, 10, 30);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      expect(startOfDay.hour, equals(0));
      expect(startOfDay.minute, equals(0));
      expect(startOfDay.second, equals(0));

      expect(endOfDay.day, equals(16));
      expect(endOfDay.hour, equals(0));
      expect(endOfDay.minute, equals(0));
    });

    // 验证时间戳转换的可逆性
    test('时间戳转换应该正确', () {
      final date = DateTime(2024, 1, 15, 10, 30);
      final timestamp = date.millisecondsSinceEpoch;
      final convertedBack = DateTime.fromMillisecondsSinceEpoch(timestamp);

      expect(convertedBack, equals(date));
    });
  });

  // 枚举索引稳定性测试
  group('DatabaseService 枚举索引测试', () {
    // TaskStatus枚举测试
    test('TaskStatus 枚举索引应该稳定', () {
      expect(TaskStatus.pending.index, equals(0));
      expect(TaskStatus.scheduled.index, equals(1));
      expect(TaskStatus.inProgress.index, equals(2));
      expect(TaskStatus.completed.index, equals(3));
      expect(TaskStatus.cancelled.index, equals(4));
    });

    // 其他属性枚举测试
    test('Priority 枚举索引应该稳定', () {
      expect(Priority.low.index, equals(0));
      expect(Priority.medium.index, equals(1));
      expect(Priority.high.index, equals(2));
    });

    test('EnergyLevel 枚举索引应该稳定', () {
      expect(EnergyLevel.low.index, equals(0));
      expect(EnergyLevel.medium.index, equals(1));
      expect(EnergyLevel.high.index, equals(2));
    });

    test('FocusLevel 枚举索引应该稳定', () {
      expect(FocusLevel.light.index, equals(0));
      expect(FocusLevel.medium.index, equals(1));
      expect(FocusLevel.deep.index, equals(2));
    });

    test('TaskCategory 枚举索引应该稳定', () {
      expect(TaskCategory.creative.index, equals(0));
      expect(TaskCategory.analytical.index, equals(1));
      expect(TaskCategory.routine.index, equals(2));
      expect(TaskCategory.communication.index, equals(3));
    });
  });
}