import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'enums.dart';

// 定义一个用户时间块类
class UserTimeBlock {
  final String id;  // 唯一标识符
  final String name;  // 时间块名称
  final String startTime;  // HH:mm格式
  final String endTime;  // HH:mm格式
  final List<int> daysOfWeek; // 1-7, 1=周一
  final EnergyLevel energyLevel;  // 能量水平
  final FocusLevel focusLevel;  // 专注水平
  final List<TaskCategory> suitableCategories;  // 适合这个时间块做的任务类别
  final List<Priority> suitablePriorities;  // 适合这个时间块处理的任务优先级
  final List<EnergyLevel> suitableEnergyLevels;  // 适合这个时间块的能量水平
  final String? description;  // 可选描述
  final String color;  // 时间块颜色
  final bool isActive;  // 是否启用
  final bool isDefault;  // 是否是初始默认时间块
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 更新时间

  // 构造函数
  UserTimeBlock({
    String? id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    required this.energyLevel,
    required this.focusLevel,
    required this.suitableCategories,
    required this.suitablePriorities,
    required this.suitableEnergyLevels,
    this.description,
    String? color,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),  // 自动生成UUID
        color = color ?? '#2196F3',  // 默认蓝色
        isActive = isActive ?? true,  // 默认启用
        isDefault = isDefault ?? false,  // 默认非默认时间块
        createdAt = createdAt ?? DateTime.now(),  // 默认当前时间
        updatedAt = updatedAt ?? DateTime.now();  // 默认当前时间

  // 将对象转换为 Map，用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'daysOfWeek': jsonEncode(daysOfWeek),
      'energyLevel': energyLevel.index,
      'focusLevel': focusLevel.index,
      'suitableCategories': jsonEncode(
        suitableCategories.map((e) => e.index).toList(),
      ),
      'suitablePriorities': jsonEncode(
        suitablePriorities.map((e) => e.index).toList(),
      ),
      'suitableEnergyLevels': jsonEncode(
        suitableEnergyLevels.map((e) => e.index).toList(),
      ),
      'description': description,
      'color': color,
      'isActive': isActive ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // 从 Map 创建对象实例
  factory UserTimeBlock.fromMap(Map<String, dynamic> map) {
    return UserTimeBlock(
      id: map['id'],
      name: map['name'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      daysOfWeek: List<int>.from(jsonDecode(map['daysOfWeek'])),
      energyLevel: EnergyLevel.values[map['energyLevel']],
      focusLevel: FocusLevel.values[map['focusLevel']],
      suitableCategories: (jsonDecode(map['suitableCategories']) as List)
          .map((e) => TaskCategory.values[e])
          .toList(),
      suitablePriorities: (jsonDecode(map['suitablePriorities']) as List)
          .map((e) => Priority.values[e])
          .toList(),
      suitableEnergyLevels: (jsonDecode(map['suitableEnergyLevels']) as List)
          .map((e) => EnergyLevel.values[e])
          .toList(),
      description: map['description'],
      color: map['color'],
      isActive: map['isActive'] == 1,
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  // 检查某个时间是否在这个时间块内
  bool containsTime(DateTime dateTime) {
    // 检查是否在weekday的列表当中
    if (!daysOfWeek.contains(dateTime.weekday)) {
      return false;
    }
    // 时间字符串构建,确保单位数补0(9变成09)
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    // 时间范围比较
    return timeStr.compareTo(startTime) >= 0 &&
        timeStr.compareTo(endTime) < 0;
  }

  // 获取时间块的持续时间（分钟）
  int get durationMinutes {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  }

  // 解析时间字符串("14:30" → ["14", "30"])
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

// 用于在UI中表示时间
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}