import 'package:shared_preferences/shared_preferences.dart';

class PomodoroSettings {
  final int workDuration;      // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration;  // in minutes
  final int pomodorosUntilLongBreak;

  PomodoroSettings({
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.pomodorosUntilLongBreak,
  });

  // Default settings
  static PomodoroSettings get defaultSettings => PomodoroSettings(
    workDuration: 25,
    shortBreakDuration: 5,
    longBreakDuration: 15,
    pomodorosUntilLongBreak: 4,
  );

  // Preset templates
  static final Map<String, PomodoroSettings> presets = {
    'classic': PomodoroSettings(
      workDuration: 25,
      shortBreakDuration: 5,
      longBreakDuration: 15,
      pomodorosUntilLongBreak: 4,
    ),
    'short_focus': PomodoroSettings(
      workDuration: 15,
      shortBreakDuration: 3,
      longBreakDuration: 10,
      pomodorosUntilLongBreak: 4,
    ),
    'deep_work': PomodoroSettings(
      workDuration: 45,
      shortBreakDuration: 10,
      longBreakDuration: 30,
      pomodorosUntilLongBreak: 3,
    ),
  };

  Map<String, dynamic> toJson() => {
    'workDuration': workDuration,
    'shortBreakDuration': shortBreakDuration,
    'longBreakDuration': longBreakDuration,
    'pomodorosUntilLongBreak': pomodorosUntilLongBreak,
  };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) => PomodoroSettings(
    workDuration: json['workDuration'] ?? 25,
    shortBreakDuration: json['shortBreakDuration'] ?? 5,
    longBreakDuration: json['longBreakDuration'] ?? 15,
    pomodorosUntilLongBreak: json['pomodorosUntilLongBreak'] ?? 4,
  );

  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? pomodorosUntilLongBreak,
  }) => PomodoroSettings(
    workDuration: workDuration ?? this.workDuration,
    shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
    longBreakDuration: longBreakDuration ?? this.longBreakDuration,
    pomodorosUntilLongBreak: pomodorosUntilLongBreak ?? this.pomodorosUntilLongBreak,
  );
}

class PomodoroSettingsService {
  static const String _settingsKey = 'pomodoro_settings';

  // Save settings
  static Future<void> saveSettings(PomodoroSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJson().toString());

    // Save individual values for easier access
    await prefs.setInt('pomo_work_duration', settings.workDuration);
    await prefs.setInt('pomo_short_break', settings.shortBreakDuration);
    await prefs.setInt('pomo_long_break', settings.longBreakDuration);
    await prefs.setInt('pomo_until_long', settings.pomodorosUntilLongBreak);
  }

  // Load settings
  static Future<PomodoroSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final workDuration = prefs.getInt('pomo_work_duration') ?? 25;
    final shortBreak = prefs.getInt('pomo_short_break') ?? 5;
    final longBreak = prefs.getInt('pomo_long_break') ?? 15;
    final untilLong = prefs.getInt('pomo_until_long') ?? 4;

    return PomodoroSettings(
      workDuration: workDuration,
      shortBreakDuration: shortBreak,
      longBreakDuration: longBreak,
      pomodorosUntilLongBreak: untilLong,
    );
  }

  // Reset to default
  static Future<void> resetToDefault() async {
    await saveSettings(PomodoroSettings.defaultSettings);
  }

  // Validate settings
  static bool validateSettings(PomodoroSettings settings) {
    return settings.workDuration >= 5 && settings.workDuration <= 90 &&
        settings.shortBreakDuration >= 1 && settings.shortBreakDuration <= 15 &&
        settings.longBreakDuration >= 5 && settings.longBreakDuration <= 60 &&
        settings.pomodorosUntilLongBreak >= 2 && settings.pomodorosUntilLongBreak <= 10;
  }
}