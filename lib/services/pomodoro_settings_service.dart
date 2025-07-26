import 'package:shared_preferences/shared_preferences.dart';

class PomodoroSettings {
  final int workDuration;      // 以分钟为单位
  final int shortBreakDuration; // 以分钟为单位
  final int longBreakDuration;  // 以分钟为单位
  final int pomodorosUntilLongBreak;

  // 构造函数
  PomodoroSettings({
    required this.workDuration, // 工作时长
    required this.shortBreakDuration, // 短休息时长
    required this.longBreakDuration,  // 长休息时长
    required this.pomodorosUntilLongBreak,  // 需要多少个番茄时钟才能获得一次长休息
  });

  // 默认设置
  static PomodoroSettings get defaultSettings => PomodoroSettings(
    // 返回默认的番茄时钟设置
    workDuration: 25,
    shortBreakDuration: 5,
    longBreakDuration: 15,
    pomodorosUntilLongBreak: 4,
  );

  // 预设模板
  static final Map<String, PomodoroSettings> presets = {
    // 静态MAP,存储三种预设的番茄时钟设置
    // 经典配置
    'classic': PomodoroSettings(
      workDuration: 25,
      shortBreakDuration: 5,
      longBreakDuration: 15,
      pomodorosUntilLongBreak: 4,
    ),
    // 短时专注设置
    'short_focus': PomodoroSettings(
      workDuration: 15,
      shortBreakDuration: 3,
      longBreakDuration: 10,
      pomodorosUntilLongBreak: 4,
    ),
    // 深度工作设置
    'deep_work': PomodoroSettings(
      workDuration: 45,
      shortBreakDuration: 10,
      longBreakDuration: 30,
      pomodorosUntilLongBreak: 3,
    ),
  };

  // 序列化方法,将对象转换为MAP,用于存储到SharedPreferences
  Map<String, dynamic> toJson() => {
    'workDuration': workDuration,
    'shortBreakDuration': shortBreakDuration,
    'longBreakDuration': longBreakDuration,
    'pomodorosUntilLongBreak': pomodorosUntilLongBreak,
  };

  // 反序列化工厂构造函数,从 Map 创建 PomodoroSettings 对象
  factory PomodoroSettings.fromJson(Map<String, dynamic> json) => PomodoroSettings(
    // 使用??空值合并运算符提供默认值,防止数据缺失
    workDuration: json['workDuration'] ?? 25,
    shortBreakDuration: json['shortBreakDuration'] ?? 5,
    longBreakDuration: json['longBreakDuration'] ?? 15,
    pomodorosUntilLongBreak: json['pomodorosUntilLongBreak'] ?? 4,
  );

  // 实现不可变对象的更新模式
  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? pomodorosUntilLongBreak,
  }) => PomodoroSettings(
    // 创建一个新对象,只修改指定的属性值,其他属性保持不变
    workDuration: workDuration ?? this.workDuration,
    shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
    longBreakDuration: longBreakDuration ?? this.longBreakDuration,
    pomodorosUntilLongBreak: pomodorosUntilLongBreak ?? this.pomodorosUntilLongBreak,
  );
}

// 定义PomodoroSettingsService类
class PomodoroSettingsService {
  // 静态服务类,提供番茄钟设置的存储和读取功能
  static const String _settingsKey = 'pomodoro_settings';

  // 保存设置方法
  static Future<void> saveSettings(PomodoroSettings settings) async {
    // 获取 SharedPreferences 实例
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJson().toString());

    // 同时单独保存每个值,方便快速访问
    await prefs.setInt('pomo_work_duration', settings.workDuration);
    await prefs.setInt('pomo_short_break', settings.shortBreakDuration);
    await prefs.setInt('pomo_long_break', settings.longBreakDuration);
    await prefs.setInt('pomo_until_long', settings.pomodorosUntilLongBreak);
  }

  // 加载设置的方法
  static Future<PomodoroSettings> loadSettings() async {
    // 异步读取存储设置
    final prefs = await SharedPreferences.getInstance();

    // 从各个键读取单独的值
    final workDuration = prefs.getInt('pomo_work_duration') ?? 25;
    final shortBreak = prefs.getInt('pomo_short_break') ?? 5;
    final longBreak = prefs.getInt('pomo_long_break') ?? 15;
    final untilLong = prefs.getInt('pomo_until_long') ?? 4;

    // 创建并返回PomodoroSettings对象
    return PomodoroSettings(
      workDuration: workDuration,
      shortBreakDuration: shortBreak,
      longBreakDuration: longBreak,
      pomodorosUntilLongBreak: untilLong,
    );
  }

  // 重置为默认设置
  static Future<void> resetToDefault() async {
    // 简单的调用saveSetting方法,传入默认设置
    await saveSettings(PomodoroSettings.defaultSettings);
  }

  // 设置验证方法
  static bool validateSettings(PomodoroSettings settings) {
    return settings.workDuration >= 5 && settings.workDuration <= 90 &&
        settings.shortBreakDuration >= 1 && settings.shortBreakDuration <= 15 &&
        settings.longBreakDuration >= 5 && settings.longBreakDuration <= 60 &&
        settings.pomodorosUntilLongBreak >= 2 && settings.pomodorosUntilLongBreak <= 10;
  }
}