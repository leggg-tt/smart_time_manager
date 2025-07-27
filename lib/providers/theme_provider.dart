import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义主题模式枚举
// system：跟随系统主题（系统是暗色就暗色，系统是亮色就亮色）
// light：强制使用亮色主题
// dark：强制使用暗色主题
enum AppThemeMode { system, light, dark }

// 创建ThemeProvider状态管理基类
class ThemeProvider extends ChangeNotifier {
  // 用于在SharedPreferences中存储主题设置的键名
  static const String _themeKey = 'app_theme_mode';

  // _themeMode：私有变量,存储当前主题模式,默认跟随系统
  AppThemeMode _themeMode = AppThemeMode.system;

  // themeMode：公开的getter,外部通过它读取当前主题模式
  AppThemeMode get themeMode => _themeMode;

  // 构造函数,创建实例时自动调用_loadTheme()
  ThemeProvider() {
    _loadTheme();
  }

  // 加载主题设置
  Future<void> _loadTheme() async {
    // 获取SharedPreferences实例
    final prefs = await SharedPreferences.getInstance();
    // 读取存储的主题索引,如果没有则默认为0（system模式）
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    // 通过索引从枚举值数组中获取对应的主题模式
    _themeMode = AppThemeMode.values[themeIndex];
    // 通知所有监听者主题已更新
    notifyListeners();
  }

  // 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    // 更新内存中的主题模式
    _themeMode = mode;
    // 获取SharedPreferences实例
    final prefs = await SharedPreferences.getInstance();
    // 将新主题模式的索引保存到本地
    await prefs.setInt(_themeKey, mode.index);
    // 通知监听者更新UI
    notifyListeners();
  }

  // 获取Flutter主题模式
  ThemeMode get actualThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // 获取主题模式文本描述
  String get themeModeText {
    switch (_themeMode) {
      case AppThemeMode.system:
        return 'Follow System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}