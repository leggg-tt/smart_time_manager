import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import '../models/enums.dart';

// 创建AnalyticsService类
class AnalyticsService {
  // _db:私有成员变量,获取数据库服务的单例实例
  final DatabaseService _db = DatabaseService.instance;

  // 任务完成统计方法
  // 异步方法,返回包含统计数据的Map
  Future<Map<String, dynamic>> getTaskCompletionStats({
    // 可选参数:开始日期和结束日期,用于筛选时间范围
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 获取数据库实例
    final db = await _db.database;

    // 构建WHERE子句
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // 如果提供了日期范围,创建SQL WHERE子句
    if (startDate != null && endDate != null) {
      // 使用参数化查询防止SQL注入
      whereClause = 'WHERE completedAt BETWEEN ? AND ?';
      whereArgs = [
        // 将日期转换为毫秒时间戳
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // 按状态分组统计
    // 查询每种状态的任务数量,按任务状态分组,返回每个状态及其对应的任务数
    final statusStats = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      $whereClause
      GROUP BY status
    ''', whereArgs);

    // 查询总任务数
    final totalTasks = await db.rawQuery('''
      SELECT COUNT(*) as total FROM tasks $whereClause
    ''', whereArgs);

    // 查询已经完成的任务数量
    final completedTasks = await db.rawQuery('''
      SELECT COUNT(*) as completed FROM tasks 
      WHERE status = ${TaskStatus.completed.index}
      ${startDate != null ? 'AND completedAt BETWEEN ? AND ?' : ''}
    ''', startDate != null ? whereArgs : []);

    // 查询已完成的任务数量
    final total = totalTasks.first['total'] as int;  // 总任务数
    final completed = completedTasks.first['completed'] as int;  // 已经完成的任务数量

    return {
      'totalTasks': total,
      'completedTasks': completed,
      'completionRate': total > 0 ? (completed / total * 100) : 0,  // 完成率百分比
      'byStatus': statusStats,  // 按状态分组的详细数据
    };
  }

  // 时间利用率分析
  Future<Map<String, dynamic>> getTimeUtilizationStats({
    // 分析实际使用时间与计划时间的对比
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    String whereClause = 'WHERE actualStartTime IS NOT NULL';
    List<dynamic> whereArgs = [];

    // 只统计有实际开始时间的任务
    if (startDate != null && endDate != null) {
      whereClause += ' AND actualStartTime BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // 实际时间对比计划时间
    // SUM(durationMinutes)：计算计划总时长
    // CASE WHEN：条件表达式，计算实际花费时间
    // (actualEndTime - actualStartTime) / 60000：毫秒转分钟
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

    // 返回计划时间,实际时间和利用率
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

  // 任务类别分布
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

    // COUNT(*)：每个类别的任务数
    // SUM(durationMinutes)：每个类别的总时长
    // AVG(durationMinutes)：每个类别的平均时长
    // GROUP BY taskCategory：按类别分组
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

    // 将查询结果转换为更友好的格式
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

  // 优先级分布
  // 分析不同优先级任务的完成情况
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

    // 使用 SUM(CASE WHEN...) 统计每个优先级中已完成的任务数
    final results = await db.rawQuery('''
      SELECT 
        priority,
        COUNT(*) as count,
        SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END) as completed
      FROM tasks
      $whereClause
      GROUP BY priority
    ''', whereArgs);

    // 计算每个优先级的完成率
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

  // 每日任务模式
  // 分析最近N天的任务模式,默认30天
  Future<List<Map<String, dynamic>>> getDailyTaskPattern({
    int days = 30,
  }) async {
    final db = await _db.database;
    // 计算时间范围
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // 日期分组查询
    // DATE(scheduledStartTime / 1000, 'unixepoch')：将时间戳转换为日期
    // 按日期分组统计任务数、完成数和总时长
    // ORDER BY date:按日期排序
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

  // 高峰生产力时段,分析一天中哪些时段完成任务最多
  Future<List<Map<String, dynamic>>> getPeakProductivityHours() async {
    final db = await _db.database;

    // 按小时分组
    // strftime('%H', ...)：提取小时部分
    // 统计每个小时的任务数和完成数
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

  // 番茄钟统计,统计番茄钟使用情况
  Future<Map<String, dynamic>> getPomodoroStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    // 查找描述中包含番茄钟信息的任务
    String whereClause = 'WHERE description LIKE "%[Pomodoro:%"';
    List<dynamic> whereArgs = [];

    // 日期范围筛选
    // 如果提供了开始和结束日期，添加时间范围条件
    // 使用参数化查询防止SQL注入
    // 将日期转换为毫秒时间戳存储
    if (startDate != null && endDate != null) {
      whereClause += ' AND completedAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // 返回所有包含番茄钟信息的任务记录
    final tasksWithPomodoro = await db.query(
      'tasks',
      where: whereClause.replaceFirst('WHERE ', ''),
      whereArgs: whereArgs,
    );

    // 初始化计数器
    int totalPomodoros = 0;  // 完成的番茄钟总数
    int totalWorkMinutes = 0;  // 总工作时间（分钟）

    // 遍历查询结果,安全地获取描述字段
    for (final task in tasksWithPomodoro) {
      final description = task['description'] as String?;
      if (description != null) {
        // 正则表达式解析
        // 第一个捕获组：完成的番茄钟数量
        // 第二个捕获组：总工作时间（分钟）
        // 例如：[Pomodoro: 4 completed, Total work: 100 min]
        final pomodoroMatch = RegExp(r'\[Pomodoro: (\d+) completed, Total work: (\d+) min\]')
            .firstMatch(description);
        // 提取并累加数据
        if (pomodoroMatch != null) {
          totalPomodoros += int.parse(pomodoroMatch.group(1)!);
          totalWorkMinutes += int.parse(pomodoroMatch.group(2)!);
        }
      }
    }

    // 返回统计结果
    return {
      'totalPomodoros': totalPomodoros,  // 总番茄钟数
      'totalWorkHours': totalWorkMinutes / 60,  // 总工作小时数（分钟转小时）
      'tasksWithPomodoro': tasksWithPomodoro.length,  // 使用番茄钟的任务数量
    };
  }

  // 时间块利用率方法(分析特定日期的时间块使用效率,看看预设的时间段被任务占用了多少)暂时没用到
  Future<List<Map<String, dynamic>>> getTimeBlockUtilization({
    DateTime? date,
  }) async {
    // 使用提供的日期或今天
    final targetDate = date ?? DateTime.now();
    // 获取星期几（1=周一，7=周日）
    final dayOfWeek = targetDate.weekday;

    // 获取该天的所有时间块配置
    final timeBlocks = await _db.getTimeBlocksByDay(dayOfWeek);

    // 获取该天安排的所有任务
    final tasks = await _db.getTasksByDate(targetDate);

    // 初始化结果列表，存储每个时间块的利用率信息
    final utilization = <Map<String, dynamic>>[];

    // 处理每个时间块
    for (final block in timeBlocks) {
      // 将时间字符串转换为完整的DateTime对象
      final blockStart = _parseTimeToDateTime(targetDate, block.startTime);
      final blockEnd = _parseTimeToDateTime(targetDate, block.endTime);
      // 计算时间块的总时长
      final blockDuration = blockEnd.difference(blockStart).inMinutes;

      // 遍历所有任务，只处理有明确时间安排的任务
      int occupiedMinutes = 0;
      for (final task in tasks) {
        if (task.scheduledStartTime != null && task.scheduledEndTime != null) {
          final taskStart = task.scheduledStartTime!;
          final taskEnd = task.scheduledEndTime!;

          // 检查时间重叠
          if (taskStart.isBefore(blockEnd) && taskEnd.isAfter(blockStart)) {
            final overlapStart = taskStart.isAfter(blockStart) ? taskStart : blockStart;
            final overlapEnd = taskEnd.isBefore(blockEnd) ? taskEnd : blockEnd;
            occupiedMinutes += overlapEnd.difference(overlapStart).inMinutes;
          }
        }
      }

      // 存储结果
      utilization.add({
        'timeBlock': block,  // 时间块对象
        'totalMinutes': blockDuration,  // 时间块总时长
        'occupiedMinutes': occupiedMinutes,  // 被占用的时间
        'utilizationRate': blockDuration > 0  // 利用率百分比
            ? (occupiedMinutes / blockDuration * 100)
            : 0,
      });
    }

    return utilization;
  }

  // 辅助方法,将时间字符串转换为DateTime对象
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