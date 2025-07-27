import 'package:flutter/material.dart';
import '../models/ai_preferences.dart';
import '../services/ai_preferences_service.dart';
import '../services/ai_service.dart';

class AISettingsDialog extends StatefulWidget {
  const AISettingsDialog({Key? key}) : super(key: key);

  @override
  State<AISettingsDialog> createState() => _AISettingsDialogState();
}

class _AISettingsDialogState extends State<AISettingsDialog> {
  late AIPreferences _preferences;
  final AITaskParser _aiParser = AITaskParser();
  String? _currentApiKey;
  bool _isLoading = true;
  bool _isSaving = false;
  int _monthlyApiCalls = 0;

  // 任务时长选项
  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120, 180];

  // 能量级别选项
  final Map<String, String> _energyLevels = {
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  // 专注度选项
  final Map<String, String> _focusLevels = {
    'deep': 'Deep',
    'medium': 'Medium',
    'light': 'Light',
  };

  // 时间选项
  final List<String> _timeOptions = ['09:00', '10:00', '14:00', '15:00'];

  // 星期选项
  final Map<String, String> _weekDays = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
  };

  // 工作时间偏好选项
  final Map<String, String> _workTimePreferences = {
    'morning': 'Morning Person (6:00-12:00)',
    'balanced': 'Balanced (9:00-17:00)',
    'night': 'Night Owl (14:00-22:00)',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _preferences = await AIPreferencesService.loadPreferences();
    _currentApiKey = await _aiParser.getApiKey();
    _monthlyApiCalls = await AIPreferencesService.getMonthlyApiCallCount();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    await AIPreferencesService.savePreferences(_preferences);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI settings saved')),
      );
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _currentApiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Claude API Key',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _aiParser.saveApiKey(controller.text);
                setState(() {
                  _currentApiKey = controller.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Assistant Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Configuration Section
                    _buildSectionTitle('API Configuration'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.key),
                              title: const Text('API Key'),
                              subtitle: Text(_currentApiKey != null && _currentApiKey!.isNotEmpty
                                  ? 'sk-ant-...${_currentApiKey!.substring(_currentApiKey!.length - 4)}'
                                  : 'Not configured'),
                              trailing: TextButton(
                                onPressed: _showApiKeyDialog,
                                child: const Text('Update'),
                              ),
                            ),
                            const Divider(),
                            // ===== 改动开始：修复Monthly Usage显示问题 =====
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.analytics),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Monthly Usage',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$_monthlyApiCalls API calls this month',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _preferences.lastApiCallTime != null
                                              ? 'Last used: ${_formatDate(_preferences.lastApiCallTime!)}'
                                              : 'Never used',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ===== 改动结束 =====
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Task Default Duration Section
                    _buildSectionTitle('Default Task Duration'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDurationSetting(
                              'Meeting/Call',
                              _preferences.meetingDefaultDuration,
                                  (value) => setState(() => _preferences = _preferences.copyWith(
                                meetingDefaultDuration: value,
                              )),
                            ),
                            const Divider(),
                            _buildDurationSetting(
                              'Creative Work',
                              _preferences.creativeDefaultDuration,
                                  (value) => setState(() => _preferences = _preferences.copyWith(
                                creativeDefaultDuration: value,
                              )),
                            ),
                            const Divider(),
                            _buildDurationSetting(
                              'Routine Task',
                              _preferences.routineDefaultDuration,
                                  (value) => setState(() => _preferences = _preferences.copyWith(
                                routineDefaultDuration: value,
                              )),
                            ),
                            const Divider(),
                            _buildDurationSetting(
                              'Analytical Work',
                              _preferences.analyticalDefaultDuration,
                                  (value) => setState(() => _preferences = _preferences.copyWith(
                                analyticalDefaultDuration: value,
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Task Default Attributes Section
                    _buildSectionTitle('Default Task Attributes'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTaskAttributeSection('Meeting/Call',
                              _preferences.meetingDefaultEnergy,
                              _preferences.meetingDefaultFocus,
                                  (energy) => setState(() => _preferences = _preferences.copyWith(
                                meetingDefaultEnergy: energy,
                              )),
                                  (focus) => setState(() => _preferences = _preferences.copyWith(
                                meetingDefaultFocus: focus,
                              )),
                            ),
                            const Divider(height: 32),
                            _buildTaskAttributeSection('Creative Work',
                              _preferences.creativeDefaultEnergy,
                              _preferences.creativeDefaultFocus,
                                  (energy) => setState(() => _preferences = _preferences.copyWith(
                                creativeDefaultEnergy: energy,
                              )),
                                  (focus) => setState(() => _preferences = _preferences.copyWith(
                                creativeDefaultFocus: focus,
                              )),
                            ),
                            const Divider(height: 32),
                            _buildTaskAttributeSection('Routine Task',
                              _preferences.routineDefaultEnergy,
                              _preferences.routineDefaultFocus,
                                  (energy) => setState(() => _preferences = _preferences.copyWith(
                                routineDefaultEnergy: energy,
                              )),
                                  (focus) => setState(() => _preferences = _preferences.copyWith(
                                routineDefaultFocus: focus,
                              )),
                            ),
                            const Divider(height: 32),
                            _buildTaskAttributeSection('Analytical Work',
                              _preferences.analyticalDefaultEnergy,
                              _preferences.analyticalDefaultFocus,
                                  (energy) => setState(() => _preferences = _preferences.copyWith(
                                analyticalDefaultEnergy: energy,
                              )),
                                  (focus) => setState(() => _preferences = _preferences.copyWith(
                                analyticalDefaultFocus: focus,
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time Parsing Preferences Section
                    _buildSectionTitle('Time Parsing Preferences'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '"Tomorrow" default time',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _preferences.tomorrowDefaultTime,
                                  items: _timeOptions.map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _preferences = _preferences.copyWith(
                                        tomorrowDefaultTime: value,
                                      ));
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '"Next week" default day',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _preferences.nextWeekDefaultDay,
                                  items: _weekDays.entries.map((entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _preferences = _preferences.copyWith(
                                        nextWeekDefaultDay: value,
                                      ));
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Work time preference',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...(_workTimePreferences.entries.map((entry) => RadioListTile<String>(
                                  title: Text(entry.value),
                                  value: entry.key,
                                  groupValue: _preferences.workTimePreference,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                                  dense: true,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _preferences = _preferences.copyWith(
                                        workTimePreference: value,
                                      ));
                                    }
                                  },
                                )).toList()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDurationSetting(String label, int currentValue, Function(int) onChanged) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<int>(
        value: currentValue,
        items: _durationOptions
            .where((duration) {
          // 根据任务类型过滤合适的时长选项
          if (label == 'Routine Task') {
            return duration <= 60;
          } else if (label == 'Creative Work') {
            return duration >= 60;
          }
          return true;
        })
            .map((duration) => DropdownMenuItem(
          value: duration,
          child: Text('$duration min'),
        ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildTaskAttributeSection(
      String taskType,
      String currentEnergy,
      String currentFocus,
      Function(String) onEnergyChanged,
      Function(String) onFocusChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taskType,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        // Energy Level
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Energy Level'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: _energyLevels.entries.map((entry) => ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                )).toList(),
                selected: {currentEnergy},
                onSelectionChanged: (selection) {
                  onEnergyChanged(selection.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Focus Level
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Level'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: _focusLevels.entries.map((entry) => ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                )).toList(),
                selected: {currentFocus},
                onSelectionChanged: (selection) {
                  onFocusChanged(selection.first);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== 改动开始：优化日期格式化函数 =====
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
// ===== 改动结束 =====
}