import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';
import 'database_service.dart';

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final UserTimeBlock? timeBlock;
  final double score;
  final List<String> reasons;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.timeBlock,
    required this.score,
    required this.reasons,
  });

  Duration get duration => endTime.difference(startTime);
}

class SchedulerService {
  final DatabaseService _db = DatabaseService.instance;

  // 为任务推荐时间段
  Future<List<TimeSlot>> recommendTimeSlots(
      Task task,
      DateTime targetDate,
      ) async {
    // 1. 获取目标日期是星期几
    final dayOfWeek = targetDate.weekday;

    // 2. 获取该天的所有时间块
    final timeBlocks = await _db.getTimeBlocksByDay(dayOfWeek);
    if (timeBlocks.isEmpty) return [];

    // 3. 获取该天已安排的任务
    final existingTasks = await _db.getTasksByDate(targetDate);

    // 4. 生成可用时间段并评分
    final availableSlots = <TimeSlot>[];

    for (final block in timeBlocks) {
      final slots = _generateSlotsFromBlock(
        block,
        targetDate,
        task,
        existingTasks,
      );
      availableSlots.addAll(slots);
    }

    // 5. 按分数排序
    availableSlots.sort((a, b) => b.score.compareTo(a.score));

    // 6. 返回前3个推荐
    return availableSlots.take(3).toList();
  }

  // 从时间块生成可用时间段
  List<TimeSlot> _generateSlotsFromBlock(
      UserTimeBlock block,
      DateTime date,
      Task task,
      List<Task> existingTasks,
      ) {
    final slots = <TimeSlot>[];

    // 解析时间块的开始和结束时间
    final blockStart = _parseTimeToDateTime(date, block.startTime);
    final blockEnd = _parseTimeToDateTime(date, block.endTime);

    // 查找时间块内的可用时段
    DateTime currentStart = blockStart;

    while (currentStart.add(Duration(minutes: task.durationMinutes))
        .isBefore(blockEnd) ||
        currentStart.add(Duration(minutes: task.durationMinutes))
            .isAtSameMomentAs(blockEnd)) {

      final currentEnd = currentStart.add(Duration(minutes: task.durationMinutes));

      // 检查是否与现有任务冲突
      if (!_hasConflict(currentStart, currentEnd, existingTasks)) {
        // 计算匹配分数
        final score = _calculateScore(task, block, currentStart);
        final reasons = _generateReasons(task, block, score);

        slots.add(TimeSlot(
          startTime: currentStart,
          endTime: currentEnd,
          timeBlock: block,
          score: score,
          reasons: reasons,
        ));
      }

      // 移动到下一个时间段（15分钟间隔）
      currentStart = currentStart.add(const Duration(minutes: 15));
    }

    return slots;
  }

  // 解析时间字符串到DateTime
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

  // 检查时间冲突
  bool _hasConflict(
      DateTime start,
      DateTime end,
      List<Task> existingTasks,
      ) {
    for (final task in existingTasks) {
      if (task.scheduledStartTime == null) continue;

      final taskEnd = task.scheduledEndTime!;

      // 检查是否有重叠
      if (!(end.isBefore(task.scheduledStartTime!) ||
          start.isAfter(taskEnd) ||
          start.isAtSameMomentAs(taskEnd))) {
        return true;
      }
    }
    return false;
  }

  // 计算匹配分数
  double _calculateScore(
      Task task,
      UserTimeBlock block,
      DateTime proposedStart,
      ) {
    double score = 0;

    // 1. 能量匹配度（25分）
    if (task.energyRequired == block.energyLevel) {
      score += 25;
    } else if (block.energyLevel.value > task.energyRequired.value) {
      score += 15; // 向下兼容
    }

    // 2. 专注度匹配（25分）
    if (task.focusRequired == block.focusLevel) {
      score += 25;
    } else if (block.focusLevel.value > task.focusRequired.value) {
      score += 10; // 过度满足
    }

    // 3. 任务类型匹配（25分）
    if (block.suitableCategories.contains(task.taskCategory)) {
      score += 25;
    } else {
      score += 10; // 不在列表但不冲突
    }

    // 4. 优先级匹配（25分）
    if (block.suitablePriorities.contains(task.priority)) {
      if (task.priority == Priority.high &&
          block.energyLevel == EnergyLevel.high) {
        score += 25; // 高优先级 + 黄金时间
      } else {
        score += 15; // 一般匹配
      }
    } else if (task.priority == Priority.low &&
        block.energyLevel == EnergyLevel.high) {
      score += 5; // 避免浪费
    } else {
      score += 10;
    }

    // 5. 加分项
    // 时间利用率
    final blockDuration = block.durationMinutes;
    final taskDuration = task.durationMinutes;
    final waste = blockDuration - taskDuration;
    if (waste >= 0 && waste <= 15) {
      score += 5; // 时间利用率高
    }

    // 早晨加分（如果是高优先级任务）
    if (task.priority == Priority.high && proposedStart.hour < 12) {
      score += 5;
    }

    return score;
  }

  // 生成推荐理由
  List<String> _generateReasons(
      Task task,
      UserTimeBlock block,
      double score,
      ) {
    final reasons = <String>[];

    if (score >= 90) {
      reasons.add('Perfect match for your ${block.name}'); // 原来是 '完美匹配您的${block.name}'
    } else if (score >= 70) {
      reasons.add('Good match for ${block.name}');        // 原来是 '较好匹配${block.name}'
    } else {
      reasons.add('Available time slot');                  // 原来是 '可用时间段'
    }

    // 能量匹配说明
    if (task.energyRequired == block.energyLevel) {
      reasons.add('Energy requirement perfectly matched'); // 原来是 '能量需求完全匹配'
    }

    // 专注度说明
    if (task.focusRequired == block.focusLevel) {
      reasons.add('Focus level requirement matched');      // 原来是 '专注度要求匹配'
    }

    // 任务类型说明
    if (block.suitableCategories.contains(task.taskCategory)) {
      reasons.add('Suitable for ${task.taskCategory.displayName} tasks'); // 原来是 '适合${task.taskCategory.displayName}任务'
    }

    return reasons;
  }

  // 检查任务是否可以安排到指定时间
  Future<bool> canScheduleTask(
      Task task,
      DateTime startTime,
      ) async {
    final endTime = startTime.add(Duration(minutes: task.durationMinutes));
    final existingTasks = await _db.getTasksByDate(startTime);

    // 排除当前任务自己（如果是更新）
    final otherTasks = existingTasks.where((t) => t.id != task.id).toList();

    return !_hasConflict(startTime, endTime, otherTasks);
  }

  // 获取时间碎片化分析
  Future<Map<String, dynamic>> analyzeTimeFragmentation(
      DateTime date,
      ) async {
    final tasks = await _db.getTasksByDate(date);
    final dayStart = DateTime(date.year, date.month, date.day, 6, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 22, 0);

    // 计算空闲时间块
    final freeBlocks = <Duration>[];
    DateTime currentTime = dayStart;

    // 按时间排序任务
    tasks.sort((a, b) =>
        a.scheduledStartTime!.compareTo(b.scheduledStartTime!));

    for (final task in tasks) {
      if (task.scheduledStartTime == null) continue;

      if (task.scheduledStartTime!.isAfter(currentTime)) {
        final freeTime = task.scheduledStartTime!.difference(currentTime);
        if (freeTime.inMinutes >= 30) {
          freeBlocks.add(freeTime);
        }
      }

      currentTime = task.scheduledEndTime!;
    }

    // 检查最后一个任务到一天结束
    if (currentTime.isBefore(dayEnd)) {
      final freeTime = dayEnd.difference(currentTime);
      if (freeTime.inMinutes >= 30) {
        freeBlocks.add(freeTime);
      }
    }

    // 分析结果
    final totalFreeMinutes = freeBlocks.fold<int>(
      0,
          (sum, block) => sum + block.inMinutes,
    );

    final fragmentCount = freeBlocks.where(
            (block) => block.inMinutes < 120
    ).length;

    final hasLongBlock = freeBlocks.any(
            (block) => block.inMinutes >= 120
    );

    return {
      'freeBlockCount': freeBlocks.length,
      'totalFreeHours': totalFreeMinutes / 60,
      'fragmentCount': fragmentCount,
      'hasDeepWorkTime': hasLongBlock,
      'averageBlockMinutes': freeBlocks.isEmpty
          ? 0
          : totalFreeMinutes ~/ freeBlocks.length,
      'suggestion': _generateFragmentationSuggestion(
        freeBlocks.length,
        fragmentCount,
        hasLongBlock,
      ),
    };
  }

  String _generateFragmentationSuggestion(
      int blockCount,
      int fragmentCount,
      bool hasLongBlock,
      ) {
    if (blockCount > 5) {
      return 'Your time is quite scattered, consider grouping similar tasks'; // 原来是 '您的时间较为分散，建议将类似任务集中安排'
    } else if (fragmentCount > 3) {
      return 'Multiple time fragments available for simple tasks'; // 原来是 '有较多碎片时间，可以用来处理简单任务'
    } else if (!hasLongBlock) {
      return 'Lacking continuous deep work time, consider adjusting schedule'; // 原来是 '缺少连续的深度工作时间，建议调整日程'
    } else {
      return 'Time arrangement is reasonable, maintain current rhythm'; // 原来是 '时间安排较为合理，保持当前节奏'
    }
  }
}