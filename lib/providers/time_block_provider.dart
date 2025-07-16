import 'package:flutter/material.dart';
import '../models/user_time_block.dart';
import '../services/database_service.dart';

class TimeBlockProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<UserTimeBlock> _allTimeBlocks = []; // 保存所有时间块（包括禁用的）
  bool _isLoading = false;
  String? _error;

  // 获取所有时间块（包括禁用的）- 用于设置页面
  List<UserTimeBlock> get allTimeBlocks => _allTimeBlocks;

  // 获取启用的时间块 - 用于日历和调度
  List<UserTimeBlock> get timeBlocks => _allTimeBlocks.where((block) => block.isActive).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  // 加载所有时间块（包括禁用的）
  Future<void> loadTimeBlocks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 直接查询数据库，不过滤 isActive
      final db = await _db.database;
      final maps = await db.query(
        'user_time_blocks',
        orderBy: 'startTime ASC',
      );
      _allTimeBlocks = maps.map((map) => UserTimeBlock.fromMap(map)).toList();
    } catch (e) {
      _error = '加载时间块失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // 获取某一天的时间块（只返回启用的）
  List<UserTimeBlock> getTimeBlocksForDay(int dayOfWeek) {
    return _allTimeBlocks
        .where((block) => block.isActive && block.daysOfWeek.contains(dayOfWeek))
        .toList();
  }

  // 添加时间块
  Future<void> addTimeBlock(UserTimeBlock timeBlock) async {
    try {
      await _db.insertTimeBlock(timeBlock);
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
      await _db.updateTimeBlock(timeBlock);
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

  // 切换时间块启用状态
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