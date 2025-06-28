import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'enums.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final int durationMinutes;
  final DateTime? deadline;
  DateTime? scheduledStartTime;
  DateTime? actualStartTime;
  DateTime? actualEndTime;
  final Priority priority;
  final EnergyLevel energyRequired;
  final FocusLevel focusRequired;
  final TaskCategory taskCategory;
  TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  DateTime? completedAt;
  List<String>? preferredTimeBlockIds;
  List<String>? avoidTimeBlockIds;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.durationMinutes,
    this.deadline,
    this.scheduledStartTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.priority,
    required this.energyRequired,
    required this.focusRequired,
    required this.taskCategory,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.preferredTimeBlockIds,
    this.avoidTimeBlockIds,
  })  : id = id ?? const Uuid().v4(),
        status = status ?? TaskStatus.pending,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 转换为Map以存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'deadline': deadline?.millisecondsSinceEpoch,
      'scheduledStartTime': scheduledStartTime?.millisecondsSinceEpoch,
      'actualStartTime': actualStartTime?.millisecondsSinceEpoch,
      'actualEndTime': actualEndTime?.millisecondsSinceEpoch,
      'priority': priority.index,
      'energyRequired': energyRequired.index,
      'focusRequired': focusRequired.index,
      'taskCategory': taskCategory.index,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'preferredTimeBlockIds': preferredTimeBlockIds != null
          ? jsonEncode(preferredTimeBlockIds)
          : null,
      'avoidTimeBlockIds': avoidTimeBlockIds != null
          ? jsonEncode(avoidTimeBlockIds)
          : null,
    };
  }

  // 从数据库Map创建Task对象
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      durationMinutes: map['durationMinutes'],
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
          : null,
      scheduledStartTime: map['scheduledStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledStartTime'])
          : null,
      actualStartTime: map['actualStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualStartTime'])
          : null,
      actualEndTime: map['actualEndTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualEndTime'])
          : null,
      priority: Priority.values[map['priority']],
      energyRequired: EnergyLevel.values[map['energyRequired']],
      focusRequired: FocusLevel.values[map['focusRequired']],
      taskCategory: TaskCategory.values[map['taskCategory']],
      status: TaskStatus.values[map['status']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      preferredTimeBlockIds: map['preferredTimeBlockIds'] != null
          ? List<String>.from(jsonDecode(map['preferredTimeBlockIds']))
          : null,
      avoidTimeBlockIds: map['avoidTimeBlockIds'] != null
          ? List<String>.from(jsonDecode(map['avoidTimeBlockIds']))
          : null,
    );
  }

  // 复制并修改部分属性
  Task copyWith({
    String? title,
    String? description,
    int? durationMinutes,
    DateTime? deadline,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    Priority? priority,
    EnergyLevel? energyRequired,
    FocusLevel? focusRequired,
    TaskCategory? taskCategory,
    TaskStatus? status,
    DateTime? completedAt,
    List<String>? preferredTimeBlockIds,
    List<String>? avoidTimeBlockIds,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      deadline: deadline ?? this.deadline,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      priority: priority ?? this.priority,
      energyRequired: energyRequired ?? this.energyRequired,
      focusRequired: focusRequired ?? this.focusRequired,
      taskCategory: taskCategory ?? this.taskCategory,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      preferredTimeBlockIds: preferredTimeBlockIds ?? this.preferredTimeBlockIds,
      avoidTimeBlockIds: avoidTimeBlockIds ?? this.avoidTimeBlockIds,
    );
  }

  // 获取任务的结束时间
  DateTime? get scheduledEndTime {
    if (scheduledStartTime == null) return null;
    return scheduledStartTime!.add(Duration(minutes: durationMinutes));
  }

  // 检查任务是否已过期
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && status != TaskStatus.completed;
  }

  // 获取任务持续时间的友好显示
  String get durationDisplay {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }
}