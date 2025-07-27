import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<AppThemeMode>(
            title: const Text('Follow System'),
            subtitle: const Text('Automatically match system theme'),
            value: AppThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
          ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}