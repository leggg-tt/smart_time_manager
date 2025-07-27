import 'package:flutter/material.dart';
import '../models/ai_preferences.dart';
import '../services/ai_preferences_service.dart';
import '../services/ai_service.dart';

// 定义有状态组件,因为这个对话框需要管理用户输入和状态变化
class AISettingsDialog extends StatefulWidget {
  const AISettingsDialog({Key? key}) : super(key: key);

  @override
  State<AISettingsDialog> createState() => _AISettingsDialogState();
}

// 状态变量定义
class _AISettingsDialogState extends State<AISettingsDialog> {
  // late表示稍后初始化
  late AIPreferences _preferences;  // 存储AI偏好设置
  final AITaskParser _aiParser = AITaskParser();  // AI任务解析器实例
  String? _currentApiKey;  // 当前的API密钥
  bool _isLoading = true;  // 加载状态标志
  bool _isSaving = false;  // 保存状态标志
  int _monthlyApiCalls = 0;  // 本月API调用次数

  // 任务时长选项
  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120, 180];

  // 能量级别选项(键是存储值,值是显示文本)
  final Map<String, String> _energyLevels = {
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  // 专注度选项(同上)
  final Map<String, String> _focusLevels = {
    'deep': 'Deep',
    'medium': 'Medium',
    'light': 'Light',
  };

  // 时间选项
  final List<String> _timeOptions = ['09:00', '10:00', '14:00', '15:00'];

  // 星期选项(这里只提供了周一到周三,后期根据用户反馈去做调整)
  final Map<String, String> _weekDays = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
  };

  // 工作时间偏好选项(三种不同工作类型)
  final Map<String, String> _workTimePreferences = {
    'morning': 'Morning Person (6:00-12:00)',
    'balanced': 'Balanced (9:00-17:00)',
    'night': 'Night Owl (14:00-22:00)',
  };

  // 初始化方法：组件创建时立即加载数据
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 异步加载数据
  Future<void> _loadData() async {
    // 从服务加载AI偏好设置
    _preferences = await AIPreferencesService.loadPreferences();
    // 获取当前API密钥
    _currentApiKey = await _aiParser.getApiKey();
    // 获取本月API调用次数
    _monthlyApiCalls = await AIPreferencesService.getMonthlyApiCallCount();

    // 更新UI状态,结束加载
    setState(() {
      _isLoading = false;
    });
  }

  // 保存设置方法
  Future<void> _saveSettings() async {
    // 设置保存状态为true
    setState(() {
      _isSaving = true;
    });

    // 异步调用服务保存偏好设置
    await AIPreferencesService.savePreferences(_preferences);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      // 关闭对话框并显示成功提示
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI settings saved')),
      );
    }
  }

  // API密钥更新对话框
  void _showApiKeyDialog() {
    // 创建文本控制器,预填充当前密钥
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
              // 使用obscureText:true隐藏输入内容
              obscureText: true,
            ),
          ],
        ),
        // 对话框操作按钮
        actions: [
          TextButton(
            // 取消按钮,直接关闭对话框
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            // 保存按钮
            onPressed: () async {
              // 验证非空后保存密钥并更新状态
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

  // 构建UI
  @override
  Widget build(BuildContext context) {
    // 数据未加载完成时显示加载指示器
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 主对话框结构
    return Dialog(
      child: Container(
        // 限制最大宽度600和高度700
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        // 垂直布局
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // 使用主题色作为背景
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                // 显示AI图标和标题
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
                    // API配置部分
                    _buildSectionTitle('API Configuration'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.key),
                              title: const Text('API Key'),
                              // 显示API密钥状态,为了安全只展示后四位
                              subtitle: Text(_currentApiKey != null && _currentApiKey!.isNotEmpty
                                  ? 'sk-ant-...${_currentApiKey!.substring(_currentApiKey!.length - 4)}'
                                  : 'Not configured'),
                              trailing: TextButton(
                                // 更新按钮
                                onPressed: _showApiKeyDialog,
                                child: const Text('Update'),
                              ),
                            ),
                            const Divider(),
                            // Monthly Usage显示
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.analytics),
                                  const SizedBox(width: 16),
                                  // 使用Expanded确保文本不会溢出
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
                                        // 显示本月API调用次数
                                        Text(
                                          '$_monthlyApiCalls API calls this month',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          // 显示最后使用时间
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 任务默认时长设置
                    _buildSectionTitle('Default Task Duration'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          // 为不同类型的任务设置默认时长
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

                    // 任务默认属性部分
                    _buildSectionTitle('Default Task Attributes'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          // 为不同类型的任务设置默认属性
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

                    // 时间解析首选项部分
                    _buildSectionTitle('Time Parsing Preferences'),
                    // 容器结构
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // "明天"默认时间设置
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
                                // 下拉选择器
                                DropdownButton<String>(
                                  // 当前值绑定到_preferences.tomorrowDefaultTime
                                  value: _preferences.tomorrowDefaultTime,
                                  // 选项来自_timeOptions
                                  items: _timeOptions.map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      // 选择后更新偏好设置
                                      setState(() => _preferences = _preferences.copyWith(
                                        tomorrowDefaultTime: value,
                                      ));
                                    }
                                  },
                                ),
                              ],
                            ),
                            // 同上,但是时下周
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
                                // 星期选择器
                                DropdownButton<String>(
                                  value: _preferences.nextWeekDefaultDay,
                                  // 使用entries.map遍历键值对
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
                            // 工作时间偏好标题
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
                                // RadioListTile创建单选按钮列表项
                                ...(_workTimePreferences.entries.map((entry) => RadioListTile<String>(
                                  title: Text(entry.value),
                                  value: entry.key,
                                  // groupValue绑定当前选中值
                                  groupValue: _preferences.workTimePreference,
                                  // contentPadding设为0以去除默认内边距
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                                  // dense:true使列表项更紧凑
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
            // 操作按钮区域
            Container(
              // 四周16像素内边距
              padding: const EdgeInsets.all(16),
              // 装饰容器
              decoration: BoxDecoration(
                // 只在顶部添加边框线
                border: Border(
                  top: BorderSide(
                    // 使用主题定义的分割线颜色
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              // 水平排列按钮
              child: Row(
                // 按钮靠右对齐
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    // 取消按钮
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    // 保存按钮
                    // 保存中：禁用按钮
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                    // 保存中：显示加载指示器
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

  // 构建章节标题方法
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

  // 构建时长设置项
  // 值改变时回调函数
  Widget _buildDurationSetting(String label, int currentValue, Function(int) onChanged) {
    return ListTile(
      title: Text(label),  // 任务类型名称
      trailing: DropdownButton<int>(
        value: currentValue,  // 当前选中的时长值
        items: _durationOptions
            .where((duration) {
          // 根据任务类型过滤合适的时长选项
          // 不知道这种预设是否合理,根据后期实验来判断是否调整
          if (label == 'Routine Task') {
            return duration <= 60;  // 日常任务最多60分钟
          } else if (label == 'Creative Work') {
            return duration >= 60;  //  创意工作至少60分钟
          }
          return true;
        })
            .map((duration) => DropdownMenuItem(
          value: duration,
          child: Text('$duration min'),  // 显示格式
        ))
            .toList(),
        onChanged: (value) {
          // 检查新值非空
          if (value != null) {
            // 调用传入的回调函数更新状态
            onChanged(value);
          }
        },
      ),
    );
  }

  // 构建任务属性设置区
  Widget _buildTaskAttributeSection(
      String taskType,  // 任务类型标题
      String currentEnergy,  // 当前能量级别
      String currentFocus,  // 当前专注度
      Function(String) onEnergyChanged,  // 能量级别变更回调
      Function(String) onFocusChanged,  // 专注度变更回调
      ) {
    // 垂直布局
    return Column(
      // 左对齐
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
              // 按钮组占满宽度
              width: double.infinity,
              // 分段按钮
              child: SegmentedButton<String>(
                segments: _energyLevels.entries.map((entry) => ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                )).toList(),
                // 使用Set表示选中项
                selected: {currentEnergy},
                onSelectionChanged: (selection) {
                  onEnergyChanged(selection.first);
                },
              ),
            ),
          ],
        ),
        // 同上
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

  // 优化日期格式化函数
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';  // 1分钟内
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';  // 1小时内显示分钟
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';  // 1天内显示小时
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';  // 7天内显示天数
    } else {
      return '${date.month}/${date.day}';  // 超过7天显示具体日期
    }
  }
}