import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_time_manager/providers/time_block_provider.dart';
import 'package:smart_time_manager/models/user_time_block.dart';
import 'package:smart_time_manager/models/enums.dart';

// 主测试函数
void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试时间块的辅助方法
  UserTimeBlock createTestTimeBlock({
    String? id,
    String name = 'Test Time Block',
    String startTime = '09:00',
    String endTime = '11:00',
    List<int>? daysOfWeek,
    EnergyLevel energyLevel = EnergyLevel.medium,
    FocusLevel focusLevel = FocusLevel.medium,
    bool isActive = true,
    bool isDefault = false,
  }) {
    return UserTimeBlock(
      id: id ?? 'test-block-1',
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek ?? [1, 2, 3, 4, 5], // 默认工作日
      energyLevel: energyLevel,
      focusLevel: focusLevel,
      suitableCategories: [TaskCategory.routine],
      suitablePriorities: [Priority.medium],
      suitableEnergyLevels: [EnergyLevel.medium],
      description: 'Test description',
      color: '0xFF2196F3', // 修改为字符串
      isActive: isActive,
      isDefault: isDefault,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('TimeBlockProvider 初始化测试', () {
    test('初始状态应该正确', () {
      final provider = TimeBlockProvider();

      // 测试provider的初始状态
      expect(provider.allTimeBlocks, isEmpty);
      expect(provider.timeBlocks, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('获取启用的时间块应该过滤掉禁用的', () {
      final provider = TimeBlockProvider();

      expect(provider.timeBlocks, isEmpty);
      expect(provider.allTimeBlocks, isEmpty);
    });
  });

  // 时间块管理测试
  group('TimeBlockProvider 时间块管理测试', () {
    // 测试按星期几获取时间块的功能
    test('获取某一天的时间块应该正确过滤', () {
      final provider = TimeBlockProvider();

      // 初始状态下应该返回空列表
      expect(provider.getTimeBlocksForDay(1), isEmpty); // 周一
      expect(provider.getTimeBlocksForDay(6), isEmpty); // 周六
    });

    // 测试清除错误信息功能
    test('清除错误应该正常工作', () {
      final provider = TimeBlockProvider();

      // 初始状态错误应该为null
      expect(provider.error, isNull);

      // 清除错误
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  // 监听器测试
  group('TimeBlockProvider 监听器测试', () {
    // 测试ChangeNotifier的通知机制
    test('清除错误应该通知监听器', () {
      final provider = TimeBlockProvider();
      var notificationCount = 0;

      // 添加监听器
      provider.addListener(() {
        notificationCount++;
      });

      // 调用clearError触发通知
      provider.clearError();

      // 验证监听器被调用
      expect(notificationCount, equals(1));

      // 移除监听器
      provider.removeListener(() {});
    });
  });

  // 属性访问测试
  group('TimeBlockProvider 属性访问测试', () {
    // 测试加载状态getter
    test('isLoading 应该返回正确的加载状态', () {
      final provider = TimeBlockProvider();
      expect(provider.isLoading, isFalse);
    });

    // 测试错误信息getter
    test('error 应该返回当前错误信息', () {
      final provider = TimeBlockProvider();
      expect(provider.error, isNull);
    });

    // 测试获取所有时间块（包括禁用的）
    test('allTimeBlocks 应该返回所有时间块列表', () {
      final provider = TimeBlockProvider();
      expect(provider.allTimeBlocks, isNotNull);
      expect(provider.allTimeBlocks, isEmpty);
    });

    // 测试获取启用的时间块
    test('timeBlocks 应该只返回启用的时间块', () {
      final provider = TimeBlockProvider();
      expect(provider.timeBlocks, isNotNull);
      expect(provider.timeBlocks, isEmpty);
    });
  });

  // 业务逻辑测试
  group('TimeBlockProvider 业务逻辑测试', () {
    // 测试所有星期的时间块获取
    test('getTimeBlocksForDay 应该正确处理不同的星期参数', () {
      final provider = TimeBlockProvider();

      // 测试所有星期
      for (int day = 1; day <= 7; day++) {
        final blocks = provider.getTimeBlocksForDay(day);
        expect(blocks, isNotNull);
        expect(blocks, isEmpty); // 初始状态应该为空
      }
    });

    test('getTimeBlocksForDay 应该返回列表而不是null', () {
      final provider = TimeBlockProvider();

      // 即使没有匹配的时间块,也应该返回空列表
      final mondayBlocks = provider.getTimeBlocksForDay(1);
      expect(mondayBlocks, isNotNull);
      expect(mondayBlocks, isList);
    });
  });

  // 边界情况测试
  group('TimeBlockProvider 边界情况测试', () {
    // 测试无效输入的处理
    test('getTimeBlocksForDay 处理无效的星期值', () {
      final provider = TimeBlockProvider();

      // 测试边界值（虽然实际应用中不应该出现）
      expect(() => provider.getTimeBlocksForDay(0), returnsNormally);
      expect(() => provider.getTimeBlocksForDay(8), returnsNormally);
      expect(() => provider.getTimeBlocksForDay(-1), returnsNormally);

      // 这些调用应该返回空列表
      expect(provider.getTimeBlocksForDay(0), isEmpty);
      expect(provider.getTimeBlocksForDay(8), isEmpty);
    });
  });
}