import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ai_preferences.dart';

class AIPreferencesService {
  static const String _prefsKey = 'ai_preferences';

  // 保存 AI 偏好设置
  static Future<void> savePreferences(AIPreferences prefs) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final json = jsonEncode(prefs.toJson());
    await sharedPrefs.setString(_prefsKey, json);
  }

  // 加载 AI 偏好设置
  static Future<AIPreferences> loadPreferences() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final jsonString = sharedPrefs.getString(_prefsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return AIPreferences.fromJson(json);
      } catch (e) {
        return AIPreferences.defaultPreferences;
      }
    }

    return AIPreferences.defaultPreferences;
  }

  // 更新 API 调用统计
  static Future<void> incrementApiCallCount() async {
    final currentPrefs = await loadPreferences();

    final updatedPrefs = currentPrefs.copyWith(
      apiCallCount: currentPrefs.apiCallCount + 1,
      lastApiCallTime: DateTime.now(),
    );

    await savePreferences(updatedPrefs);
  }

  // 获取本月 API 调用次数
  static Future<int> getMonthlyApiCallCount() async {
    final prefs = await loadPreferences();

    if (prefs.lastApiCallTime == null) {
      return 0;
    }

    final now = DateTime.now();
    final lastCall = prefs.lastApiCallTime!;

    // 如果最后调用不是本月，重置计数
    if (lastCall.year != now.year || lastCall.month != now.month) {
      await savePreferences(prefs.copyWith(apiCallCount: 0));
      return 0;
    }

    return prefs.apiCallCount;
  }

  // 重置为默认设置
  static Future<void> resetToDefault() async {
    await savePreferences(AIPreferences.defaultPreferences);
  }

  // 测试 API 连接
  static Future<bool> testApiConnection(String apiKey) async {
    // 这里可以实现一个简单的 API 测试请求
    // 暂时返回 true，实际实现时可以发送一个测试请求
    return apiKey.isNotEmpty && apiKey.startsWith('sk-ant-');
  }
}