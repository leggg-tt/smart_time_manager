import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import '../models/enums.dart';

class AnalyticsService {
  final DatabaseService _db = DatabaseService.instance;

  // Task completion statistics
  Future<Map<String, dynamic>> getTaskCompletionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    // Date range filter
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE completedAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // Total tasks by status
    final statusStats = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      $whereClause
      GROUP BY status
    ''', whereArgs);

    // Completion rate
    final totalTasks = await db.rawQuery('''
      SELECT COUNT(*) as total FROM tasks $whereClause
    ''', whereArgs);

    final completedTasks = await db.rawQuery('''
      SELECT COUNT(*) as completed FROM tasks 
      WHERE status = ${TaskStatus.completed.index}
      ${startDate != null ? 'AND completedAt BETWEEN ? AND ?' : ''}
    ''', startDate != null ? whereArgs : []);

    final total = totalTasks.first['total'] as int;
    final completed = completedTasks.first['completed'] as int;

    return {
      'totalTasks': total,
      'completedTasks': completed,
      'completionRate': total > 0 ? (completed / total * 100) : 0,
      'byStatus': statusStats,
    };
  }

  // Time utilization analysis
  Future<Map<String, dynamic>> getTimeUtilizationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    String whereClause = 'WHERE actualStartTime IS NOT NULL';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += ' AND actualStartTime BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // Actual vs planned time
    final timeStats = await db.rawQuery('''
      SELECT 
        SUM(durationMinutes) as plannedMinutes,
        SUM(
          CASE 
            WHEN actualEndTime IS NOT NULL AND actualStartTime IS NOT NULL
            THEN (actualEndTime - actualStartTime) / 60000
            ELSE 0
          END
        ) as actualMinutes
      FROM tasks
      $whereClause
    ''', whereArgs);

    final stats = timeStats.first;
    final plannedMinutes = (stats['plannedMinutes'] ?? 0) as int;
    final actualMinutes = (stats['actualMinutes'] ?? 0) as num;

    return {
      'plannedHours': plannedMinutes / 60,
      'actualHours': actualMinutes / 60,
      'utilizationRate': plannedMinutes > 0
          ? (actualMinutes / plannedMinutes * 100).toDouble()
          : 0.0,
    };
  }

  // Task category distribution
  Future<List<Map<String, dynamic>>> getCategoryDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE createdAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    final results = await db.rawQuery('''
      SELECT 
        taskCategory,
        COUNT(*) as count,
        SUM(durationMinutes) as totalMinutes,
        AVG(durationMinutes) as avgMinutes
      FROM tasks
      $whereClause
      GROUP BY taskCategory
    ''', whereArgs);

    return results.map((row) {
      final category = TaskCategory.values[row['taskCategory'] as int];
      return {
        'category': category,
        'count': row['count'],
        'totalHours': (row['totalMinutes'] as int) / 60,
        'avgMinutes': row['avgMinutes'],
      };
    }).toList();
  }

  // Priority distribution
  Future<List<Map<String, dynamic>>> getPriorityDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE createdAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    final results = await db.rawQuery('''
      SELECT 
        priority,
        COUNT(*) as count,
        SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END) as completed
      FROM tasks
      $whereClause
      GROUP BY priority
    ''', whereArgs);

    return results.map((row) {
      final priority = Priority.values[row['priority'] as int];
      final count = row['count'] as int;
      final completed = row['completed'] as int;
      return {
        'priority': priority,
        'count': count,
        'completed': completed,
        'completionRate': count > 0 ? (completed / count * 100) : 0,
      };
    }).toList();
  }

  // Daily task pattern
  Future<List<Map<String, dynamic>>> getDailyTaskPattern({
    int days = 30,
  }) async {
    final db = await _db.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final results = await db.rawQuery('''
      SELECT 
        DATE(scheduledStartTime / 1000, 'unixepoch') as date,
        COUNT(*) as taskCount,
        SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END) as completed,
        SUM(durationMinutes) as totalMinutes
      FROM tasks
      WHERE scheduledStartTime BETWEEN ? AND ?
      GROUP BY date
      ORDER BY date
    ''', [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ]);

    return results.map((row) => {
      'date': row['date'],
      'taskCount': row['taskCount'],
      'completed': row['completed'],
      'totalHours': (row['totalMinutes'] as int) / 60,
    }).toList();
  }

  // Peak productivity hours
  Future<List<Map<String, dynamic>>> getPeakProductivityHours() async {
    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT 
        CAST(strftime('%H', scheduledStartTime / 1000, 'unixepoch') AS INTEGER) as hour,
        COUNT(*) as taskCount,
        SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END) as completed
      FROM tasks
      WHERE scheduledStartTime IS NOT NULL
      GROUP BY hour
      ORDER BY hour
    ''');

    return results.map((row) {
      final hour = row['hour'] as int;
      final count = row['taskCount'] as int;
      final completed = row['completed'] as int;
      return {
        'hour': hour,
        'taskCount': count,
        'completed': completed,
        'completionRate': count > 0 ? (completed / count * 100) : 0,
      };
    }).toList();
  }

  // Pomodoro statistics
  Future<Map<String, dynamic>> getPomodoroStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    String whereClause = 'WHERE description LIKE "%[Pomodoro:%"';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += ' AND completedAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    final tasksWithPomodoro = await db.query(
      'tasks',
      where: whereClause.replaceFirst('WHERE ', ''),
      whereArgs: whereArgs,
    );

    int totalPomodoros = 0;
    int totalWorkMinutes = 0;

    for (final task in tasksWithPomodoro) {
      final description = task['description'] as String?;
      if (description != null) {
        // Extract pomodoro data from description
        final pomodoroMatch = RegExp(r'\[Pomodoro: (\d+) completed, Total work: (\d+) min\]')
            .firstMatch(description);
        if (pomodoroMatch != null) {
          totalPomodoros += int.parse(pomodoroMatch.group(1)!);
          totalWorkMinutes += int.parse(pomodoroMatch.group(2)!);
        }
      }
    }

    return {
      'totalPomodoros': totalPomodoros,
      'totalWorkHours': totalWorkMinutes / 60,
      'tasksWithPomodoro': tasksWithPomodoro.length,
    };
  }

  // Time block utilization
  Future<List<Map<String, dynamic>>> getTimeBlockUtilization({
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dayOfWeek = targetDate.weekday;

    // Get time blocks for the day
    final timeBlocks = await _db.getTimeBlocksByDay(dayOfWeek);

    // Get tasks scheduled for that day
    final tasks = await _db.getTasksByDate(targetDate);

    final utilization = <Map<String, dynamic>>[];

    for (final block in timeBlocks) {
      final blockStart = _parseTimeToDateTime(targetDate, block.startTime);
      final blockEnd = _parseTimeToDateTime(targetDate, block.endTime);
      final blockDuration = blockEnd.difference(blockStart).inMinutes;

      // Calculate occupied time in this block
      int occupiedMinutes = 0;
      for (final task in tasks) {
        if (task.scheduledStartTime != null && task.scheduledEndTime != null) {
          final taskStart = task.scheduledStartTime!;
          final taskEnd = task.scheduledEndTime!;

          // Check if task overlaps with block
          if (taskStart.isBefore(blockEnd) && taskEnd.isAfter(blockStart)) {
            final overlapStart = taskStart.isAfter(blockStart) ? taskStart : blockStart;
            final overlapEnd = taskEnd.isBefore(blockEnd) ? taskEnd : blockEnd;
            occupiedMinutes += overlapEnd.difference(overlapStart).inMinutes;
          }
        }
      }

      utilization.add({
        'timeBlock': block,
        'totalMinutes': blockDuration,
        'occupiedMinutes': occupiedMinutes,
        'utilizationRate': blockDuration > 0
            ? (occupiedMinutes / blockDuration * 100)
            : 0,
      });
    }

    return utilization;
  }

  DateTime _parseTimeToDateTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}