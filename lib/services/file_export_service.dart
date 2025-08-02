import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

class FileExportService {
  final DatabaseService _db = DatabaseService.instance;

  // 导出任务数据为CSV文件
  Future<String> exportTasksToFile({
    DateTime? startDate,
    DateTime? endDate,
    bool includeCompleted = true,
    bool includePending = true,
    bool includeScheduled = true,
  }) async {
    try {
      // 获取任务数据
      final tasks = await _getTasksForExport(
        startDate: startDate,
        endDate: endDate,
        includeCompleted: includeCompleted,
        includePending: includePending,
        includeScheduled: includeScheduled,
      );

      if (tasks.isEmpty) {
        throw Exception('No tasks found for the selected criteria');
      }

      // 生成CSV内容
      final csvContent = _generateCSVContent(tasks);

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();

      // 创建导出文件夹
      final exportDir = Directory('${directory.path}/SmartTimeManager/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // 生成文件名
      final fileName = 'tasks_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${exportDir.path}/$fileName');

      // 写入文件
      await file.writeAsString(csvContent, flush: true);

      // 返回文件路径
      return file.path;
    } catch (e) {
      throw Exception('Failed to export tasks: $e');
    }
  }

  // 获取导出目录路径
  Future<String> getExportDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/SmartTimeManager/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  // 列出所有导出的文件
  Future<List<FileSystemEntity>> listExportedFiles() async {
    final exportPath = await getExportDirectoryPath();
    final exportDir = Directory(exportPath);
    if (await exportDir.exists()) {
      return exportDir.listSync()
          .where((entity) => entity.path.endsWith('.csv') || entity.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    }
    return [];
  }

  // 删除导出文件
  Future<void> deleteExportFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 获取要导出的任务
  Future<List<Task>> _getTasksForExport({
    DateTime? startDate,
    DateTime? endDate,
    required bool includeCompleted,
    required bool includePending,
    required bool includeScheduled,
  }) async {
    final allTasks = await _db.getAllTasks();

    return allTasks.where((task) {
      // 状态过滤
      bool statusMatch = false;
      if (includeCompleted && task.status == TaskStatus.completed) statusMatch = true;
      if (includePending && task.status == TaskStatus.pending) statusMatch = true;
      if (includeScheduled && (task.status == TaskStatus.scheduled || task.status == TaskStatus.inProgress)) statusMatch = true;

      if (!statusMatch) return false;

      // 日期过滤
      if (startDate != null || endDate != null) {
        final taskDate = task.completedAt ?? task.scheduledStartTime ?? task.createdAt;

        if (startDate != null && taskDate.isBefore(startDate)) return false;
        if (endDate != null && taskDate.isAfter(endDate.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();
  }

  // 生成CSV内容
  String _generateCSVContent(List<Task> tasks) {
    final buffer = StringBuffer();

    // 添加 UTF-8 BOM 以确保 Excel 正确识别编码
    buffer.write('\uFEFF');

    // CSV头部
    buffer.writeln(
        'Title,Description,Status,Priority,Duration (min),Energy Required,Focus Required,'
            'Category,Created Date,Scheduled Date,Completed Date,Actual Duration (min)'
    );

    // 任务数据
    for (final task in tasks) {
      final actualDuration = (task.actualStartTime != null && task.actualEndTime != null)
          ? task.actualEndTime!.difference(task.actualStartTime!).inMinutes
          : '';

      buffer.writeln(
          '${_escapeCSV(task.title)},'
              '${_escapeCSV(task.description ?? '')},'
              '${_getStatusText(task.status)},'
              '${task.priority.displayName},'
              '${task.durationMinutes},'
              '${task.energyRequired.displayName},'
              '${task.focusRequired.displayName},'
              '${task.taskCategory.displayName},'
              '${_formatDate(task.createdAt)},'
              '${_formatDate(task.scheduledStartTime)},'
              '${_formatDate(task.completedAt)},'
              '$actualDuration'
      );
    }

    return buffer.toString();
  }

  // 转义CSV特殊字符
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // 格式化日期
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // 获取状态文本
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.scheduled:
        return 'Scheduled';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  // 导出分析报告到文件
  Future<String> exportAnalyticsReportToFile({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final tasks = await _db.getAllTasks();
      final filteredTasks = tasks.where((task) {
        final taskDate = task.completedAt ?? task.scheduledStartTime ?? task.createdAt;
        return taskDate.isAfter(startDate) && taskDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // 生成报告内容
      final reportContent = _generateAnalyticsReport(filteredTasks, startDate, endDate);

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();

      // 创建导出文件夹
      final exportDir = Directory('${directory.path}/SmartTimeManager/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // 生成文件名
      final fileName = 'analytics_report_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.txt';
      final file = File('${exportDir.path}/$fileName');

      // 写入文件
      await file.writeAsString(reportContent, flush: true);

      // 返回文件路径
      return file.path;
    } catch (e) {
      throw Exception('Failed to export analytics report: $e');
    }
  }

  // 生成分析报告
  String _generateAnalyticsReport(List<Task> tasks, DateTime startDate, DateTime endDate) {
    final buffer = StringBuffer();

    // 报告标题
    buffer.writeln('SMART TIME MANAGER - ANALYTICS REPORT');
    buffer.writeln('=====================================');
    buffer.writeln('Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}');
    buffer.writeln('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln();

    // 总体统计
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    final totalPlannedMinutes = tasks.fold<int>(0, (sum, task) => sum + task.durationMinutes);
    final totalActualMinutes = completedTasks.fold<int>(0, (sum, task) {
      if (task.actualStartTime != null && task.actualEndTime != null) {
        return sum + task.actualEndTime!.difference(task.actualStartTime!).inMinutes;
      }
      return sum;
    });

    buffer.writeln('OVERVIEW');
    buffer.writeln('--------');
    buffer.writeln('Total Tasks: ${tasks.length}');
    buffer.writeln('Completed Tasks: ${completedTasks.length}');
    buffer.writeln('Completion Rate: ${tasks.isEmpty ? 0 : (completedTasks.length / tasks.length * 100).toStringAsFixed(1)}%');
    buffer.writeln('Total Planned Hours: ${(totalPlannedMinutes / 60).toStringAsFixed(1)}');
    buffer.writeln('Total Actual Hours: ${(totalActualMinutes / 60).toStringAsFixed(1)}');
    buffer.writeln();

    // 按优先级统计
    buffer.writeln('BY PRIORITY');
    buffer.writeln('-----------');
    for (final priority in Priority.values) {
      final priorityTasks = tasks.where((t) => t.priority == priority).toList();
      final priorityCompleted = priorityTasks.where((t) => t.status == TaskStatus.completed).length;
      buffer.writeln('${priority.displayName}: ${priorityTasks.length} tasks, $priorityCompleted completed');
    }
    buffer.writeln();

    // 按类别统计
    buffer.writeln('BY CATEGORY');
    buffer.writeln('-----------');
    for (final category in TaskCategory.values) {
      final categoryTasks = tasks.where((t) => t.taskCategory == category).toList();
      final categoryCompleted = categoryTasks.where((t) => t.status == TaskStatus.completed).length;
      buffer.writeln('${category.displayName}: ${categoryTasks.length} tasks, $categoryCompleted completed');
    }

    return buffer.toString();
  }
}