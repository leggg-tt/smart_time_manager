import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/enums.dart';

/// 任务模板类
class TaskTemplate {
  final String id;
  final String title;
  final String? description;
  final int durationMinutes;
  final Priority priority;
  final EnergyLevel energyRequired;
  final FocusLevel focusRequired;
  final TaskCategory taskCategory;

  TaskTemplate({
    required this.id,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.priority,
    required this.energyRequired,
    required this.focusRequired,
    required this.taskCategory,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'durationMinutes': durationMinutes,
    'priority': priority.index,
    'energyRequired': energyRequired.index,
    'focusRequired': focusRequired.index,
    'taskCategory': taskCategory.index,
  };

  /// 从 JSON 创建
  factory TaskTemplate.fromJson(Map<String, dynamic> json) => TaskTemplate(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    durationMinutes: json['durationMinutes'],
    priority: Priority.values[json['priority']],
    energyRequired: EnergyLevel.values[json['energyRequired']],
    focusRequired: FocusLevel.values[json['focusRequired']],
    taskCategory: TaskCategory.values[json['taskCategory']],
  );

  /// 从任务创建模板
  factory TaskTemplate.fromTask(Task task) => TaskTemplate(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: task.title,
    description: task.description,
    durationMinutes: task.durationMinutes,
    priority: task.priority,
    energyRequired: task.energyRequired,
    focusRequired: task.focusRequired,
    taskCategory: task.taskCategory,
  );

  /// 转换为任务
  Task toTask() => Task(
    title: title,
    description: description,
    durationMinutes: durationMinutes,
    priority: priority,
    energyRequired: energyRequired,
    focusRequired: focusRequired,
    taskCategory: taskCategory,
  );
}

/// 任务模板服务类
class TaskTemplateService {
  // 使用唯一的键名，避免与其他 SharedPreferences 冲突
  static const String _templatesKey = 'user_task_templates_v1';
  static const String _lastModifiedKey = 'templates_last_modified';
  static const int _maxTemplates = 20; // 最大模板数量限制

  /// 获取所有模板
  static Future<List<TaskTemplate>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? templatesJson = prefs.getString(_templatesKey);

      if (templatesJson == null || templatesJson.isEmpty) {
        return [];
      }

      final List<dynamic> templatesList = json.decode(templatesJson);
      return templatesList.map((t) => TaskTemplate.fromJson(t)).toList();

    } catch (e) {
      print('Error loading templates: $e');
      // 如果数据损坏，返回空列表而不是崩溃
      return [];
    }
  }

  /// 保存模板
  static Future<bool> saveTemplate(TaskTemplate template) async {
    try {
      final templates = await getTemplates();

      // 检查模板数量限制
      if (templates.length >= _maxTemplates &&
          !templates.any((t) => t.id == template.id)) {
        throw Exception('Maximum template limit reached ($_maxTemplates)');
      }

      // 检查是否已存在同名模板（更新而不是创建新的）
      final existingIndex = templates.indexWhere((t) => t.title == template.title);
      if (existingIndex != -1) {
        // 更新现有模板
        templates[existingIndex] = template;
      } else {
        // 添加新模板
        templates.add(template);
      }

      final prefs = await SharedPreferences.getInstance();
      final String templatesJson = json.encode(
          templates.map((t) => t.toJson()).toList()
      );

      // 保存模板列表
      await prefs.setString(_templatesKey, templatesJson);

      // 保存最后修改时间
      await prefs.setString(
          _lastModifiedKey,
          DateTime.now().toIso8601String()
      );

      return true;

    } catch (e) {
      print('Error saving template: $e');
      return false;
    }
  }

  /// 删除模板
  static Future<void> deleteTemplate(String templateId) async {
    try {
      final templates = await getTemplates();
      templates.removeWhere((t) => t.id == templateId);

      final prefs = await SharedPreferences.getInstance();

      if (templates.isEmpty) {
        // 如果没有模板了，直接删除键
        await prefs.remove(_templatesKey);
        await prefs.remove(_lastModifiedKey);
      } else {
        // 否则保存更新后的列表
        final String templatesJson = json.encode(
            templates.map((t) => t.toJson()).toList()
        );
        await prefs.setString(_templatesKey, templatesJson);
        await prefs.setString(
            _lastModifiedKey,
            DateTime.now().toIso8601String()
        );
      }
    } catch (e) {
      print('Error deleting template: $e');
      throw e;
    }
  }

  /// 从任务创建并保存模板
  static Future<bool> createTemplateFromTask(Task task) async {
    try {
      final template = TaskTemplate.fromTask(task);
      return await saveTemplate(template);
    } catch (e) {
      print('Error creating template from task: $e');
      return false;
    }
  }

  /// 清空所有模板
  static Future<void> clearAllTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_templatesKey);
      await prefs.remove(_lastModifiedKey);
    } catch (e) {
      print('Error clearing templates: $e');
      throw e;
    }
  }

  /// 获取存储信息（用于调试和设置页面）
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      final lastModified = prefs.getString(_lastModifiedKey);

      return {
        'key': _templatesKey,
        'size': templatesJson?.length ?? 0,
        'templateCount': templatesJson != null
            ? (json.decode(templatesJson) as List).length
            : 0,
        'lastModified': lastModified,
        'estimatedSizeKB': ((templatesJson?.length ?? 0) / 1024).toStringAsFixed(2),
        'maxTemplates': _maxTemplates,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'templateCount': 0,
        'maxTemplates': _maxTemplates,
      };
    }
  }

  /// 检查模板是否有效
  static bool isValidTemplate(TaskTemplate template) {
    return template.title.isNotEmpty &&
        template.durationMinutes > 0 &&
        template.durationMinutes <= 480; // 最多8小时
  }
}