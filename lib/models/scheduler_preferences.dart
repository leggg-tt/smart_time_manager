class SchedulerPreferences {
  // 权重配置（0-100）
  final int energyMatchWeight;        // 能量匹配权重
  final int focusMatchWeight;         // 专注度匹配权重
  final int categoryMatchWeight;      // 任务类型匹配权重
  final int priorityMatchWeight;      // 优先级匹配权重
  final int timeUtilizationWeight;    // 时间利用率权重
  final int morningBoostWeight;       // 早晨加分权重

  // 行为偏好
  final bool preferMorningForHighPriority;  // 高优先级任务优先安排在早晨
  final bool avoidFragmentation;            // 避免时间碎片化
  final bool groupSimilarTasks;              // 相似任务分组
  final int minBreakBetweenTasks;           // 任务间最小休息时间（分钟）

  SchedulerPreferences({
    required this.energyMatchWeight,
    required this.focusMatchWeight,
    required this.categoryMatchWeight,
    required this.priorityMatchWeight,
    required this.timeUtilizationWeight,
    required this.morningBoostWeight,
    this.preferMorningForHighPriority = true,
    this.avoidFragmentation = true,
    this.groupSimilarTasks = false,
    this.minBreakBetweenTasks = 5,
  });

  // 默认权重配置
  static SchedulerPreferences get defaultPreferences => SchedulerPreferences(
    energyMatchWeight: 25,
    focusMatchWeight: 25,
    categoryMatchWeight: 25,
    priorityMatchWeight: 25,
    timeUtilizationWeight: 0,  // 改为0，使总和正好100
    morningBoostWeight: 0,      // 改为0，使总和正好100
    preferMorningForHighPriority: true,
    avoidFragmentation: true,
    groupSimilarTasks: false,
    minBreakBetweenTasks: 15,   // 保持与原来一致
  );

  // 预设模板
  static final Map<String, SchedulerPreferences> presets = {
    'balanced': SchedulerPreferences(
      energyMatchWeight: 25,
      focusMatchWeight: 25,
      categoryMatchWeight: 25,
      priorityMatchWeight: 25,
      timeUtilizationWeight: 0,
      morningBoostWeight: 0,
      preferMorningForHighPriority: true,
      avoidFragmentation: true,
      groupSimilarTasks: false,
      minBreakBetweenTasks: 15,
    ),
    'energy_focused': SchedulerPreferences(
      energyMatchWeight: 40,
      focusMatchWeight: 20,
      categoryMatchWeight: 20,
      priorityMatchWeight: 15,
      timeUtilizationWeight: 3,
      morningBoostWeight: 2,
      preferMorningForHighPriority: true,
      avoidFragmentation: true,
      groupSimilarTasks: false,
      minBreakBetweenTasks: 15,
    ),
    'priority_focused': SchedulerPreferences(
      energyMatchWeight: 15,
      focusMatchWeight: 20,
      categoryMatchWeight: 20,
      priorityMatchWeight: 40,
      timeUtilizationWeight: 3,
      morningBoostWeight: 2,
      preferMorningForHighPriority: true,
      avoidFragmentation: true,
      groupSimilarTasks: false,
      minBreakBetweenTasks: 15,
    ),
    'efficiency_focused': SchedulerPreferences(
      energyMatchWeight: 20,
      focusMatchWeight: 20,
      categoryMatchWeight: 20,
      priorityMatchWeight: 20,
      timeUtilizationWeight: 15,
      morningBoostWeight: 5,
      preferMorningForHighPriority: true,
      avoidFragmentation: true,
      groupSimilarTasks: true,
      minBreakBetweenTasks: 5,
    ),
  };

  // 归一化权重（确保总和为100）
  SchedulerPreferences normalize() {
    final total = energyMatchWeight +
        focusMatchWeight +
        categoryMatchWeight +
        priorityMatchWeight +
        timeUtilizationWeight +
        morningBoostWeight;

    if (total == 0) return defaultPreferences;

    final factor = 100.0 / total;

    return SchedulerPreferences(
      energyMatchWeight: (energyMatchWeight * factor).round(),
      focusMatchWeight: (focusMatchWeight * factor).round(),
      categoryMatchWeight: (categoryMatchWeight * factor).round(),
      priorityMatchWeight: (priorityMatchWeight * factor).round(),
      timeUtilizationWeight: (timeUtilizationWeight * factor).round(),
      morningBoostWeight: (morningBoostWeight * factor).round(),
      preferMorningForHighPriority: preferMorningForHighPriority,
      avoidFragmentation: avoidFragmentation,
      groupSimilarTasks: groupSimilarTasks,
      minBreakBetweenTasks: minBreakBetweenTasks,
    );
  }

  Map<String, dynamic> toJson() => {
    'energyMatchWeight': energyMatchWeight,
    'focusMatchWeight': focusMatchWeight,
    'categoryMatchWeight': categoryMatchWeight,
    'priorityMatchWeight': priorityMatchWeight,
    'timeUtilizationWeight': timeUtilizationWeight,
    'morningBoostWeight': morningBoostWeight,
    'preferMorningForHighPriority': preferMorningForHighPriority,
    'avoidFragmentation': avoidFragmentation,
    'groupSimilarTasks': groupSimilarTasks,
    'minBreakBetweenTasks': minBreakBetweenTasks,
  };

  factory SchedulerPreferences.fromJson(Map<String, dynamic> json) => SchedulerPreferences(
    energyMatchWeight: json['energyMatchWeight'] ?? 25,
    focusMatchWeight: json['focusMatchWeight'] ?? 25,
    categoryMatchWeight: json['categoryMatchWeight'] ?? 25,
    priorityMatchWeight: json['priorityMatchWeight'] ?? 25,
    timeUtilizationWeight: json['timeUtilizationWeight'] ?? 5,
    morningBoostWeight: json['morningBoostWeight'] ?? 5,
    preferMorningForHighPriority: json['preferMorningForHighPriority'] ?? true,
    avoidFragmentation: json['avoidFragmentation'] ?? true,
    groupSimilarTasks: json['groupSimilarTasks'] ?? false,
    minBreakBetweenTasks: json['minBreakBetweenTasks'] ?? 5,
  );

  SchedulerPreferences copyWith({
    int? energyMatchWeight,
    int? focusMatchWeight,
    int? categoryMatchWeight,
    int? priorityMatchWeight,
    int? timeUtilizationWeight,
    int? morningBoostWeight,
    bool? preferMorningForHighPriority,
    bool? avoidFragmentation,
    bool? groupSimilarTasks,
    int? minBreakBetweenTasks,
  }) => SchedulerPreferences(
    energyMatchWeight: energyMatchWeight ?? this.energyMatchWeight,
    focusMatchWeight: focusMatchWeight ?? this.focusMatchWeight,
    categoryMatchWeight: categoryMatchWeight ?? this.categoryMatchWeight,
    priorityMatchWeight: priorityMatchWeight ?? this.priorityMatchWeight,
    timeUtilizationWeight: timeUtilizationWeight ?? this.timeUtilizationWeight,
    morningBoostWeight: morningBoostWeight ?? this.morningBoostWeight,
    preferMorningForHighPriority: preferMorningForHighPriority ?? this.preferMorningForHighPriority,
    avoidFragmentation: avoidFragmentation ?? this.avoidFragmentation,
    groupSimilarTasks: groupSimilarTasks ?? this.groupSimilarTasks,
    minBreakBetweenTasks: minBreakBetweenTasks ?? this.minBreakBetweenTasks,
  );
}