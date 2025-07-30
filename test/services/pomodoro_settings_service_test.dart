import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_time_manager/services/pomodoro_settings_service.dart';

// 主函数
void main() {
  group('PomodoroSettings Tests', () {
    group('Constructor and Default Settings', () {
      // 构造函数和默认设置测试
      test('should create settings with specified values', () {
        final settings = PomodoroSettings(
          workDuration: 30,
          shortBreakDuration: 7,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 3,
        );

        expect(settings.workDuration, equals(30));
        expect(settings.shortBreakDuration, equals(7));
        expect(settings.longBreakDuration, equals(20));
        expect(settings.pomodorosUntilLongBreak, equals(3));
      });

      // 验证默认设置
      test('should provide correct default settings', () {
        final defaultSettings = PomodoroSettings.defaultSettings;

        expect(defaultSettings.workDuration, equals(25));
        expect(defaultSettings.shortBreakDuration, equals(5));
        expect(defaultSettings.longBreakDuration, equals(15));
        expect(defaultSettings.pomodorosUntilLongBreak, equals(4));
      });
    });

    // 预设模式测试
    group('Presets', () {
      // 经典模式
      test('should provide classic preset', () {
        final classic = PomodoroSettings.presets['classic']!;

        expect(classic.workDuration, equals(25));
        expect(classic.shortBreakDuration, equals(5));
        expect(classic.longBreakDuration, equals(15));
        expect(classic.pomodorosUntilLongBreak, equals(4));
      });

      // 短专注模式
      test('should provide short focus preset', () {
        final shortFocus = PomodoroSettings.presets['short_focus']!;

        expect(shortFocus.workDuration, equals(15));
        expect(shortFocus.shortBreakDuration, equals(3));
        expect(shortFocus.longBreakDuration, equals(10));
        expect(shortFocus.pomodorosUntilLongBreak, equals(4));
      });

      // 深度工作模式
      test('should provide deep work preset', () {
        final deepWork = PomodoroSettings.presets['deep_work']!;

        expect(deepWork.workDuration, equals(45));
        expect(deepWork.shortBreakDuration, equals(10));
        expect(deepWork.longBreakDuration, equals(30));
        expect(deepWork.pomodorosUntilLongBreak, equals(3));
      });

      // 验证是否有所有预设
      test('should have all expected presets', () {
        expect(PomodoroSettings.presets.keys, containsAll(['classic', 'short_focus', 'deep_work']));
        expect(PomodoroSettings.presets.length, equals(3));
      });
    });

    // 序列化测试
    group('Serialization', () {
      // toJson测试
      test('toJson should convert settings to map correctly', () {
        final settings = PomodoroSettings(
          workDuration: 30,
          shortBreakDuration: 7,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 3,
        );

        final json = settings.toJson();

        // 测试将设置对象转换为JSON格式
        expect(json['workDuration'], equals(30));
        expect(json['shortBreakDuration'], equals(7));
        expect(json['longBreakDuration'], equals(20));
        expect(json['pomodorosUntilLongBreak'], equals(3));
      });

      // fromJson测试
      test('fromJson should create settings from map correctly', () {
        final json = {
          'workDuration': 35,
          'shortBreakDuration': 8,
          'longBreakDuration': 25,
          'pomodorosUntilLongBreak': 5,
        };

        final settings = PomodoroSettings.fromJson(json);

        // 测试从JSON创建设置对象
        expect(settings.workDuration, equals(35));
        expect(settings.shortBreakDuration, equals(8));
        expect(settings.longBreakDuration, equals(25));
        expect(settings.pomodorosUntilLongBreak, equals(5));
      });

      // 测试如何处理缺失字段
      test('fromJson should use default values for missing fields', () {
        final json = <String, dynamic>{};

        final settings = PomodoroSettings.fromJson(json);

        // 空JSON应该返回默认值
        expect(settings.workDuration, equals(25));
        expect(settings.shortBreakDuration, equals(5));
        expect(settings.longBreakDuration, equals(15));
        expect(settings.pomodorosUntilLongBreak, equals(4));
      });

      // 验证处理部分数据
      test('fromJson should handle partial data', () {
        final json = {
          'workDuration': 40,
          'shortBreakDuration': null,
          // Missing other fields
        };

        final settings = PomodoroSettings.fromJson(json);

        // 部分字段缺失时,使用提供的值和默认值组合
        expect(settings.workDuration, equals(40));
        expect(settings.shortBreakDuration, equals(5));
        expect(settings.longBreakDuration, equals(15));
        expect(settings.pomodorosUntilLongBreak, equals(4));
      });
    });

    // copyWith方法测试
    group('copyWith', () {
      // 测试copyWith创建新实例
      test('should create new instance with updated values', () {
        final original = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 15,
          pomodorosUntilLongBreak: 4,
        );

        final updated = original.copyWith(
          workDuration: 30,
          longBreakDuration: 20,
        );

        // 验证修改的值
        expect(updated.workDuration, equals(30));
        expect(updated.longBreakDuration, equals(20));

        // 验证不变的值
        expect(updated.shortBreakDuration, equals(5));
        expect(updated.pomodorosUntilLongBreak, equals(4));

        // 验证原始数据没有改变
        expect(original.workDuration, equals(25));
        expect(original.longBreakDuration, equals(15));
      });

      // 验证在没有数值提供的时候返回默认数据
      test('should return identical copy when no parameters provided', () {
        final original = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 15,
          pomodorosUntilLongBreak: 4,
        );

        final copy = original.copyWith();

        expect(copy.workDuration, equals(original.workDuration));
        expect(copy.shortBreakDuration, equals(original.shortBreakDuration));
        expect(copy.longBreakDuration, equals(original.longBreakDuration));
        expect(copy.pomodorosUntilLongBreak, equals(original.pomodorosUntilLongBreak));
      });
    });
  });

  // PomodoroSettingsService服务测试
  group('PomodoroSettingsService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // 保存和加载测试
    group('saveSettings and loadSettings', () {
      // 测试完整的保存和加载流程
      test('should save and load settings correctly', () async {
        final settings = PomodoroSettings(
          workDuration: 30,
          shortBreakDuration: 7,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 3,
        );

        // 保存设置
        await PomodoroSettingsService.saveSettings(settings);

        // 加载设置
        final loadedSettings = await PomodoroSettingsService.loadSettings();

        expect(loadedSettings.workDuration, equals(30));
        expect(loadedSettings.shortBreakDuration, equals(7));
        expect(loadedSettings.longBreakDuration, equals(20));
        expect(loadedSettings.pomodorosUntilLongBreak, equals(3));
      });

      // 验证单独的键
      test('should save individual preference keys', () async {
        final settings = PomodoroSettings(
          workDuration: 35,
          shortBreakDuration: 8,
          longBreakDuration: 25,
          pomodorosUntilLongBreak: 5,
        );

        await PomodoroSettingsService.saveSettings(settings);

        // 验证单独的键被正确加入
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('pomo_work_duration'), equals(35));
        expect(prefs.getInt('pomo_short_break'), equals(8));
        expect(prefs.getInt('pomo_long_break'), equals(25));
        expect(prefs.getInt('pomo_until_long'), equals(5));
      });

      // 验证在没有保存数据是返回默认数据
      test('should return default settings when no saved data exists', () async {
        // 不保存,只加载
        final loadedSettings = await PomodoroSettingsService.loadSettings();

        expect(loadedSettings.workDuration, equals(25));
        expect(loadedSettings.shortBreakDuration, equals(5));
        expect(loadedSettings.longBreakDuration, equals(15));
        expect(loadedSettings.pomodorosUntilLongBreak, equals(4));
      });

      // 验证独立属性是否可以独立保存
      test('should handle partial saved data', () async {
        // 只保存一些值
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('pomo_work_duration', 40);
        await prefs.setInt('pomo_short_break', 10);
        // 不保存其他值

        final loadedSettings = await PomodoroSettingsService.loadSettings();

        expect(loadedSettings.workDuration, equals(40));
        expect(loadedSettings.shortBreakDuration, equals(10));
        expect(loadedSettings.longBreakDuration, equals(15)); // Default
        expect(loadedSettings.pomodorosUntilLongBreak, equals(4)); // Default
      });
    });

    group('resetToDefault', () {
      // 重置功能测试
      test('should reset settings to default values', () async {
        // 第一次保存自定义设置
        final customSettings = PomodoroSettings(
          workDuration: 40,
          shortBreakDuration: 10,
          longBreakDuration: 30,
          pomodorosUntilLongBreak: 6,
        );
        await PomodoroSettingsService.saveSettings(customSettings);

        // 验证自定义设置是否可以保存
        var loadedSettings = await PomodoroSettingsService.loadSettings();
        expect(loadedSettings.workDuration, equals(40));

        // 验证是否可以转回默认
        await PomodoroSettingsService.resetToDefault();

        // 验证设置返回默认
        loadedSettings = await PomodoroSettingsService.loadSettings();
        expect(loadedSettings.workDuration, equals(25));
        expect(loadedSettings.shortBreakDuration, equals(5));
        expect(loadedSettings.longBreakDuration, equals(15));
        expect(loadedSettings.pomodorosUntilLongBreak, equals(4));
      });
    });

    // 设置验证测试
    group('validateSettings', () {
      // 有效设置
      test('should validate correct settings', () {
        final validSettings = PomodoroSettings(
          workDuration: 30,
          shortBreakDuration: 5,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 4,
        );

        // 验证合理的设置应该通过验证
        expect(PomodoroSettingsService.validateSettings(validSettings), isTrue);
      });

      // 工作时长验证
      // 验证是否可以驳回过短的时间
      test('should reject settings with work duration too short', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 4,
          shortBreakDuration: 5,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 验证是否可以驳回过长的时间
      test('should reject settings with work duration too long', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 91,
          shortBreakDuration: 5,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 同上
      test('should reject settings with short break too short', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 0,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 同上
      test('should reject settings with short break too long', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 16,
          longBreakDuration: 20,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 同上
      test('should reject settings with long break too short', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 4,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 同上
      test('should reject settings with long break too long', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 61,
          pomodorosUntilLongBreak: 4,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      test('should reject settings with too few pomodoros until long break', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 15,
          pomodorosUntilLongBreak: 1,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      test('should reject settings with too many pomodoros until long break', () {
        final invalidSettings = PomodoroSettings(
          workDuration: 25,
          shortBreakDuration: 5,
          longBreakDuration: 15,
          pomodorosUntilLongBreak: 11,
        );

        expect(PomodoroSettingsService.validateSettings(invalidSettings), isFalse);
      });

      // 边界值测试
      test('should validate edge case values', () {
        // 测试最小有效值
        final minSettings = PomodoroSettings(
          workDuration: 5,
          shortBreakDuration: 1,
          longBreakDuration: 5,
          pomodorosUntilLongBreak: 2,
        );
        // 测试最小和最大的有效值
        expect(PomodoroSettingsService.validateSettings(minSettings), isTrue);

        // 测试最大有效值
        final maxSettings = PomodoroSettings(
          workDuration: 90,
          shortBreakDuration: 15,
          longBreakDuration: 60,
          pomodorosUntilLongBreak: 10,
        );
        expect(PomodoroSettingsService.validateSettings(maxSettings), isTrue);
      });
    });

    // 集成测试
    group('Integration Tests', () {
      // 测试完整工作流程
      test('should handle complete workflow with presets', () async {
        // 1. 开始默认设置
        var settings = await PomodoroSettingsService.loadSettings();
        expect(settings.workDuration, equals(25));

        // 2. 应用预设
        final deepWorkPreset = PomodoroSettings.presets['deep_work']!;
        await PomodoroSettingsService.saveSettings(deepWorkPreset);

        // 3. 验证预设已经保存
        settings = await PomodoroSettingsService.loadSettings();
        expect(settings.workDuration, equals(45));
        expect(settings.shortBreakDuration, equals(10));

        // 4. 修改预设
        final modified = settings.copyWith(workDuration: 50);
        await PomodoroSettingsService.saveSettings(modified);

        // 5. 验证预设
        settings = await PomodoroSettingsService.loadSettings();
        expect(settings.workDuration, equals(50));
        expect(settings.shortBreakDuration, equals(10)); // Unchanged

        // 6. 验证之前的设置
        expect(PomodoroSettingsService.validateSettings(settings), isTrue);

        // 7. 重置为默认
        await PomodoroSettingsService.resetToDefault();
        settings = await PomodoroSettingsService.loadSettings();
        expect(settings.workDuration, equals(25));
      });

      // 数据完整性测试
      test('should maintain data integrity across save/load cycles', () async {
        final originalSettings = PomodoroSettings(
          workDuration: 33,
          shortBreakDuration: 7,
          longBreakDuration: 22,
          pomodorosUntilLongBreak: 5,
        );

        // 多次保存和加载,验证数据不会损坏
        for (int i = 0; i < 5; i++) {
          await PomodoroSettingsService.saveSettings(originalSettings);
          final loaded = await PomodoroSettingsService.loadSettings();

          expect(loaded.workDuration, equals(33));
          expect(loaded.shortBreakDuration, equals(7));
          expect(loaded.longBreakDuration, equals(22));
          expect(loaded.pomodorosUntilLongBreak, equals(5));
        }
      });
    });
  });
}