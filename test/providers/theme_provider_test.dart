import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_time_manager/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 住测试函数
void main() {
  // 确保测试环境正确初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  // 测试组设置
  group('ThemeProvider Tests', () {
    // 延迟初始化的ThemeProvider变量
    late ThemeProvider themeProvider;

    // setUp函数在每个测试前运行,用于准备测试环境
    setUp(() async {
      // 每个测试前清空 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // 创建新的ThemeProvider实例
      themeProvider = ThemeProvider();
      // 等待初始加载完成
      await Future.delayed(const Duration(milliseconds: 100));
    });

    // 初始状态测试
    test('初始主题模式应该是系统模式', () {
      // 验证初始主题模式是系统模式（AppThemeMode是自定义枚举）
      expect(themeProvider.themeMode, AppThemeMode.system);
      // 验证actualThemeMode正确转换为Flutter的ThemeMode.system
      expect(themeProvider.actualThemeMode, ThemeMode.system);
      // 验证主题模式的文本描述正确
      expect(themeProvider.themeModeText, 'Follow System');
    });

    // 亮色主题测试
    test('设置亮色主题模式', () async {
      // 设置为亮色主题
      await themeProvider.setThemeMode(AppThemeMode.light);

      // 验证内存中的值
      expect(themeProvider.themeMode, AppThemeMode.light);
      expect(themeProvider.actualThemeMode, ThemeMode.light);
      expect(themeProvider.themeModeText, 'Light');

      // 验证是否保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_theme_mode'), 1); // AppThemeMode.light 的索引
    });

    // 暗色主题测试
    test('设置暗色主题模式', () async {
      // 设置为暗色主题
      await themeProvider.setThemeMode(AppThemeMode.dark);

      // 验证内存中的值
      expect(themeProvider.themeMode, AppThemeMode.dark);
      expect(themeProvider.actualThemeMode, ThemeMode.dark);
      expect(themeProvider.themeModeText, 'Dark');

      // 验证是否保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_theme_mode'), 2); // AppThemeMode.dark 的索引
    });

    // 系统主题模式测试
    test('设置系统主题模式', () async {
      // 先设置为暗色，然后改回系统
      await themeProvider.setThemeMode(AppThemeMode.dark);
      await themeProvider.setThemeMode(AppThemeMode.system);

      // 验证切换后的状态正确
      expect(themeProvider.themeMode, AppThemeMode.system);
      expect(themeProvider.actualThemeMode, ThemeMode.system);
      expect(themeProvider.themeModeText, 'Follow System');
    });

    // 持久化加载测试
    test('从 SharedPreferences 加载已保存的主题', () async {
      // 先设置一个主题并保存
      await themeProvider.setThemeMode(AppThemeMode.dark);

      // 创建新的provider实例（模拟应用重启）
      final newThemeProvider = ThemeProvider();

      // 等待加载完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证是否正确加载了保存的主题
      expect(newThemeProvider.themeMode, AppThemeMode.dark);
      expect(newThemeProvider.actualThemeMode, ThemeMode.dark);
    });

    // 监听器通知测试
    test('通知监听器主题变化', () async {
      int notificationCount = 0;

      // 添加监听器
      themeProvider.addListener(() {
        notificationCount++;
      });

      // 改变主题
      await themeProvider.setThemeMode(AppThemeMode.light);

      // 验证通知被触发
      expect(notificationCount, greaterThan(0));

      // 清理监听器
      themeProvider.removeListener(() {});
    });

    // 枚举转换测试
    test('actualThemeMode 转换正确', () {
      // 测试所有枚举值的转换
      themeProvider.setThemeMode(AppThemeMode.system);
      expect(themeProvider.actualThemeMode, ThemeMode.system);

      themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.actualThemeMode, ThemeMode.light);

      themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.actualThemeMode, ThemeMode.dark);
    });

    // 文本描述测试
    test('themeModeText 返回正确的文本', () {
      // 测试所有枚举值的文本
      themeProvider.setThemeMode(AppThemeMode.system);
      expect(themeProvider.themeModeText, 'Follow System');

      themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.themeModeText, 'Light');

      themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.themeModeText, 'Dark');
    });
  });
}