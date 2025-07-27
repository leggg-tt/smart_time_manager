import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// 定义ThemeSelectorDialog无状态组件
class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  // 构建方法
  @override
  Widget build(BuildContext context) {
    // 监听ThemeProvider的变化,当主题改变时,这个组件会自动重建
    final themeProvider = context.watch<ThemeProvider>();

    // 创建选择主题对话框
    return AlertDialog(
      // 标题显示
      title: const Text('Choose Theme'),
      // 垂直排列
      content: Column(
        // 让Column只占用必要的高度
        mainAxisSize: MainAxisSize.min,
        children: [
          // 带标题和副标题的单选按钮
          RadioListTile<AppThemeMode>(
            // 主题
            title: const Text('Follow System'),
            // 说明文字
            subtitle: const Text('Automatically match system theme'),
            value: AppThemeMode.system,
            groupValue: themeProvider.themeMode,
            // 检查value不为null,调用provider的setThemeMode更新主题,关闭对话框
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
          ),
          // 第二个单选项 - 亮色主题
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            subtitle: const Text('Always use light theme'),
            value: AppThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
          ),
          // 第三个单选项 - 暗色主题
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            subtitle: const Text('Always use dark theme'),
            value: AppThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      // 取消按钮,点击关闭
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}