import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'enums.dart';

class UserTimeBlock {
  final String id;
  final String name;
  final String startTime; // HH:mm格式
  final String endTime;   // HH:mm格式
  final List<int> daysOfWeek; // 1-7, 1=周一
  final EnergyLevel energyLevel;
  final FocusLevel focusLevel;
  final List<TaskCategory> suitableCategories;
  final List<Priority> suitablePriorities;
  final List<EnergyLevel> suitableEnergyLevels;
  final String? description;
  final String color;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  })  : id = id ?? const Uuid().v4(),
        color = color ?? '#2196F3',
        isActive = isActive ?? true,
        isDefault = isDefault ?? false,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
    if (!daysOfWeek.contains(dateTime.weekday)) {
      return false;
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return timeStr.compareTo(startTime) >= 0 &&
        timeStr.compareTo(endTime) < 0;
  }

  // 获取时间块的持续时间（分钟）
  int get durationMinutes {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  }

  // 解析时间字符串
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