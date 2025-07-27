// AI偏好设置模型
class AIPreferences {
  // 任务默认时长（分钟）
  final int meetingDefaultDuration;  // 会议类任务默认时长（分钟）
  final int creativeDefaultDuration;  // 创意类任务默认时长
  final int routineDefaultDuration;  // 日常类任务默认时长
  final int analyticalDefaultDuration;  // 分析类任务默认时长

  // 会议/通话类默认属性
  final String meetingDefaultEnergy;  // 默认能量需求
  final String meetingDefaultFocus;  // 默认专注度需求

  // 创意工作类默认属性
  final String creativeDefaultEnergy;  // 默认能量需求
  final String creativeDefaultFocus;  // 默认专注度需求

  // 日常任务类默认属性
  final String routineDefaultEnergy;  // 默认能量需求
  final String routineDefaultFocus;  // 默认专注度需求

  // 分析工作类默认属性
  final String analyticalDefaultEnergy;  // 默认能量需求
  final String analyticalDefaultFocus;  // 默认专注度需求

  // 时间解析偏好
  final String tomorrowDefaultTime;  // 假设语音只解析出明天,默认时间是
  final String nextWeekDefaultDay;  // 假设语音只解析出下周,默认时间是
  final String workTimePreference;  // 工作时间偏好

  // API使用次数统计
  final int apiCallCount;  // API调用次数
  final DateTime? lastApiCallTime;  // 最后一次API调用时间

  // 构造函数,默认模板
  AIPreferences({
    this.meetingDefaultDuration = 60,
    this.creativeDefaultDuration = 90,
    this.routineDefaultDuration = 30,
    this.analyticalDefaultDuration = 60,
    this.meetingDefaultEnergy = 'medium',
    this.meetingDefaultFocus = 'medium',
    this.creativeDefaultEnergy = 'high',
    this.creativeDefaultFocus = 'deep',
    this.routineDefaultEnergy = 'low',
    this.routineDefaultFocus = 'light',
    this.analyticalDefaultEnergy = 'medium',
    this.analyticalDefaultFocus = 'deep',
    this.tomorrowDefaultTime = '09:00',
    this.nextWeekDefaultDay = 'monday',
    this.workTimePreference = 'balanced',
    this.apiCallCount = 0,
    this.lastApiCallTime,
  });

  // 默认偏好设置,获取默认配置实例
  static AIPreferences get defaultPreferences => AIPreferences();

  // JSON 序列化
  Map<String, dynamic> toJson() => {
    'meetingDefaultDuration': meetingDefaultDuration,
    'creativeDefaultDuration': creativeDefaultDuration,
    'routineDefaultDuration': routineDefaultDuration,
    'analyticalDefaultDuration': analyticalDefaultDuration,
    'meetingDefaultEnergy': meetingDefaultEnergy,
    'meetingDefaultFocus': meetingDefaultFocus,
    'creativeDefaultEnergy': creativeDefaultEnergy,
    'creativeDefaultFocus': creativeDefaultFocus,
    'routineDefaultEnergy': routineDefaultEnergy,
    'routineDefaultFocus': routineDefaultFocus,
    'analyticalDefaultEnergy': analyticalDefaultEnergy,
    'analyticalDefaultFocus': analyticalDefaultFocus,
    'tomorrowDefaultTime': tomorrowDefaultTime,
    'nextWeekDefaultDay': nextWeekDefaultDay,
    'workTimePreference': workTimePreference,
    'apiCallCount': apiCallCount,
    'lastApiCallTime': lastApiCallTime?.toIso8601String(),
  };

  // 将json数据(map格式)转换回AIPreferences对象实例
  factory AIPreferences.fromJson(Map<String, dynamic> json) => AIPreferences(
    meetingDefaultDuration: json['meetingDefaultDuration'] ?? 60,
    creativeDefaultDuration: json['creativeDefaultDuration'] ?? 90,
    routineDefaultDuration: json['routineDefaultDuration'] ?? 30,
    analyticalDefaultDuration: json['analyticalDefaultDuration'] ?? 60,
    meetingDefaultEnergy: json['meetingDefaultEnergy'] ?? 'medium',
    meetingDefaultFocus: json['meetingDefaultFocus'] ?? 'medium',
    creativeDefaultEnergy: json['creativeDefaultEnergy'] ?? 'high',
    creativeDefaultFocus: json['creativeDefaultFocus'] ?? 'deep',
    routineDefaultEnergy: json['routineDefaultEnergy'] ?? 'low',
    routineDefaultFocus: json['routineDefaultFocus'] ?? 'light',
    analyticalDefaultEnergy: json['analyticalDefaultEnergy'] ?? 'medium',
    analyticalDefaultFocus: json['analyticalDefaultFocus'] ?? 'deep',
    tomorrowDefaultTime: json['tomorrowDefaultTime'] ?? '09:00',
    nextWeekDefaultDay: json['nextWeekDefaultDay'] ?? 'monday',
    workTimePreference: json['workTimePreference'] ?? 'balanced',
    apiCallCount: json['apiCallCount'] ?? 0,
    lastApiCallTime: json['lastApiCallTime'] != null
        ? DateTime.parse(json['lastApiCallTime'])
        : null,
  );

  // 创建当前对象的副本,只修改指定的字段,保持其他字段不变
  AIPreferences copyWith({
    int? meetingDefaultDuration,
    int? creativeDefaultDuration,
    int? routineDefaultDuration,
    int? analyticalDefaultDuration,
    String? meetingDefaultEnergy,
    String? meetingDefaultFocus,
    String? creativeDefaultEnergy,
    String? creativeDefaultFocus,
    String? routineDefaultEnergy,
    String? routineDefaultFocus,
    String? analyticalDefaultEnergy,
    String? analyticalDefaultFocus,
    String? tomorrowDefaultTime,
    String? nextWeekDefaultDay,
    String? workTimePreference,
    int? apiCallCount,
    DateTime? lastApiCallTime,
  }) => AIPreferences(
    meetingDefaultDuration: meetingDefaultDuration ?? this.meetingDefaultDuration,
    creativeDefaultDuration: creativeDefaultDuration ?? this.creativeDefaultDuration,
    routineDefaultDuration: routineDefaultDuration ?? this.routineDefaultDuration,
    analyticalDefaultDuration: analyticalDefaultDuration ?? this.analyticalDefaultDuration,
    meetingDefaultEnergy: meetingDefaultEnergy ?? this.meetingDefaultEnergy,
    meetingDefaultFocus: meetingDefaultFocus ?? this.meetingDefaultFocus,
    creativeDefaultEnergy: creativeDefaultEnergy ?? this.creativeDefaultEnergy,
    creativeDefaultFocus: creativeDefaultFocus ?? this.creativeDefaultFocus,
    routineDefaultEnergy: routineDefaultEnergy ?? this.routineDefaultEnergy,
    routineDefaultFocus: routineDefaultFocus ?? this.routineDefaultFocus,
    analyticalDefaultEnergy: analyticalDefaultEnergy ?? this.analyticalDefaultEnergy,
    analyticalDefaultFocus: analyticalDefaultFocus ?? this.analyticalDefaultFocus,
    tomorrowDefaultTime: tomorrowDefaultTime ?? this.tomorrowDefaultTime,
    nextWeekDefaultDay: nextWeekDefaultDay ?? this.nextWeekDefaultDay,
    workTimePreference: workTimePreference ?? this.workTimePreference,
    apiCallCount: apiCallCount ?? this.apiCallCount,
    lastApiCallTime: lastApiCallTime ?? this.lastApiCallTime,
  );

  // 生成自定义的解析规则文本
  // 用户可以在通用设置界面自行更改
  // 但考虑到可以改变的内容较少,现在想的解决办法是在ai_service中自己再加一些prompt来完善
  String generateParsingRules() {
    return '''
Parsing rules:
1. If duration is not specified, use these defaults based on task type:
   - Meetings/calls: $meetingDefaultDuration minutes
   - Creative work: $creativeDefaultDuration minutes
   - Routine tasks: $routineDefaultDuration minutes
   - Analytical tasks: $analyticalDefaultDuration minutes
2. If priority is not mentioned, judge based on tone and deadline urgency
3. Infer appropriate category, energy and focus requirements based on task content
4. If relative time like "tomorrow", "next week", "this afternoon" is mentioned, convert to specific date:
   - "tomorrow" should default to $tomorrowDefaultTime
   - "next week" should default to $nextWeekDefaultDay
   - Work time preference: $workTimePreference (morning: 6-12, balanced: 9-17, night: 14-22)
5. If no specific time is mentioned, recommend suitable time slots based on task type and work time preference
6. For meetings/calls, default to $meetingDefaultEnergy energy and $meetingDefaultFocus focus
7. For creative work, default to $creativeDefaultEnergy energy and $creativeDefaultFocus focus
8. For routine tasks, default to $routineDefaultEnergy energy and $routineDefaultFocus focus
9. For analytical tasks, default to $analyticalDefaultEnergy energy and $analyticalDefaultFocus focus
''';
  }
}