import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../models/ai_preferences.dart';
import 'ai_preferences_service.dart';

// 定义AITaskParser 类
class AITaskParser {
  // _apiKeyPref:存储API Key的键名常量
  static const String _apiKeyPref = 'claude_api_key';
  // 缓存的API Key,避免重复读取
  String? _apiKey;

  // 获取存储的 API Key
  Future<String?> getApiKey() async {
    // 检查内存缓存_apiKey
    if (_apiKey != null) return _apiKey;
    // 如果没有缓存,从 SharedPreferences 读取
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);
    return _apiKey;
  }

  // 保存 API Key
  Future<void> saveApiKey(String apiKey) async {
    // 存储到SharedPreferences持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    // 更新内存缓存
    _apiKey = apiKey;
  }

  // 解析语音输入并创建任务 - 支持英文
  Future<ParsedTaskData?> parseVoiceInput(String voiceText) async {
    // 将语音转换的文本解析为结构化任务数据
    final apiKey = await getApiKey();
    // 首先检查API Key是否有效
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Please set Claude API Key first');
    }

    // 加载用户的 AI 偏好设置
    final aiPreferences = await AIPreferencesService.loadPreferences();

    // 增加 API 调用计数
    await AIPreferencesService.incrementApiCallCount();

    try {
      // 构建API 请求
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          // 指定 JSON 格式
          'Content-Type': 'application/json',
          // 认证密钥
          'x-api-key': apiKey,
          // API 版本
          'anthropic-version': '2023-06-01',
        },
        // 构建请求体
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': '''
Please parse the following voice input into structured task data. Return JSON format only, no other content.

Voice input: "$voiceText"

Current time: ${DateTime.now().toIso8601String()}

Please return JSON in this format:
{
  "title": "Task title",
  "description": "Task description (optional)",
  "durationMinutes": 60,
  "priority": "high/medium/low",
  "energyRequired": "high/medium/low", 
  "focusRequired": "deep/medium/light",
  "taskCategory": "creative/analytical/routine/communication",
  "deadline": "YYYY-MM-DD (optional)",
  "suggestedDate": "YYYY-MM-DD (suggested date to schedule)",
  "suggestedTime": "HH:mm (suggested time to schedule)"
}

Core Parsing Rules:
1. Always judge priority based on tone and deadline urgency if not explicitly mentioned
2. Infer appropriate category from task content keywords
3. Convert all relative time expressions to specific dates
4. Always suggest a suitable time slot if no specific time is mentioned
5. Consider task dependencies and logical sequence

${aiPreferences.generateParsingRules()}

Additional Context Rules:
- For ambiguous durations, prefer shorter times for simple tasks and longer for complex ones
- If the task involves other people (meetings, calls), default to business hours
- For tasks requiring deep concentration, prefer morning hours or user's peak time
- Break down compound requests into the most important single task
- Recognize common task patterns and apply appropriate defaults

Language-Specific Rules:
- Chinese: "明天"=tomorrow, "下周"=next week, "下午"=afternoon, "上午"=morning
- Understand cultural context (e.g., Chinese lunch time is typically 12:00-13:00)
- Handle both formal and informal expressions

Task Category Detection Keywords:
- Creative: design, write, create, brainstorm, plan, innovate, draw, paint (画画)
- Analytical: analyze, review, research, calculate, evaluate, assess
- Communication: meet, call, email, discuss, present, talk
- Routine: check, update, organize, file, process, submit

Examples of voice input patterns:
English:
- "Schedule a meeting with John tomorrow at 3 PM for 2 hours"
- "Finish the project report by Friday afternoon, it needs high focus"
- "Call mom sometime this week"
- "Prepare presentation for Monday morning meeting"
- "Review emails and respond to urgent ones"
- "Workout at the gym for an hour"
- "Write blog post about AI trends, should take about 90 minutes"

Chinese:
- "明天下午3点和John开会，大概2小时"
- "下周五之前完成项目报告"
- "明天我要画画"
- "下周给妈妈打电话"
- "准备周一早上的演讲"

Error Handling:
- If unclear, use task type to determine reasonable defaults
- If date parsing fails, use next available weekday
- Always provide a valid response even with minimal input
'''
            }
          ],
        }),
      );

      // 处理API响应
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];

        // 提取 JSON 部分
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final taskData = jsonDecode(jsonStr);
          // 解析 JSON 并创建 ParsedTaskData 对象
          return ParsedTaskData.fromJson(taskData);
        }
      }

      throw Exception('API request failed: ${response.statusCode}');
    } catch (e) {
      print('AI parsing error: $e');
      throw Exception('Parsing failed: $e');
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

  // JSON解析方法
  factory ParsedTaskData.fromJson(Map<String, dynamic> json) {
    return ParsedTaskData(
      // 提供默认值
      title: json['title'] ?? 'Untitled Task',
      description: json['description'],
      durationMinutes: json['durationMinutes'] ?? 60,
      // 调用辅助方法解析枚举值
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

  // 枚举解析辅助方法
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