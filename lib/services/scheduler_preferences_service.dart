import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/scheduler_preferences.dart';

class SchedulerPreferencesService {
  static const String _prefsKey = 'scheduler_preferences';

  // Save preferences
  static Future<void> savePreferences(SchedulerPreferences prefs) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final json = jsonEncode(prefs.toJson());
    await sharedPrefs.setString(_prefsKey, json);
  }

  // Load preferences
  static Future<SchedulerPreferences> loadPreferences() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final jsonString = sharedPrefs.getString(_prefsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return SchedulerPreferences.fromJson(json);
      } catch (e) {
        // If parsing fails, return default
        return SchedulerPreferences.defaultPreferences;
      }
    }

    return SchedulerPreferences.defaultPreferences;
  }

  // Reset to default
  static Future<void> resetToDefault() async {
    await savePreferences(SchedulerPreferences.defaultPreferences);
  }

  // Apply preset
  static Future<void> applyPreset(String presetName) async {
    final preset = SchedulerPreferences.presets[presetName];
    if (preset != null) {
      await savePreferences(preset);
    }
  }
}