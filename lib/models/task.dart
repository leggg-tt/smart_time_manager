import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'enums.dart';

// task属性说明
class Task {
  final String id;  // 任务的唯一标识符(不可变)
  final String title;  // 任务标题(不可变)
  final String? description;  // 任务描述(可选)
  final int durationMinutes;  // 任务预计持续时间
  final DateTime? deadline;  // 截止日期(可选)
  DateTime? scheduledStartTime; // 计划开始时间(可修改)
  DateTime? actualStartTime;  // 实际开始时间
  DateTime? actualEndTime;  // 实际结束时间
  final Priority priority;  // 优先级
  final EnergyLevel energyRequired;  // 所需能量水平
  final FocusLevel focusRequired;  // 所需专注度
  final TaskCategory taskCategory;  // 任务类别
  TaskStatus status;  // 任务状态
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 更改时间
  DateTime? completedAt;  // 完成时间(可选)
  List<String>? preferredTimeBlockIds;  //偏好时间块id列表
  List<String>? avoidTimeBlockIds;  //避免时间块id列表


  // 构造函数
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
  })  : id = id ?? const Uuid().v4(),  // 自动生成UUID
        status = status ?? TaskStatus.pending,  // 默认任务状态为待处理
        createdAt = createdAt ?? DateTime.now(),  // 默认创建时间是现在的时间
        updatedAt = updatedAt ?? DateTime.now();  // 默认更新时间为当时的时间

  // 转换为Map以存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      // 将DateTime转换为毫秒时间戳存储
      'deadline': deadline?.millisecondsSinceEpoch,
      'scheduledStartTime': scheduledStartTime?.millisecondsSinceEpoch,
      'actualStartTime': actualStartTime?.millisecondsSinceEpoch,
      'actualEndTime': actualEndTime?.millisecondsSinceEpoch,
      // 枚举值存储为索引
      'priority': priority.index,
      'energyRequired': energyRequired.index,
      'focusRequired': focusRequired.index,
      'taskCategory': taskCategory.index,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      // 将列表转换为JSON字符串存储(暂时没用上)
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
      // 从时间戳恢复DateTime对象
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
      // 从索引恢复枚举值
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
      // 从JSON字符串恢复列表(暂时没用)
      preferredTimeBlockIds: map['preferredTimeBlockIds'] != null
          ? List<String>.from(jsonDecode(map['preferredTimeBlockIds']))
          : null,
      avoidTimeBlockIds: map['avoidTimeBlockIds'] != null
          ? List<String>.from(jsonDecode(map['avoidTimeBlockIds']))
          : null,
    );
  }

  // 复制并修改部分属性,方便进行修改操作
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
    if (deadline == null) return false;  // 没有截至日期就不会过期
    // 超过截止日期任务未完成则过期
    return DateTime.now().isAfter(deadline!) && status != TaskStatus.completed;
  }

  // 获取任务持续时间的显示
  String get durationDisplay {
    if (durationMinutes < 60) {
      return '$durationMinutes min';  // 少于一小时显示分钟
    } else {
      final hours = durationMinutes ~/ 60;  // 整数除法得到小时数
      final minutes = durationMinutes % 60;  // 余数得到剩余分钟
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }
}