import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../services/pomodoro_settings_service.dart';
import 'task_provider.dart';

// 番茄钟状态枚举
enum PomodoroState {
  idle,  // 空闲状态
  working,  // 工作中
  shortBreak, // 短休息
  longBreak,  // 长休息
  paused,  // 暂停
}

// 类定义与成员变量
class PomodoroProvider with ChangeNotifier {
  // 具有默认值的动态持续时间
  int _workDuration = 25 * 60;  // 默认25分钟
  int _shortBreakDuration = 5 * 60;  // 默认五分钟
  int _longBreakDuration = 15 * 60;  // 默认十五分钟
  int _pomodorosUntilLongBreak = 4;  // 默认四个番茄时钟进行休息

  // 设置里的初始化
  PomodoroSettings? _currentSettings;  // 当前的番茄钟设置对象
  bool _isInitialized = false;  // 标记是否已完成初始化

  // 当前正在进行的任务
  Task? _currentTask;
  // 当前番茄钟的状态
  PomodoroState _state = PomodoroState.idle;
  // 当前阶段剩余秒数
  int _remainingSeconds = 25 * 60;  // 默认工作时长
  // 已经完成的番茄时钟数量
  int _completedPomodoros = 0;
  // 总工作分钟数
  int _totalWorkMinutes = 0;
  // 总休息分钟数(还没用到,之后可能加到统计部分)
  int _totalBreakMinutes = 0;
  // 定时器对象
  Timer? _timer;
  // 会话开始时间
  DateTime? _sessionStartTime;
  // 每个番茄时钟完成的时间戳列表
  List<DateTime> _pomodoroTimestamps = [];

  // 构造函数
  PomodoroProvider() {
    _loadSettings();
  }

  bool get isInitialized => _isInitialized;

  // 设置的加载和应用
  Future<void> _loadSettings() async {
    try {
      // 异步加载保存的设置
      _currentSettings = await PomodoroSettingsService.loadSettings();
      // 应用加载的设置
      _applySettings(_currentSettings!);
      // 标记初始化完成
      _isInitialized = true;
      // 通知监听者更新UI
      notifyListeners();
    } catch (e) {
      // 如果加载失败会使用默认设置
      _currentSettings = PomodoroSettings.defaultSettings;
      _applySettings(_currentSettings!);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // 应用设置
  void _applySettings(PomodoroSettings settings) {
    _workDuration = settings.workDuration * 60; // 转换成秒
    _shortBreakDuration = settings.shortBreakDuration * 60;
    _longBreakDuration = settings.longBreakDuration * 60;
    _pomodorosUntilLongBreak = settings.pomodorosUntilLongBreak;

    // 如果当前是空闲状态,更新剩余时间为新的工作时长
    if (_state == PomodoroState.idle) {
      _remainingSeconds = _workDuration;
    }
  }

  // 设置更新
  Future<void> updateSettings(PomodoroSettings settings) async {
    // 异步保存新设置
    await PomodoroSettingsService.saveSettings(settings);
    //应用到当前状态
    _currentSettings = settings;
    _applySettings(settings);
    // 通知UI更新
    notifyListeners();
  }

  // Getters方法
  // 提供对私有状态的只读访问
  Task? get currentTask => _currentTask;
  PomodoroState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedPomodoros => _completedPomodoros;
  int get totalWorkMinutes => _totalWorkMinutes;
  PomodoroSettings? get settings => _currentSettings;

  // 格式化时间
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 进度计算
  double get progress {
    // 如果是空闲或暂停状态，返回0
    if (_state == PomodoroState.idle) {
      return 0.0;
    }

    // 获取当前阶段的总秒数（已经考虑了部分番茄钟）
    final total = _totalSeconds;
    if (total == 0) return 0.0;

    // 计算已经过去的时间
    final elapsed = total - _remainingSeconds;
    return elapsed / total;

    /* 原版本代码 - 存在部分番茄钟进度条只走到50%的bug
    int totalSeconds;
    switch (_state) {
      case PomodoroState.working:
        totalSeconds = _workDuration;
        break;
      case PomodoroState.shortBreak:
        totalSeconds = _shortBreakDuration;
        break;
      case PomodoroState.longBreak:
        totalSeconds = _longBreakDuration;
        break;
      default:
        return 0.0;
    }
    return (_totalSeconds - _remainingSeconds) / totalSeconds;
    */
  }

  // 获取当前阶段总时长
  int get _totalSeconds {
    switch (_state) {
      case PomodoroState.working:
        // 对于工作状态，检查是否是部分番茄钟
        final remainingMinutes = getRemainingWorkMinutes();
        // 判断是否是"部分番茄钟"
        if (remainingMinutes > 0 && remainingMinutes < (_workDuration ~/ 60)) {
          // 如果是，返回实际需要的时间
          return remainingMinutes * 60;
        }
        // 否则返回完整的阶段时长
        return _workDuration;
      case PomodoroState.shortBreak:
        // 返回短暂休息时长
        return _shortBreakDuration;
      case PomodoroState.longBreak:
        // 返回长期休息时长
        return _longBreakDuration;
      default:
        // 返回设定工作时长
        return _workDuration;
    }
  }

  // 估算所需番茄钟数
  int getEstimatedPomodoros(Task task) {
    // 根据任务时长和番茄时钟时长计算需要多少个番茄时钟
    final workMinutes = _currentSettings?.workDuration ?? 25;
    // 向上取整
    return (task.durationMinutes / workMinutes).ceil();
  }

  // 开始番茄时钟会话
  void startSession(Task task, TaskProvider taskProvider) {
    // 等待加载后再开始
    if (!_isInitialized) {
      // 否则直接使用默认值
      _loadSettings().then((_) {
        _startSessionInternal(task, taskProvider);
      });
      return;
    }

    _startSessionInternal(task, taskProvider);
  }

  // 初始化所有状态变量
  void _startSessionInternal(Task task, TaskProvider taskProvider) {
    _currentTask = task;
    _state = PomodoroState.working;
    _remainingSeconds = _workDuration;
    _completedPomodoros = 0;
    _totalWorkMinutes = 0;
    _totalBreakMinutes = 0;
    _sessionStartTime = DateTime.now();
    _pomodoroTimestamps = [];

    // 如果任务还未开始,更新任务状态为进行中
    if (task.actualStartTime == null) {
      final updatedTask = task.copyWith(
        actualStartTime: DateTime.now(),
        status: TaskStatus.inProgress,
      );
      taskProvider.updateTask(updatedTask);
      _currentTask = updatedTask;
    }

    // 启动定时器
    _startTimer();
    // 通知UI更新
    notifyListeners();
  }

  // 控制方法:开始/恢复
  void start() {
    // 如果是暂停的状态,胡斐到之前的状态
    if (_state == PomodoroState.paused) {
      _state = _previousState;
    } else if (_state == PomodoroState.idle && _currentTask != null) {
      // 如果是空闲且有任务,开始新的工作阶段
      _state = PomodoroState.working;
      _remainingSeconds = _workDuration;
    }
    _startTimer();
    notifyListeners();
  }

  // 暂停计时器
  PomodoroState _previousState = PomodoroState.idle;
  // 保存当前状态,切换到暂停状态,取消定时器
  void pause() {
    if (_state == PomodoroState.working ||
        _state == PomodoroState.shortBreak ||
        _state == PomodoroState.longBreak) {
      _previousState = _state;
      _state = PomodoroState.paused;
      _timer?.cancel();
      notifyListeners();
    }
  }

  // 跳过休息
  void skipBreak() {
    // 如果在休息阶段,跳过并开始新的番茄时钟
    if (_state == PomodoroState.shortBreak || _state == PomodoroState.longBreak) {
      _timer?.cancel();
      _startNewPomodoro();
    }
  }

  // 放弃当时的番茄时钟
  void abandon() {
    // 取消定时器
    _timer?.cancel();
    // 回到空闲状态
    _state = PomodoroState.idle;
    notifyListeners();
  }

  // 完成任务
  void completeTask(TaskProvider taskProvider) {
    if (_currentTask == null) return;

    final updatedTask = _currentTask!.copyWith(
      // 更新任务的结束时间和状态
      actualEndTime: DateTime.now(),
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );

    // 将番茄时钟统计数据追加到任务描述中
    final pomodoroData = '\n---\n[Pomodoro: $_completedPomodoros completed, '
        'Total work: $_totalWorkMinutes min]';

    final newDescription = (updatedTask.description ?? '') + pomodoroData;
    final finalTask = updatedTask.copyWith(description: newDescription);

    // 通过TaskProvider更新任务
    taskProvider.updateTask(finalTask);

    // 重置番茄时钟状态
    _timer?.cancel();
    _state = PomodoroState.idle;
    _currentTask = null;
    notifyListeners();
  }

  // 启动定时器
  void _startTimer() {
    // 取消之前的定时器
    _timer?.cancel();
    // 创建每秒执行一次的定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 每秒减少剩余时间并通知UI
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // 时间到达0时调用完成处理
        _onTimerComplete();
      }
    });
  }

  // 定时器完成处理
  void _onTimerComplete() {
    _timer?.cancel();

    switch (_state) {
      case PomodoroState.working:
      // 计算实际工作时间
        final actualMinutesThisPomodoro = _getLastPomodoroMinutes();
        _completedPomodoros++;
        _totalWorkMinutes += actualMinutesThisPomodoro;
        _pomodoroTimestamps.add(DateTime.now());

        // 检查任务是否已经完成
        if (_isTaskTimeCompleted()) {
          // 任务时间完成，显示完成选项
          _state = PomodoroState.idle;
          _showTaskCompletionNotification();
        } else {
          // 决定下一个休息类型
          if (_completedPomodoros % _pomodorosUntilLongBreak == 0) {
            _state = PomodoroState.longBreak;
            _remainingSeconds = _longBreakDuration;
          } else {
            _state = PomodoroState.shortBreak;
            _remainingSeconds = _shortBreakDuration;
          }
          _startTimer(); // Start timer for break
        }

        // TODO: 显示通知
        _showCompletionNotification();
        break;

      case PomodoroState.shortBreak:
        _totalBreakMinutes += (_shortBreakDuration ~/ 60);
        _startNewPomodoro();
        break;

      case PomodoroState.longBreak:
        _totalBreakMinutes += (_longBreakDuration ~/ 60);
        _startNewPomodoro();
        break;

      default:
        break;
    }

    notifyListeners();
  }

  // 获取最后一个番茄钟的实际分钟数
  int _getLastPomodoroMinutes() {
    if (_currentTask == null) return _workDuration ~/ 60;

    final workMinutes = _currentSettings?.workDuration ?? 25;

    // 计算这个番茄钟前已经工作了多少分钟
    final minutesBeforeThisPomodoro = (_completedPomodoros) * workMinutes;

    // 如果超过任务持续时间，则仅返回剩余的分钟数
    if (minutesBeforeThisPomodoro + workMinutes > _currentTask!.durationMinutes) {
      return _currentTask!.durationMinutes - minutesBeforeThisPomodoro;
    }

    return workMinutes;
  }

  // 检查任务时间是否完成
  bool _isTaskTimeCompleted() {
    if (_currentTask == null) return false;
    return _totalWorkMinutes >= _currentTask!.durationMinutes;
  }

  // 获取剩余工作分钟数
  int getRemainingWorkMinutes() {
    if (_currentTask == null) return 0;
    return (_currentTask!.durationMinutes - _totalWorkMinutes).clamp(0, _workDuration ~/ 60);
  }

  // 开始新的番茄钟
  void _startNewPomodoro() {
    final remainingMinutes = getRemainingWorkMinutes();

    if (remainingMinutes <= 0) {
      // 任务完成
      _state = PomodoroState.idle;
      _showTaskCompletionNotification();
    } else {
      _state = PomodoroState.working;
      // 如果剩余时间低于工作持续时间,用剩余时间来替换
      _remainingSeconds = remainingMinutes < (_workDuration ~/ 60) ? remainingMinutes * 60 : _workDuration;
      _startTimer();
    }
    notifyListeners();
  }

  void _showCompletionNotification() {
    // TODO: 实现实际通知
    debugPrint('Pomodoro completed! Time for a break.');
  }

  void _showTaskCompletionNotification() {
    // TODO: 实现实际通知
    debugPrint('Task time completed! You can mark it as done.');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}