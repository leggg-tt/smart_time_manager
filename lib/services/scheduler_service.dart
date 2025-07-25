import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';
import '../models/scheduler_preferences.dart';
import 'database_service.dart';
import 'scheduler_preferences_service.dart';

//定义TimeSlot类
class TimeSlot {
  final DateTime startTime;  // 时间段开始时间
  final DateTime endTime;  // 时间段结束时间
  final UserTimeBlock? timeBlock;  // 关联的用户时间块
  final double score;  // 匹配分数
  final List<String> reasons;  // 推荐理由列表

  TimeSlot({
    required this.startTime,  //必须提供
    required this.endTime,
    this.timeBlock,  // 可选
    required this.score,
    required this.reasons,
  });

  Duration get duration => endTime.difference(startTime);  // 计算时间段持续时间
}

class SchedulerService {
  // 数据库服务单例
  final DatabaseService _db = DatabaseService.instance;
  // 智能评分方案偏好设置
  SchedulerPreferences? _preferences;

  // 智能评分偏好设置初始化
  Future<void> _ensurePreferences() async {
    // 每次都重新加载，确保使用最新的设置
    _preferences = await SchedulerPreferencesService.loadPreferences();
    // 调试用的,后面记得删除
    print('Loaded preferences - Energy weight: ${_preferences?.energyMatchWeight}');
  }

  // 为任务推荐时间段
  Future<List<TimeSlot>> recommendTimeSlots(
      Task task,  // 任务
      DateTime targetDate,  // 目标日期
      ) async {
    // 确保在开始之前偏好设置加载完毕
    await _ensurePreferences();

    // 获取目标日期是星期几
    final dayOfWeek = targetDate.weekday;

    // 获取该天的所有时间块
    final timeBlocks = await _db.getTimeBlocksByDay(dayOfWeek);
    if (timeBlocks.isEmpty) return [];

    // 获取该天已安排的任务(避免发生冲突)
    final existingTasks = await _db.getTasksByDate(targetDate);

    // 生成可用时间段并评分
    final availableSlots = <TimeSlot>[];

    // 遍历所以时间块,调用生成时间段方法,将生成的时间段添加到总列表中
    for (final block in timeBlocks) {
      final slots = _generateSlotsFromBlock(
        block,
        targetDate,
        task,
        existingTasks,
      );
      availableSlots.addAll(slots);
    }

    // 按分数排序
    availableSlots.sort((a, b) => b.score.compareTo(a.score));

    // 返回前3个推荐
    return availableSlots.take(3).toList();
  }

  // 从时间块生成可用时间段
  List<TimeSlot> _generateSlotsFromBlock(
      UserTimeBlock block,  // 时间块
      DateTime date,  // 日期
      Task task,  // 任务
      List<Task> existingTasks,  // 已有任务
      ) {
    // 初始化返回的时间段列表
    final slots = <TimeSlot>[];

    // 解析时间块的开始和结束时间
    final blockStart = _parseTimeToDateTime(date, block.startTime);
    final blockEnd = _parseTimeToDateTime(date, block.endTime);

    // 查找时间块内的可用时段(使用isBefore和isAtSameMomentAs)
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

      // 移动到下一个时间段（基于最小休息时间设置,默认5分钟,台下容易报错）
      final minBreak = _preferences?.minBreakBetweenTasks ?? 5;
      currentStart = currentStart.add(Duration(minutes: minBreak));
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
      //添加 trim() 去除空格,这个之后看着在修改,先不动
      // 解析小时部分
      int.parse(parts[0]),
      // 解析分钟部分
      int.parse(parts[1]),
    );
  }

  // 检查时间冲突
  bool _hasConflict(
      DateTime start,
      DateTime end,
      List<Task> existingTasks,
      ) {
    // 遍历已有任务
    for (final task in existingTasks) {
      // 跳过未安排任务
      if (task.scheduledStartTime == null) continue;

      // 获得任务结束时间
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
    final prefs = _preferences ?? SchedulerPreferences.defaultPreferences;
    double score = 0;

    // 能量匹配度（基于权重）
    if (task.energyRequired == block.energyLevel) {
      score += prefs.energyMatchWeight;
    } else if (block.energyLevel.value > task.energyRequired.value) {
      score += prefs.energyMatchWeight * 0.6; // 向下兼容 60% 分数
    }

    // 专注度匹配（基于权重）
    if (task.focusRequired == block.focusLevel) {
      score += prefs.focusMatchWeight;
    } else if (block.focusLevel.value > task.focusRequired.value) {
      score += prefs.focusMatchWeight * 0.4; // 过度满足 40% 分数
    }

    // 任务类型匹配（基于权重）
    if (block.suitableCategories.contains(task.taskCategory)) {
      score += prefs.categoryMatchWeight;
    } else {
      score += prefs.categoryMatchWeight * 0.4; // 不在列表但不冲突 40% 分数
    }

    // 优先级匹配（基于权重）
    if (block.suitablePriorities.contains(task.priority)) {
      if (task.priority == Priority.high &&
          block.energyLevel == EnergyLevel.high) {
        score += prefs.priorityMatchWeight; // 高优先级 + 黄金时间
      } else {
        score += prefs.priorityMatchWeight * 0.6; // 一般匹配 60% 分数
      }
    } else if (task.priority == Priority.low &&
        block.energyLevel == EnergyLevel.high) {
      score += prefs.priorityMatchWeight * 0.2; // 避免浪费 20% 分数
    } else {
      score += prefs.priorityMatchWeight * 0.4; // 默认 40% 分数
    }

    // 时间利用率（基于权重）
    final blockDuration = block.durationMinutes;
    final taskDuration = task.durationMinutes;
    final waste = blockDuration - taskDuration;
    if (waste >= 0 && waste <= 15) {
      score += prefs.timeUtilizationWeight; // 时间利用率高
    } else if (waste > 15 && waste <= 30) {
      score += prefs.timeUtilizationWeight * 0.5; // 中等利用率
    }

    // 早晨加分（如果是高优先级任务）
    if (prefs.preferMorningForHighPriority &&
        task.priority == Priority.high &&
        proposedStart.hour < 12) {
      score += prefs.morningBoostWeight;
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
      reasons.add('Perfect match for your ${block.name}');
    } else if (score >= 70) {
      reasons.add('Good match for ${block.name}');
    } else {
      reasons.add('Available time slot');
    }

    // 能量匹配说明
    if (task.energyRequired == block.energyLevel) {
      reasons.add('Energy requirement perfectly matched');
    }

    // 专注度说明
    if (task.focusRequired == block.focusLevel) {
      reasons.add('Focus level requirement matched');
    }

    // 任务类型说明
    if (block.suitableCategories.contains(task.taskCategory)) {
      reasons.add('Suitable for ${task.taskCategory.displayName} tasks');
    }

    return reasons;
  }

  // 检查任务是否可以安排到指定时间(task_list_screen和task_provider)
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
    // 空任务列表,逻辑好像有问题后续修改
    tasks.sort((a, b) =>
        a.scheduledStartTime!.compareTo(b.scheduledStartTime!));

    for (final task in tasks) {
      if (task.scheduledStartTime == null) continue;

      if (task.scheduledStartTime!.isAfter(currentTime)) {
        final freeTime = task.scheduledStartTime!.difference(currentTime);
        // 只记录30分钟以上的为空闲块
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
      'freeBlockCount': freeBlocks.length,  // 空闲块总数
      'totalFreeHours': totalFreeMinutes / 60,  // 总空闲小时数
      'fragmentCount': fragmentCount,  // 碎片数量
      'hasDeepWorkTime': hasLongBlock,  // 是否有深度工作时间
      'averageBlockMinutes': freeBlocks.isEmpty  // 平均块时长
          ? 0
          : totalFreeMinutes ~/ freeBlocks.length,
      // 生成建议文本
      'suggestion': _generateFragmentationSuggestion(
        freeBlocks.length,
        fragmentCount,
        hasLongBlock,
      ),
    };
  }

  // 生成碎片化建议
  String _generateFragmentationSuggestion(
      int blockCount,
      int fragmentCount,
      bool hasLongBlock,
      ) {
    if (blockCount > 5) {
      return 'Your time is quite scattered, consider grouping similar tasks';
    } else if (fragmentCount > 3) {
      return 'Multiple time fragments available for simple tasks';
    } else if (!hasLongBlock) {
      return 'Lacking continuous deep work time, consider adjusting schedule';
    } else {
      return 'Time arrangement is reasonable, maintain current rhythm';
    }
  }
}