import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/enums.dart';

class AITaskParser {
  static const String _apiKeyPref = 'claude_api_key';
  String? _apiKey;

  // 获取存储的 API Key
  Future<String?> getApiKey() async {
    if (_apiKey != null) return _apiKey;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);
    return _apiKey;
  }

  // 保存 API Key
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _apiKey = apiKey;
  }

  // 解析语音输入并创建任务
  Future<ParsedTaskData?> parseVoiceInput(String voiceText) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先设置 Claude API Key');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': '''
请将以下语音输入解析为结构化的任务数据。返回 JSON 格式，不要包含其他内容。

语音输入："$voiceText"

当前时间：${DateTime.now().toIso8601String()}

请返回以下格式的 JSON：
{
  "title": "任务标题",
  "description": "任务描述（可选）",
  "durationMinutes": 60,
  "priority": "high/medium/low",
  "energyRequired": "high/medium/low", 
  "focusRequired": "deep/medium/light",
  "taskCategory": "creative/analytical/routine/communication",
  "deadline": "YYYY-MM-DD（可选）",
  "suggestedDate": "YYYY-MM-DD（建议安排的日期）",
  "suggestedTime": "HH:mm（建议安排的时间）"
}

解析规则：
1. 如果没有明确说明时长，根据任务类型推测合理时长
2. 如果没有说明优先级，根据语气和截止时间判断
3. 根据任务内容推断合适的类别、能量和专注度需求
4. 如果提到"明天"、"后天"等相对时间，转换为具体日期
5. 如果没有提到具体时间，根据任务类型推荐合适的时间段
'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];

        // 提取 JSON 部分
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final taskData = jsonDecode(jsonStr);
          return ParsedTaskData.fromJson(taskData);
        }
      }

      throw Exception('API 请求失败: ${response.statusCode}');
    } catch (e) {
      print('AI 解析错误: $e');
      throw Exception('解析失败: $e');
    }
  }
}

// 解析后的任务数据
class ParsedTaskData {
  final String title;
  final String? description;
  final int durationMinutes;
  final Priority priority;
  final EnergyLevel energyRequired;
  final FocusLevel focusRequired;
  final TaskCategory taskCategory;
  final DateTime? deadline;
  final DateTime? suggestedDate;
  final String? suggestedTime;

  ParsedTaskData({
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.priority,
    required this.energyRequired,
    required this.focusRequired,
    required this.taskCategory,
    this.deadline,
    this.suggestedDate,
    this.suggestedTime,
  });

  factory ParsedTaskData.fromJson(Map<String, dynamic> json) {
    return ParsedTaskData(
      title: json['title'] ?? '未命名任务',
      description: json['description'],
      durationMinutes: json['durationMinutes'] ?? 60,
      priority: _parsePriority(json['priority']),
      energyRequired: _parseEnergyLevel(json['energyRequired']),
      focusRequired: _parseFocusLevel(json['focusRequired']),
      taskCategory: _parseTaskCategory(json['taskCategory']),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      suggestedDate: json['suggestedDate'] != null
          ? DateTime.parse(json['suggestedDate'])
          : null,
      suggestedTime: json['suggestedTime'],
    );
  }

  static Priority _parsePriority(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }

  static EnergyLevel _parseEnergyLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return EnergyLevel.high;
      case 'low':
        return EnergyLevel.low;
      default:
        return EnergyLevel.medium;
    }
  }

  static FocusLevel _parseFocusLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'deep':
        return FocusLevel.deep;
      case 'light':
        return FocusLevel.light;
      default:
        return FocusLevel.medium;
    }
  }

  static TaskCategory _parseTaskCategory(String? value) {
    switch (value?.toLowerCase()) {
      case 'creative':
        return TaskCategory.creative;
      case 'analytical':
        return TaskCategory.analytical;
      case 'communication':
        return TaskCategory.communication;
      default:
        return TaskCategory.routine;
    }
  }

  // 转换为 Task 对象
  Task toTask() {
    return Task(
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      priority: priority,
      energyRequired: energyRequired,
      focusRequired: focusRequired,
      taskCategory: taskCategory,
      deadline: deadline,
    );
  }

  // 获取建议的安排时间
  DateTime? getSuggestedDateTime() {
    if (suggestedDate == null) return null;

    if (suggestedTime != null) {
      final timeParts = suggestedTime!.split(':');
      return DateTime(
        suggestedDate!.year,
        suggestedDate!.month,
        suggestedDate!.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    return suggestedDate;
  }
}