import 'package:flutter/material.dart';
import '../models/user_time_block.dart';
import '../services/database_service.dart';

// 定义TimeBlockProvider类
class TimeBlockProvider with ChangeNotifier {
  // 创建数据库服务实例(私有,不可变)
  final DatabaseService _db = DatabaseService.instance;

  List<UserTimeBlock> _allTimeBlocks = []; // 保存所有时间块（包括禁用的）
  bool _isLoading = false;
  String? _error;

  // 获取所有时间块（包括禁用的）- 用于设置页面(提供只读访问)
  List<UserTimeBlock> get allTimeBlocks => _allTimeBlocks;

  // 获取启用的时间块 - 用于日历和调度(提供只读访问)
  List<UserTimeBlock> get timeBlocks => _allTimeBlocks.where((block) => block.isActive).toList();

  bool get isLoading => _isLoading;  // 加载状态
  String? get error => _error;  // 错误信息

  // 加载所有时间块（包括禁用的）
  Future<void> loadTimeBlocks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 直接查询数据库，不过滤 isActive
      final db = await _db.database;
      // 查询数据库中的user_time_blocks表
      final maps = await db.query(
        'user_time_blocks',
        // 升序排列
        orderBy: 'startTime ASC',
      );
      // 讲map转换为UserTimeBlock对象,最终转为列表赋值给_allTimeBlocks
      _allTimeBlocks = maps.map((map) => UserTimeBlock.fromMap(map)).toList();
    } catch (e) {
      _error = '加载时间块失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // 获取某一天的时间块（只返回启用的）
  List<UserTimeBlock> getTimeBlocksForDay(int dayOfWeek) {
    // 过滤条件:dayOfWeek和时间块是否启用
    return _allTimeBlocks
        .where((block) => block.isActive && block.daysOfWeek.contains(dayOfWeek))
        .toList();
  }

  // 添加时间块
  Future<void> addTimeBlock(UserTimeBlock timeBlock) async {
    try {
      // 先将数据插入数据库
      await _db.insertTimeBlock(timeBlock);
      // 添加到列表再按时间重新排序
      _allTimeBlocks.add(timeBlock);
      _allTimeBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
    } catch (e) {
      _error = '添加时间块失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 更新时间块
  Future<void> updateTimeBlock(UserTimeBlock timeBlock) async {
    try {
      // 先更新数据库中数据
      await _db.updateTimeBlock(timeBlock);
      // 在列表中找到对应id时间块.替换并重新进行排序
      final index = _allTimeBlocks.indexWhere((t) => t.id == timeBlock.id);
      if (index != -1) {
        _allTimeBlocks[index] = timeBlock;
        _allTimeBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
      notifyListeners();
    } catch (e) {
      _error = '更新时间块失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 删除时间块
  Future<void> deleteTimeBlock(String id) async {
    try {
      await _db.deleteTimeBlock(id);
      _allTimeBlocks.removeWhere((block) => block.id == id);
      notifyListeners();
    } catch (e) {
      _error = '删除时间块失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 切换时间块启用状态(模型中添加CopyWith方法,之后去进行调整)
  Future<void> toggleTimeBlockActive(String id) async {
    final block = _allTimeBlocks.firstWhere((b) => b.id == id);
    final updatedBlock = UserTimeBlock(
      id: block.id,
      name: block.name,
      startTime: block.startTime,
      endTime: block.endTime,
      daysOfWeek: block.daysOfWeek,
      energyLevel: block.energyLevel,
      focusLevel: block.focusLevel,
      suitableCategories: block.suitableCategories,
      suitablePriorities: block.suitablePriorities,
      suitableEnergyLevels: block.suitableEnergyLevels,
      description: block.description,
      color: block.color,
      // 只改变启用状态
      isActive: !block.isActive,
      isDefault: block.isDefault,
      createdAt: block.createdAt,
    );

    await updateTimeBlock(updatedBlock);
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}