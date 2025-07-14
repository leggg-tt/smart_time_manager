import 'dart:math';
import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

class TestDataGenerator {
  final DatabaseService _db = DatabaseService.instance;
  final Random _random = Random();

  // 任务标题，按类别分组 - 添加标记便于识别
  final Map<TaskCategory, List<String>> _taskTitles = {
    TaskCategory.creative: [
      '[TEST] Design new app UI',
      '[TEST] Create marketing materials',
      '[TEST] Write blog post',
      '[TEST] Brainstorm product features',
      '[TEST] Design logo concepts',
    ],
    TaskCategory.analytical: [
      '[TEST] Analyze user data',
      '[TEST] Review quarterly reports',
      '[TEST] Research market trends',
      '[TEST] Performance analysis',
      '[TEST] Budget planning',
    ],
    TaskCategory.routine: [
      '[TEST] Check emails',
      '[TEST] Update project status',
      '[TEST] File documents',
      '[TEST] Review calendar',
      '[TEST] Clean inbox',
    ],
    TaskCategory.communication: [
      '[TEST] Team meeting',
      '[TEST] Client call',
      '[TEST] One-on-one',
      '[TEST] Project sync',
      '[TEST] Department standup',
    ],
  };

  // 生成测试数据 - 优化默认参数
  Future<void> generateTestData({
    int daysBack = 7,          // 默认改为7天
    int tasksPerDay = 3,       // 默认改为每天3个任务
    double completionRate = 0.75,
    bool includePomodoros = true,
    bool useRealisticPatterns = true,  // 新增：使用真实模式
  }) async {
    print('开始生成测试数据...');

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    int totalTasksCreated = 0;
    int totalTasksCompleted = 0;

    // 为每天生成任务
    for (int dayOffset = 0; dayOffset < daysBack; dayOffset++) {
      final currentDate = startDate.add(Duration(days: dayOffset));

      // 跳过周末
      if (currentDate.weekday == 6 || currentDate.weekday == 7) {
        continue;
      }

      // 使用真实模式时，每天的任务数量有变化
      int dayTaskCount = tasksPerDay;
      if (useRealisticPatterns) {
        // 周一和周五任务较多，周三较少
        if (currentDate.weekday == 1 || currentDate.weekday == 5) {
          dayTaskCount = tasksPerDay + _random.nextInt(2);
        } else if (currentDate.weekday == 3) {
          dayTaskCount = max(1, tasksPerDay - 1);
        }
      }

      // 获取当天的时间块
      final timeBlocks = await _db.getTimeBlocksByDay(currentDate.weekday);

      // 生成当天的任务
      for (int i = 0; i < dayTaskCount; i++) {
        Task task = _generateRandomTask(currentDate, timeBlocks);

        // 决定任务是否应该完成
        final shouldComplete = _random.nextDouble() < completionRate;

        if (shouldComplete && currentDate.isBefore(DateTime.now())) {
          // 设置实际开始时间（可能比计划时间早或晚）
          final startVariance = _random.nextInt(21) - 10; // -10到+10分钟
          final actualStart = task.scheduledStartTime != null
              ? task.scheduledStartTime!.add(Duration(minutes: startVariance))
              : currentDate.add(Duration(hours: 9 + i * 2));

          // 实际持续时间可能与计划不同
          final durationVariance = _random.nextInt(31) - 15; // -15到+15分钟
          final actualDuration = task.durationMinutes + durationVariance;
          final actualEnd = actualStart.add(Duration(minutes: actualDuration));

          task = task.copyWith(
            status: TaskStatus.completed,
            actualStartTime: actualStart,    // 现在包含实际开始时间！
            actualEndTime: actualEnd,         // 实际结束时间
            completedAt: actualEnd,
          );

          // 添加番茄钟数据
          if (includePomodoros && _random.nextDouble() < 0.6) {
            final pomodoroCount = (actualDuration / 25).ceil();
            final completedPomodoros = max(1, pomodoroCount - _random.nextInt(2));
            final workMinutes = completedPomodoros * 25;

            final pomodoroDescription = (task.description ?? '') +
                '\n[Pomodoro: $completedPomodoros completed, Total work: $workMinutes min]';

            task = task.copyWith(description: pomodoroDescription);
          }

          totalTasksCompleted++;
        } else if (currentDate.isAfter(DateTime.now())) {
          // 未来的任务保持已安排状态
          task = task.copyWith(status: TaskStatus.scheduled);
        } else if (_random.nextDouble() < 0.3) {
          // 一些过去的任务保持待办状态
          task = task.copyWith(
            status: TaskStatus.pending,
            scheduledStartTime: null,
          );
        } else {
          // 过去未完成的任务
          task = task.copyWith(
            status: TaskStatus.scheduled,
            // 这些任务看起来像是被跳过了
          );
        }

        await _db.insertTask(task);
        totalTasksCreated++;
      }
    }

    // 生成一些未来的任务（接下来3天）
    for (int dayOffset = 1; dayOffset <= 3; dayOffset++) {
      final futureDate = endDate.add(Duration(days: dayOffset));

      // 跳过周末
      if (futureDate.weekday == 6 || futureDate.weekday == 7) continue;

      // 未来每天生成1-2个任务
      final futureTaskCount = 1 + _random.nextInt(2);

      for (int i = 0; i < futureTaskCount; i++) {
        final task = _generateRandomTask(futureDate, []);
        await _db.insertTask(task.copyWith(status: TaskStatus.scheduled));
        totalTasksCreated++;
      }
    }

    print('测试数据生成完成！');
    print('创建的任务总数：$totalTasksCreated');
    print('已完成的任务数：$totalTasksCompleted');
    print('完成率：${(totalTasksCompleted / totalTasksCreated * 100).toStringAsFixed(1)}%');
  }

  Task _generateRandomTask(DateTime date, List<UserTimeBlock> timeBlocks) {
    // 随机选择类别
    final category = TaskCategory.values[_random.nextInt(TaskCategory.values.length)];

    // 从类别中随机选择标题
    final titles = _taskTitles[category]!;
    final title = titles[_random.nextInt(titles.length)];

    // 根据权重分配优先级
    final priorityRand = _random.nextDouble();
    final priority = priorityRand < 0.2 ? Priority.high
        : priorityRand < 0.6 ? Priority.medium
        : Priority.low;

    // 根据类别设置持续时间
    final duration = _getRandomDuration(category);

    // 根据类别和优先级设置精力和专注度
    final energyRequired = _getEnergyLevel(category, priority);
    final focusRequired = _getFocusLevel(category);

    // 安排时间（如果有可用的时间块）
    DateTime? scheduledTime;
    if (timeBlocks.isNotEmpty && _random.nextDouble() < 0.8) {
      final block = timeBlocks[_random.nextInt(timeBlocks.length)];
      final blockStart = _parseTimeToDateTime(date, block.startTime);
      final blockEnd = _parseTimeToDateTime(date, block.endTime);

      // 在时间块内随机选择时间
      final blockDuration = blockEnd.difference(blockStart).inMinutes;
      if (blockDuration >= duration) {
        final maxStartOffset = blockDuration - duration;
        final startOffset = _random.nextInt(maxStartOffset + 1);
        scheduledTime = blockStart.add(Duration(minutes: startOffset));
      }
    }

    // 如果没有合适的时间块，在工作时间内随机安排
    if (scheduledTime == null) {
      final hour = 8 + _random.nextInt(10); // 8 AM to 6 PM
      final minute = _random.nextInt(4) * 15; // 0, 15, 30, or 45
      scheduledTime = DateTime(date.year, date.month, date.day, hour, minute);
    }

    // 为高优先级任务添加截止日期
    DateTime? deadline;
    if (priority == Priority.high && _random.nextDouble() < 0.7) {
      deadline = date.add(Duration(days: _random.nextInt(7) + 1));
    }

    return Task(
      title: title,
      description: _random.nextDouble() < 0.3
          ? '这是用于测试分析功能的模拟数据'
          : null,
      durationMinutes: duration,
      priority: priority,
      energyRequired: energyRequired,
      focusRequired: focusRequired,
      taskCategory: category,
      deadline: deadline,
      scheduledStartTime: scheduledTime,
      status: TaskStatus.scheduled,
    );
  }

  int _getRandomDuration(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return 60 + _random.nextInt(60); // 60-120分钟
      case TaskCategory.analytical:
        return 45 + _random.nextInt(45); // 45-90分钟
      case TaskCategory.routine:
        return 15 + _random.nextInt(30); // 15-45分钟
      case TaskCategory.communication:
        return 30 + _random.nextInt(30); // 30-60分钟
    }
  }

  EnergyLevel _getEnergyLevel(TaskCategory category, Priority priority) {
    if (priority == Priority.high) {
      return _random.nextDouble() < 0.7 ? EnergyLevel.high : EnergyLevel.medium;
    }

    switch (category) {
      case TaskCategory.creative:
      case TaskCategory.analytical:
        return _random.nextDouble() < 0.6 ? EnergyLevel.high : EnergyLevel.medium;
      case TaskCategory.routine:
        return _random.nextDouble() < 0.7 ? EnergyLevel.low : EnergyLevel.medium;
      case TaskCategory.communication:
        return EnergyLevel.medium;
    }
  }

  FocusLevel _getFocusLevel(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return _random.nextDouble() < 0.7 ? FocusLevel.deep : FocusLevel.medium;
      case TaskCategory.analytical:
        return FocusLevel.deep;
      case TaskCategory.routine:
        return _random.nextDouble() < 0.7 ? FocusLevel.light : FocusLevel.medium;
      case TaskCategory.communication:
        return _random.nextDouble() < 0.6 ? FocusLevel.medium : FocusLevel.light;
    }
  }

  // 修复：将 TimeOfDay 参数改为 String
  DateTime _parseTimeToDateTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // 清除所有测试任务（只清除带[TEST]标记的）
  Future<void> clearTestTasks() async {
    final db = await _db.database;
    // 只删除标题包含[TEST]的任务
    await db.delete(
      'tasks',
      where: 'title LIKE ?',
      whereArgs: ['%[TEST]%'],
    );
    print('测试任务已清除');
  }

  // 清除所有任务（危险操作）
  Future<void> clearAllTasks() async {
    final db = await _db.database;
    await db.delete('tasks');
    print('所有任务已清除');
  }
}