import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/scheduler_preferences.dart';

// 定义纯静态方法的服务类
class SchedulerPreferencesService {
  // _prefsKey:存储在SharedPreferences中的键名常量,用于标识调度器偏好设置
  static const String _prefsKey = 'scheduler_preferences';

  // 保存偏好设置方法
  static Future<void> savePreferences(SchedulerPreferences prefs) async {
    // 获取SharedPreferences单例实例
    final sharedPrefs = await SharedPreferences.getInstance();
    // 先将对象转换为Map,再把map转换为json字符串
    final json = jsonEncode(prefs.toJson());
    // 将json字符串存储到本地
    await sharedPrefs.setString(_prefsKey, json);
  }

  // 加载偏好设置方法
  static Future<SchedulerPreferences> loadPreferences() async {
    // 获取SharedPreferences单例实例
    final sharedPrefs = await SharedPreferences.getInstance();
    // 尝试读取存储的json字符串
    final jsonString = sharedPrefs.getString(_prefsKey);

    if (jsonString != null) {
      // 如果存在已保存的数据,尝试解析json并创建对象
      try {
        final json = jsonDecode(jsonString);
        return SchedulerPreferences.fromJson(json);
      } catch (e) {
        // 如果解析失败,返回默认值
        return SchedulerPreferences.defaultPreferences;
      }
    }

    return SchedulerPreferences.defaultPreferences;
  }

  // 重置为默认设置
  static Future<void> resetToDefault() async {
    // 直接调用savePreferences方法,传入默认偏好设置
    await savePreferences(SchedulerPreferences.defaultPreferences);
  }

  // 应用预设配置
  static Future<void> applyPreset(String presetName) async {
    // presetName：预设配置的名称
    final preset = SchedulerPreferences.presets[presetName];
    if (preset != null) {
      await savePreferences(preset);
    }
  }
}