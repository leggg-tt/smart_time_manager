import 'package:flutter_test/flutter_test.dart';
import 'package:smart_time_manager/models/task.dart';
import 'package:smart_time_manager/models/enums.dart';

// 主测试结构
// main()是测试的入口函数
// group()用于组织相关测试,第一个参数是组名
void main() {
  group('Task Model Tests', () {
    // 构造函数测试组,创建一个子组,专门测试构造函数行为
    group('Constructor Tests', () {
      // 测试1:自动生成UUID
      // test()定义单个测试用例
      test('should create task with auto-generated UUID when id is null', () {
        // 创建任务时不提供id
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        // expect()是断言函数,验证期望结果
        expect(task.id, isNotEmpty);  // 检查字符串非空
        expect(task.id.length, equals(36)); // 验证UUID标准长度
      });

      // 测试2:使用提供的ID
      test('should use provided id when specified', () {
        // 当提供自定义id时,应该使用自定义id
        const providedId = 'custom-id-12345';
        final task = Task(
          id: providedId,
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.id, equals(providedId));  // 验证任务id和自定义id一致
      });

      // 测试3:测试任务默认状态
      test('should set default status to pending', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.status, equals(TaskStatus.pending)); // 验证刚创建的任务是不是pending状态
      });

      // 测试4：时间戳设置
      test('should set createdAt and updatedAt to current time by default', () {
        // 记录创建前时间
        final beforeCreation = DateTime.now();
        // 创建任务
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );
        // 记录创建后时间
        final afterCreation = DateTime.now();

        // 验证createdAt是否在合理范围内
        expect(task.createdAt.isAfter(beforeCreation) ||
            task.createdAt.isAtSameMomentAs(beforeCreation), isTrue);
        expect(task.createdAt.isBefore(afterCreation) ||
            task.createdAt.isAtSameMomentAs(afterCreation), isTrue);
        // 验证updatedAt是否等于createdAt
        expect(task.updatedAt, equals(task.createdAt));
      });
    });

    // 序列化测试
    group('toMap() Tests', () {
      // 测试所有必需字段的正确转换
      test('should convert all required fields correctly', () {
        final now = DateTime.now();
        final task = Task(
          id: 'test-id',
          title: 'Test Task',
          durationMinutes: 90,
          priority: Priority.high,
          energyRequired: EnergyLevel.high,
          focusRequired: FocusLevel.deep,
          taskCategory: TaskCategory.creative,
          status: TaskStatus.scheduled,
          createdAt: now,
          updatedAt: now,
        );

        final map = task.toMap();

        // 测试所有必需字段的正确转换
        expect(map['id'], equals('test-id'));
        expect(map['title'], equals('Test Task'));
        expect(map['durationMinutes'], equals(90));
        // 枚举值正确转换为索引
        expect(map['priority'], equals(Priority.high.index));
        expect(map['energyRequired'], equals(EnergyLevel.high.index));
        expect(map['focusRequired'], equals(FocusLevel.deep.index));
        expect(map['taskCategory'], equals(TaskCategory.creative.index));
        expect(map['status'], equals(TaskStatus.scheduled.index));
        // DateTime转换为毫秒时间戳
        expect(map['createdAt'], equals(now.millisecondsSinceEpoch));
        expect(map['updatedAt'], equals(now.millisecondsSinceEpoch));
      });

      // 测试可选字段为null时的处理
      test('should handle optional fields when null', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        final map = task.toMap();

        expect(map['description'], isNull);
        expect(map['deadline'], isNull);
        expect(map['scheduledStartTime'], isNull);
        expect(map['actualStartTime'], isNull);
        expect(map['actualEndTime'], isNull);
        expect(map['completedAt'], isNull);
        expect(map['preferredTimeBlockIds'], isNull);
        expect(map['avoidTimeBlockIds'], isNull);
      });

      // 测试日期部分是否可以正确转换成毫秒时间戳
      test('should convert DateTime fields to milliseconds', () {
        final deadline = DateTime(2024, 12, 31, 23, 59);
        final scheduledTime = DateTime(2024, 12, 25, 14, 30);

        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          deadline: deadline,
          scheduledStartTime: scheduledTime,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        final map = task.toMap();

        // 验证日期部分是否可以正确转换成毫秒时间戳
        expect(map['deadline'], equals(deadline.millisecondsSinceEpoch));
        expect(map['scheduledStartTime'], equals(scheduledTime.millisecondsSinceEpoch));
      });

      //  测试列表到JSON字符串的转换
      test('should convert lists to JSON strings', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
          preferredTimeBlockIds: ['block1', 'block2'],
          avoidTimeBlockIds: ['block3'],
        );

        final map = task.toMap();

        expect(map['preferredTimeBlockIds'], equals('["block1","block2"]'));
        expect(map['avoidTimeBlockIds'], equals('["block3"]'));
      });
    });

    group('fromMap() Tests', () {
      // 反序列化测试
      test('should restore all fields correctly from map', () {
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'description': 'Test Description',
          'durationMinutes': 120,
          'deadline': now.millisecondsSinceEpoch,
          'scheduledStartTime': now.millisecondsSinceEpoch,
          'actualStartTime': now.millisecondsSinceEpoch,
          'actualEndTime': now.add(Duration(hours: 2)).millisecondsSinceEpoch,
          'priority': Priority.high.index,
          'energyRequired': EnergyLevel.low.index,
          'focusRequired': FocusLevel.light.index,
          'taskCategory': TaskCategory.communication.index,
          'status': TaskStatus.completed.index,
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'completedAt': now.millisecondsSinceEpoch,
          'preferredTimeBlockIds': '["block1","block2"]',
          'avoidTimeBlockIds': '["block3"]',
        };

        final task = Task.fromMap(map);

        // 测试从Map恢复所有字段
        expect(task.id, equals('test-id'));
        expect(task.title, equals('Test Task'));
        expect(task.description, equals('Test Description'));
        expect(task.durationMinutes, equals(120));
        expect(task.deadline?.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        // 枚举值从索引正确恢复
        expect(task.priority, equals(Priority.high));
        expect(task.energyRequired, equals(EnergyLevel.low));
        expect(task.focusRequired, equals(FocusLevel.light));
        expect(task.taskCategory, equals(TaskCategory.communication));
        expect(task.status, equals(TaskStatus.completed));
        // JSON字符串正确解析为列表
        expect(task.preferredTimeBlockIds, equals(['block1', 'block2']));
        expect(task.avoidTimeBlockIds, equals(['block3']));
      });

      // 测试是否可以处理null区域
      test('should handle null optional fields', () {
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

        final task = Task.fromMap(map);

        expect(task.description, isNull);
        expect(task.deadline, isNull);
        expect(task.scheduledStartTime, isNull);
        expect(task.completedAt, isNull);
        expect(task.preferredTimeBlockIds, isNull);
        expect(task.avoidTimeBlockIds, isNull);
      });

      // 测试序列化和反序列化的可逆性
      test('toMap and fromMap should be reversible', () {
        // 创建任务
        final originalTask = Task(
          title: 'Test Task',
          description: 'Test Description',
          durationMinutes: 90,
          deadline: DateTime(2024, 12, 31),
          scheduledStartTime: DateTime(2024, 12, 25, 14, 0),
          priority: Priority.high,
          energyRequired: EnergyLevel.high,
          focusRequired: FocusLevel.deep,
          taskCategory: TaskCategory.analytical,
          status: TaskStatus.scheduled,
          preferredTimeBlockIds: ['morning', 'afternoon'],
          avoidTimeBlockIds: ['evening'],
        );

        final map = originalTask.toMap();
        final restoredTask = Task.fromMap(map);
        final finalMap = restoredTask.toMap();

        // 比较必要字段（不包括自动生成的时间戳）
        expect(finalMap['id'], equals(map['id']));
        expect(finalMap['title'], equals(map['title']));
        expect(finalMap['description'], equals(map['description']));
        expect(finalMap['durationMinutes'], equals(map['durationMinutes']));
        expect(finalMap['priority'], equals(map['priority']));
        expect(finalMap['preferredTimeBlockIds'], equals(map['preferredTimeBlockIds']));
      });
    });

    // 测试copyWith()
    group('copyWith() Tests', () {
      test('should only update specified fields', () {
        final originalTask = Task(
          id: 'original-id',
          title: 'Original Title',
          description: 'Original Description',
          durationMinutes: 60,
          priority: Priority.low,
          energyRequired: EnergyLevel.low,
          focusRequired: FocusLevel.light,
          taskCategory: TaskCategory.routine,
          status: TaskStatus.pending,
        );

        // 修改title,优先级,任务状态
        final updatedTask = originalTask.copyWith(
          title: 'Updated Title',
          priority: Priority.high,
          status: TaskStatus.scheduled,
        );

        // 验证改变的部分是否正确改变
        expect(updatedTask.title, equals('Updated Title'));
        expect(updatedTask.priority, equals(Priority.high));
        expect(updatedTask.status, equals(TaskStatus.scheduled));

        // 验证未改变的地方是否没变化
        expect(updatedTask.id, equals(originalTask.id));
        expect(updatedTask.description, equals(originalTask.description));
        expect(updatedTask.durationMinutes, equals(originalTask.durationMinutes));
        expect(updatedTask.energyRequired, equals(originalTask.energyRequired));
        expect(updatedTask.focusRequired, equals(originalTask.focusRequired));
        expect(updatedTask.taskCategory, equals(originalTask.taskCategory));
      });

      // 验证更新的时候updatedAt是否正常工作
      test('should update updatedAt timestamp when copying', () {
        final originalTask = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        // 较小的延迟以确保不同的时间戳
        Future.delayed(Duration(milliseconds: 10));

        // 更新任务标题
        final updatedTask = originalTask.copyWith(title: 'Updated');

        // 验证更新时间是否在原更新时间之后
        expect(updatedTask.updatedAt.isAfter(originalTask.updatedAt), isTrue);
        // 验证创建时间是否保持一致
        expect(updatedTask.createdAt, equals(originalTask.createdAt));
      });
    });

    // 计算属性测试组
    group('Computed Properties Tests', () {
      // 计算结束时间
      test('scheduledEndTime should calculate correctly', () {
        final startTime = DateTime(2024, 12, 25, 14, 30);
        final task = Task(
          title: 'Test Task',
          durationMinutes: 90,
          scheduledStartTime: startTime,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        // 预期结束时间
        final expectedEndTime = DateTime(2024, 12, 25, 16, 0);
        // 比较预期结束时间和计划结束时间是否一致
        expect(task.scheduledEndTime, equals(expectedEndTime));
      });

      // 是否可以正确处理null情况
      test('scheduledEndTime should return null when scheduledStartTime is null', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.scheduledEndTime, isNull);
      });

      // 逾期判断
      test('isOverdue should return true for past deadline and not completed', () {
        final pastDeadline = DateTime.now().subtract(Duration(days: 1));
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          deadline: pastDeadline,
          status: TaskStatus.scheduled,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        // 验证是否是逾期状态
        expect(task.isOverdue, isTrue);
      });

      // 对于已完成的任务，isOverdue应该返回false
      test('isOverdue should return false for completed tasks', () {
        final pastDeadline = DateTime.now().subtract(Duration(days: 1));
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          deadline: pastDeadline,
          status: TaskStatus.completed,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.isOverdue, isFalse);
      });

      // 对于没有deadline的任务,isOverdue是否为false
      test('isOverdue should return false when no deadline', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          status: TaskStatus.pending,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.isOverdue, isFalse);
      });

      // 持续时间显示
      test('durationDisplay should format minutes correctly', () {
        // 小于60分钟测试
        final task1 = Task(
          title: 'Test Task',
          durationMinutes: 45,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );
        expect(task1.durationDisplay, equals('45 min'));

        // 等于60分钟测试
        final task2 = task1.copyWith(durationMinutes: 60);
        expect(task2.durationDisplay, equals('1 hr'));

        // 大于60分钟测试
        final task3 = task1.copyWith(durationMinutes: 90);
        expect(task3.durationDisplay, equals('1 hr 30 min'));

        // 多个小时测试
        final task4 = task1.copyWith(durationMinutes: 150);
        expect(task4.durationDisplay, equals('2 hr 30 min'));
      });
    });

    // 边界情况测试
    group('Edge Cases and Validation', () {
      // 空标题测试
      test('should handle empty title gracefully', () {
        final task = Task(
          title: '',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.title, isEmpty);
      });

      // 是否可以处理0持续时间
      test('should handle zero duration', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 0,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.durationMinutes, equals(0));
        expect(task.durationDisplay, equals('0 min'));
      });

      // 是否可以处理超长持续时间
      test('should handle very large duration', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 1440, // 24 hours
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
        );

        expect(task.durationDisplay, equals('24 hr'));
      });

      // 空列表处理
      test('should handle empty lists in JSON conversion', () {
        final task = Task(
          title: 'Test Task',
          durationMinutes: 60,
          priority: Priority.medium,
          energyRequired: EnergyLevel.medium,
          focusRequired: FocusLevel.medium,
          taskCategory: TaskCategory.routine,
          // 空列表
          preferredTimeBlockIds: [],
          avoidTimeBlockIds: [],
        );

        final map = task.toMap();
        // 空JSON数组
        expect(map['preferredTimeBlockIds'], equals('[]'));
        expect(map['avoidTimeBlockIds'], equals('[]'));

        final restoredTask = Task.fromMap(map);
        // 恢复后仍为空列表
        expect(restoredTask.preferredTimeBlockIds, isEmpty);
        expect(restoredTask.avoidTimeBlockIds, isEmpty);
      });
    });
  });
}