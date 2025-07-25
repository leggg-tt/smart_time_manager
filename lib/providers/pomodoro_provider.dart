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

class PomodoroProvider with ChangeNotifier {
  // Dynamic durations with default values
  int _workDuration = 25 * 60;  // Default 25 minutes
  int _shortBreakDuration = 5 * 60;  // Default 5 minutes
  int _longBreakDuration = 15 * 60;  // Default 15 minutes
  int _pomodorosUntilLongBreak = 4;  // Default 4 pomodoros

  PomodoroSettings? _currentSettings;
  bool _isInitialized = false;

  Task? _currentTask;
  PomodoroState _state = PomodoroState.idle;
  int _remainingSeconds = 25 * 60;  // Default work duration
  int _completedPomodoros = 0;
  int _totalWorkMinutes = 0;
  int _totalBreakMinutes = 0;
  Timer? _timer;
  DateTime? _sessionStartTime;
  List<DateTime> _pomodoroTimestamps = [];

  PomodoroProvider() {
    _loadSettings();
  }

  bool get isInitialized => _isInitialized;

  // Load settings on initialization
  Future<void> _loadSettings() async {
    try {
      _currentSettings = await PomodoroSettingsService.loadSettings();
      _applySettings(_currentSettings!);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If loading fails, use default settings
      _currentSettings = PomodoroSettings.defaultSettings;
      _applySettings(_currentSettings!);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Apply settings
  void _applySettings(PomodoroSettings settings) {
    _workDuration = settings.workDuration * 60; // Convert to seconds
    _shortBreakDuration = settings.shortBreakDuration * 60;
    _longBreakDuration = settings.longBreakDuration * 60;
    _pomodorosUntilLongBreak = settings.pomodorosUntilLongBreak;

    // Update remaining seconds if idle
    if (_state == PomodoroState.idle) {
      _remainingSeconds = _workDuration;
    }
  }

  // Update settings
  Future<void> updateSettings(PomodoroSettings settings) async {
    await PomodoroSettingsService.saveSettings(settings);
    _currentSettings = settings;
    _applySettings(settings);
    notifyListeners();
  }

  // Getters
  Task? get currentTask => _currentTask;
  PomodoroState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedPomodoros => _completedPomodoros;
  int get totalWorkMinutes => _totalWorkMinutes;
  PomodoroSettings? get settings => _currentSettings;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
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
  }

  int get _totalSeconds {
    switch (_state) {
      case PomodoroState.working:
      // For working state, check if this is a partial pomodoro
        final remainingMinutes = getRemainingWorkMinutes();
        if (remainingMinutes > 0 && remainingMinutes < (_workDuration ~/ 60)) {
          return remainingMinutes * 60;
        }
        return _workDuration;
      case PomodoroState.shortBreak:
        return _shortBreakDuration;
      case PomodoroState.longBreak:
        return _longBreakDuration;
      default:
        return _workDuration;
    }
  }

  // Calculate estimated pomodoros needed based on current settings
  int getEstimatedPomodoros(Task task) {
    final workMinutes = _currentSettings?.workDuration ?? 25;
    return (task.durationMinutes / workMinutes).ceil();
  }

  // Initialize pomodoro session
  void startSession(Task task, TaskProvider taskProvider) {
    // Wait for initialization if needed
    if (!_isInitialized) {
      // Use default values while loading
      _loadSettings().then((_) {
        _startSessionInternal(task, taskProvider);
      });
      return;
    }

    _startSessionInternal(task, taskProvider);
  }

  void _startSessionInternal(Task task, TaskProvider taskProvider) {
    _currentTask = task;
    _state = PomodoroState.working;
    _remainingSeconds = _workDuration;
    _completedPomodoros = 0;
    _totalWorkMinutes = 0;
    _totalBreakMinutes = 0;
    _sessionStartTime = DateTime.now();
    _pomodoroTimestamps = [];

    // Update task status to in progress
    if (task.actualStartTime == null) {
      final updatedTask = task.copyWith(
        actualStartTime: DateTime.now(),
        status: TaskStatus.inProgress,
      );
      taskProvider.updateTask(updatedTask);
      _currentTask = updatedTask;
    }

    _startTimer();
    notifyListeners();
  }

  // Start or resume timer
  void start() {
    if (_state == PomodoroState.paused) {
      _state = _previousState;
    } else if (_state == PomodoroState.idle && _currentTask != null) {
      _state = PomodoroState.working;
      _remainingSeconds = _workDuration;
    }
    _startTimer();
    notifyListeners();
  }

  // Pause timer
  PomodoroState _previousState = PomodoroState.idle;
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

  // Skip break
  void skipBreak() {
    if (_state == PomodoroState.shortBreak || _state == PomodoroState.longBreak) {
      _timer?.cancel();
      _startNewPomodoro();
    }
  }

  // Abandon current pomodoro
  void abandon() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    notifyListeners();
  }

  // Complete task
  void completeTask(TaskProvider taskProvider) {
    if (_currentTask == null) return;

    final updatedTask = _currentTask!.copyWith(
      actualEndTime: DateTime.now(),
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );

    // Save pomodoro data to task (using description field)
    final pomodoroData = '\n---\n[Pomodoro: $_completedPomodoros completed, '
        'Total work: $_totalWorkMinutes min]';

    final newDescription = (updatedTask.description ?? '') + pomodoroData;
    final finalTask = updatedTask.copyWith(description: newDescription);

    taskProvider.updateTask(finalTask);

    _timer?.cancel();
    _state = PomodoroState.idle;
    _currentTask = null;
    notifyListeners();
  }

  // Private methods
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();

    switch (_state) {
      case PomodoroState.working:
      // Calculate actual minutes worked in this pomodoro
        final actualMinutesThisPomodoro = _getLastPomodoroMinutes();
        _completedPomodoros++;
        _totalWorkMinutes += actualMinutesThisPomodoro;
        _pomodoroTimestamps.add(DateTime.now());

        // Check if task is completed
        if (_isTaskTimeCompleted()) {
          // Task time is completed, show completion option
          _state = PomodoroState.idle;
          _showTaskCompletionNotification();
        } else {
          // Determine break type
          if (_completedPomodoros % _pomodorosUntilLongBreak == 0) {
            _state = PomodoroState.longBreak;
            _remainingSeconds = _longBreakDuration;
          } else {
            _state = PomodoroState.shortBreak;
            _remainingSeconds = _shortBreakDuration;
          }
          _startTimer(); // Start timer for break
        }

        // TODO: Show notification
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

  // Get actual minutes worked in the last pomodoro
  int _getLastPomodoroMinutes() {
    if (_currentTask == null) return _workDuration ~/ 60;

    final workMinutes = _currentSettings?.workDuration ?? 25;

    // Calculate how many minutes were already worked before this pomodoro
    final minutesBeforeThisPomodoro = (_completedPomodoros) * workMinutes;

    // If this would exceed task duration, return only the remaining minutes
    if (minutesBeforeThisPomodoro + workMinutes > _currentTask!.durationMinutes) {
      return _currentTask!.durationMinutes - minutesBeforeThisPomodoro;
    }

    return workMinutes;
  }

  // Check if task time is completed
  bool _isTaskTimeCompleted() {
    if (_currentTask == null) return false;
    return _totalWorkMinutes >= _currentTask!.durationMinutes;
  }

  // Get remaining work time
  int getRemainingWorkMinutes() {
    if (_currentTask == null) return 0;
    return (_currentTask!.durationMinutes - _totalWorkMinutes).clamp(0, _workDuration ~/ 60);
  }

  // Start new pomodoro with adjusted duration
  void _startNewPomodoro() {
    final remainingMinutes = getRemainingWorkMinutes();

    if (remainingMinutes <= 0) {
      // Task completed
      _state = PomodoroState.idle;
      _showTaskCompletionNotification();
    } else {
      _state = PomodoroState.working;
      // If remaining time is less than work duration, use that instead
      _remainingSeconds = remainingMinutes < (_workDuration ~/ 60) ? remainingMinutes * 60 : _workDuration;
      _startTimer();
    }
    notifyListeners();
  }

  void _showCompletionNotification() {
    // TODO: Implement actual notification
    debugPrint('Pomodoro completed! Time for a break.');
  }

  void _showTaskCompletionNotification() {
    // TODO: Implement actual notification
    debugPrint('Task time completed! You can mark it as done.');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}