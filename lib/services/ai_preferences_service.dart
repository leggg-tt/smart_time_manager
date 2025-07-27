import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ai_preferences.dart';

// AIPreferencesService服务类定义
class AIPreferencesService {
  // 存储键名常量,用于SharedPreferences
  static const String _prefsKey = 'ai_preferences';

  // 保存AI偏好设置
  static Future<void> savePreferences(AIPreferences prefs) async {
    // 获取SharedPreferences实例
    final sharedPrefs = await SharedPreferences.getInstance();
    // 将AIPreferences对象转换为JSON字符串
    final json = jsonEncode(prefs.toJson());
    // 以字符串形式存储到本地
    await sharedPrefs.setString(_prefsKey, json);
  }

  // 加载AI偏好设置
  static Future<AIPreferences> loadPreferences() async {
    // 获取SharedPreferences实例
    final sharedPrefs = await SharedPreferences.getInstance();
    // 读取存储的JSON字符串
    final jsonString = sharedPrefs.getString(_prefsKey);

    // 如果存在数据：
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        // 尝试解码JSON并创建AIPreferences对象
        return AIPreferences.fromJson(json);
      } catch (e) {
        // 如果解析失败（数据损坏等）,返回默认设置
        return AIPreferences.defaultPreferences;
      }
    }

    return AIPreferences.defaultPreferences;
  }

  // 更新API调用统计
  static Future<void> incrementApiCallCount() async {
    // 加载当前设置
    final currentPrefs = await loadPreferences();

    // 使用copyWith创建新对象,API调用次数加1,更新最后调用时间为当前时间
    final updatedPrefs = currentPrefs.copyWith(
      apiCallCount: currentPrefs.apiCallCount + 1,
      lastApiCallTime: DateTime.now(),
    );

    // 保存更新后的设置
    await savePreferences(updatedPrefs);
  }

  // 获取本月API调用次数
  static Future<int> getMonthlyApiCallCount() async {
    // 加载偏好设置
    final prefs = await loadPreferences();

    // 如果从未调用过API,返回0
    if (prefs.lastApiCallTime == null) {
      return 0;
    }

    // 比较最后调用时间与当前时间
    final now = DateTime.now();
    final lastCall = prefs.lastApiCallTime!;

    // 如果最后调用不是本月,重置计数
    if (lastCall.year != now.year || lastCall.month != now.month) {
      await savePreferences(prefs.copyWith(apiCallCount: 0));
      return 0;
    }

    return prefs.apiCallCount;
  }

  // 重置为默认设置
  static Future<void> resetToDefault() async {
    // 直接保存默认设置,覆盖现有数据
    await savePreferences(AIPreferences.defaultPreferences);
  }

  // 测试 API 连接
  // 暂未实现,感觉意义不大
  static Future<bool> testApiConnection(String apiKey) async {
    // 这里可以实现一个简单的 API 测试请求
    // 暂时返回 true，实际实现时可以发送一个测试请求
    return apiKey.isNotEmpty && apiKey.startsWith('sk-ant-');
  }
}