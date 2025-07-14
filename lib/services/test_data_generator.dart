import 'dart:math';
import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

class TestDataGenerator {
  final DatabaseService _db = DatabaseService.instance;
  final Random _random = Random();

  // Task titles for different categories
  final Map<TaskCategory, List<String>> _taskTitles = {
    TaskCategory.creative: [
      'Design new app UI',
      'Create marketing materials',
      'Write blog post',
      'Brainstorm product features',
      'Design logo concepts',
      'Create presentation slides',
      'Develop brand guidelines',
      'Sketch wireframes',
    ],
    TaskCategory.analytical: [
      'Analyze user data',
      'Review quarterly reports',
      'Research market trends',
      'Optimize database queries',
      'Performance analysis',
      'Budget planning',
      'Risk assessment',
      'Data visualization',
    ],
    TaskCategory.routine: [
      'Check emails',
      'Update project status',
      'File documents',
      'Organize workspace',
      'Backup data',
      'Review calendar',
      'Update task list',
      'Clean inbox',
    ],
    TaskCategory.communication: [
      'Team meeting',
      'Client call',
      'One-on-one with manager',
      'Project sync',
      'Stakeholder update',
      'Interview candidate',
      'Department standup',
      'Vendor negotiation',
    ],
  };

  // Generate test data for the past N days
  Future<void> generateTestData({
    int daysBack = 30,
    int tasksPerDay = 5,
    double completionRate = 0.75,
    bool includePomodoros = true,
  }) async {
    print('Starting test data generation...');

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    int totalTasksCreated = 0;
    int totalTasksCompleted = 0;

    // Generate tasks for each day
    for (int dayOffset = 0; dayOffset < daysBack; dayOffset++) {
      final currentDate = startDate.add(Duration(days: dayOffset));

      // Skip weekends if desired
      if (currentDate.weekday == 6 || currentDate.weekday == 7) {
        continue; // Skip Saturday and Sunday
      }

      // Get time blocks for this day
      final timeBlocks = await _db.getTimeBlocksByDay(currentDate.weekday);

      // Generate tasks for this day
      final dayTaskCount = _random.nextInt(3) + tasksPerDay - 1; // Some variation

      for (int i = 0; i < dayTaskCount; i++) {
        Task task = _generateRandomTask(currentDate, timeBlocks);

        // Decide if task should be completed based on completion rate
        final shouldComplete = _random.nextDouble() < completionRate;

        if (shouldComplete && currentDate.isBefore(endDate)) {
          final completedAt = task.scheduledStartTime?.add(
            Duration(minutes: task.durationMinutes + _random.nextInt(30)),
          );

          task = task.copyWith(
            status: TaskStatus.completed,
            completedAt: completedAt,
            actualEndTime: completedAt,
          );

          // Add pomodoro data for some completed tasks
          if (includePomodoros && _random.nextDouble() < 0.6) {
            final pomodoroCount = (task.durationMinutes / 25).ceil();
            final completedPomodoros = _random.nextInt(pomodoroCount) + 1;
            final workMinutes = completedPomodoros * 25;

            final pomodoroDescription = (task.description ?? '') +
                '\n---\n[Pomodoro: $completedPomodoros completed, Total work: $workMinutes min]';

            task = task.copyWith(description: pomodoroDescription);
          }

          totalTasksCompleted++;
        } else if (currentDate.isAfter(DateTime.now())) {
          // Future tasks remain scheduled
          task = task.copyWith(status: TaskStatus.scheduled);
        } else if (_random.nextDouble() < 0.3) {
          // Some past tasks remain pending
          task = task.copyWith(
            status: TaskStatus.pending,
            scheduledStartTime: null,
          );
        }

        await _db.insertTask(task);
        totalTasksCreated++;
      }
    }

    print('Test data generation completed!');
    print('Total tasks created: $totalTasksCreated');
    print('Total tasks completed: $totalTasksCompleted');
    print('Completion rate: ${(totalTasksCompleted / totalTasksCreated * 100).toStringAsFixed(1)}%');
  }

  Task _generateRandomTask(DateTime date, List<UserTimeBlock> timeBlocks) {
    // Random category
    final category = TaskCategory.values[_random.nextInt(TaskCategory.values.length)];

    // Random title from category
    final titles = _taskTitles[category]!;
    final title = titles[_random.nextInt(titles.length)];

    // Random priority with weighted distribution
    final priorityRand = _random.nextDouble();
    final priority = priorityRand < 0.2 ? Priority.high
        : priorityRand < 0.6 ? Priority.medium
        : Priority.low;

    // Duration based on category
    final duration = _getRandomDuration(category);

    // Energy and focus based on category and priority
    final energyRequired = _getEnergyLevel(category, priority);
    final focusRequired = _getFocusLevel(category);

    // Schedule time (pick a random time block if available)
    DateTime? scheduledTime;
    if (timeBlocks.isNotEmpty && _random.nextDouble() < 0.8) {
      final block = timeBlocks[_random.nextInt(timeBlocks.length)];
      final blockStart = _parseTimeToDateTime(date, block.startTime);
      final blockEnd = _parseTimeToDateTime(date, block.endTime);

      // Random time within the block
      final blockDuration = blockEnd.difference(blockStart).inMinutes;
      if (blockDuration >= duration) {
        final maxStartOffset = blockDuration - duration;
        final startOffset = _random.nextInt(maxStartOffset + 1);
        scheduledTime = blockStart.add(Duration(minutes: startOffset));
      }
    }

    // If no suitable block, schedule at random time
    if (scheduledTime == null) {
      final hour = 8 + _random.nextInt(10); // 8 AM to 6 PM
      final minute = _random.nextInt(4) * 15; // 0, 15, 30, or 45
      scheduledTime = DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Add deadline for some high priority tasks
    DateTime? deadline;
    if (priority == Priority.high && _random.nextDouble() < 0.7) {
      deadline = date.add(Duration(days: _random.nextInt(7) + 1));
    }

    return Task(
      title: title,
      description: _random.nextDouble() < 0.3 ? 'Generated test task for analytics' : null,
      durationMinutes: duration,
      priority: priority,
      energyRequired: energyRequired,
      focusRequired: focusRequired,
      taskCategory: category,
      deadline: deadline,
      scheduledStartTime: scheduledTime,
      actualStartTime: scheduledTime,
      status: TaskStatus.scheduled,
    );
  }

  int _getRandomDuration(TaskCategory category) {
    switch (category) {
      case TaskCategory.creative:
        return 60 + _random.nextInt(120); // 60-180 minutes
      case TaskCategory.analytical:
        return 45 + _random.nextInt(90); // 45-135 minutes
      case TaskCategory.routine:
        return 15 + _random.nextInt(45); // 15-60 minutes
      case TaskCategory.communication:
        return 30 + _random.nextInt(60); // 30-90 minutes
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
      case TaskCategory.analytical:
        return _random.nextDouble() < 0.7 ? FocusLevel.deep : FocusLevel.medium;
      case TaskCategory.routine:
        return _random.nextDouble() < 0.7 ? FocusLevel.light : FocusLevel.medium;
      case TaskCategory.communication:
        return _random.nextDouble() < 0.6 ? FocusLevel.medium : FocusLevel.light;
    }
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

  // Generate realistic patterns
  Future<void> generateRealisticPatterns({
    int daysBack = 30,
  }) async {
    print('Generating realistic task patterns...');

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    for (int dayOffset = 0; dayOffset < daysBack; dayOffset++) {
      final currentDate = startDate.add(Duration(days: dayOffset));

      // Skip weekends
      if (currentDate.weekday == 6 || currentDate.weekday == 7) {
        continue;
      }

      // Morning routine tasks (8-9 AM)
      await _createMorningRoutine(currentDate);

      // Deep work sessions (9-12 AM)
      await _createDeepWorkSession(currentDate);

      // Communication block (2-4 PM)
      await _createCommunicationBlock(currentDate);

      // End of day routine (5-6 PM)
      await _createEndOfDayRoutine(currentDate);
    }

    print('Realistic patterns generation completed!');
  }

  Future<void> _createMorningRoutine(DateTime date) async {
    final tasks = [
      Task(
        title: 'Check emails',
        durationMinutes: 30,
        priority: Priority.medium,
        energyRequired: EnergyLevel.low,
        focusRequired: FocusLevel.light,
        taskCategory: TaskCategory.routine,
        scheduledStartTime: DateTime(date.year, date.month, date.day, 8, 0),
        status: date.isBefore(DateTime.now()) ? TaskStatus.completed : TaskStatus.scheduled,
        completedAt: date.isBefore(DateTime.now())
            ? DateTime(date.year, date.month, date.day, 8, 30)
            : null,
      ),
      Task(
        title: 'Review daily agenda',
        durationMinutes: 15,
        priority: Priority.medium,
        energyRequired: EnergyLevel.low,
        focusRequired: FocusLevel.light,
        taskCategory: TaskCategory.routine,
        scheduledStartTime: DateTime(date.year, date.month, date.day, 8, 30),
        status: date.isBefore(DateTime.now()) ? TaskStatus.completed : TaskStatus.scheduled,
        completedAt: date.isBefore(DateTime.now())
            ? DateTime(date.year, date.month, date.day, 8, 45)
            : null,
      ),
    ];

    for (final task in tasks) {
      if (_random.nextDouble() < 0.9) { // 90% completion rate for morning routine
        await _db.insertTask(task);
      }
    }
  }

  Future<void> _createDeepWorkSession(DateTime date) async {
    final deepWorkTasks = [
      'Write project proposal',
      'Code review',
      'Design system architecture',
      'Analyze quarterly metrics',
      'Research new technologies',
    ];

    final isCompleted = date.isBefore(DateTime.now()) && _random.nextDouble() < 0.8;
    final duration = 90 + _random.nextInt(60); // 90-150 minutes
    final scheduledStartTime = DateTime(date.year, date.month, date.day, 9, 30);

    Task task = Task(
      title: deepWorkTasks[_random.nextInt(deepWorkTasks.length)],
      durationMinutes: duration,
      priority: Priority.high,
      energyRequired: EnergyLevel.high,
      focusRequired: FocusLevel.deep,
      taskCategory: _random.nextDouble() < 0.5 ? TaskCategory.analytical : TaskCategory.creative,
      scheduledStartTime: scheduledStartTime,
      status: isCompleted ? TaskStatus.completed : TaskStatus.scheduled,
      completedAt: isCompleted ? scheduledStartTime.add(Duration(minutes: duration)) : null,
    );

    if (isCompleted) {
      // Add pomodoro data
      final pomodoroCount = (task.durationMinutes / 25).ceil();
      final completedPomodoros = pomodoroCount - _random.nextInt(2);
      task = task.copyWith(
        description: '[Pomodoro: $completedPomodoros completed, Total work: ${completedPomodoros * 25} min]',
      );
    }

    await _db.insertTask(task);
  }

  Future<void> _createCommunicationBlock(DateTime date) async {
    final meetings = [
      'Team standup',
      'Client meeting',
      'Project review',
      'One-on-one',
      'Department sync',
    ];

    final meetingCount = 1 + _random.nextInt(2); // 1-2 meetings
    for (int i = 0; i < meetingCount; i++) {
      final isCompleted = date.isBefore(DateTime.now()) && _random.nextDouble() < 0.85;
      final duration = 30 + _random.nextInt(30); // 30-60 minutes
      final scheduledStartTime = DateTime(date.year, date.month, date.day, 14 + i, 0);

      final task = Task(
        title: meetings[_random.nextInt(meetings.length)],
        durationMinutes: duration,
        priority: Priority.medium,
        energyRequired: EnergyLevel.medium,
        focusRequired: FocusLevel.medium,
        taskCategory: TaskCategory.communication,
        scheduledStartTime: scheduledStartTime,
        status: isCompleted ? TaskStatus.completed : TaskStatus.scheduled,
        completedAt: isCompleted ? scheduledStartTime.add(Duration(minutes: duration)) : null,
      );

      await _db.insertTask(task);
    }
  }

  Future<void> _createEndOfDayRoutine(DateTime date) async {
    final isCompleted = date.isBefore(DateTime.now()) && _random.nextDouble() < 0.7;
    final scheduledStartTime = DateTime(date.year, date.month, date.day, 17, 0);

    final task = Task(
      title: 'Plan tomorrow\'s tasks',
      durationMinutes: 30,
      priority: Priority.low,
      energyRequired: EnergyLevel.low,
      focusRequired: FocusLevel.light,
      taskCategory: TaskCategory.routine,
      scheduledStartTime: scheduledStartTime,
      status: isCompleted ? TaskStatus.completed : TaskStatus.scheduled,
      completedAt: isCompleted ? scheduledStartTime.add(const Duration(minutes: 30)) : null,
    );

    await _db.insertTask(task);
  }

  // Clear all tasks (useful for testing)
  Future<void> clearAllTasks() async {
    final db = await _db.database;
    await db.delete('tasks');
    print('All tasks cleared from database');
  }
}