import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import 'task_provider.dart';

enum PomodoroState {
  idle,
  working,
  shortBreak,
  longBreak,
  paused,
}

class PomodoroProvider with ChangeNotifier {
  static const int workDuration = 25 * 60; // 25 minutes in seconds
  static const int shortBreakDuration = 5 * 60; // 5 minutes in seconds
  static const int longBreakDuration = 15 * 60; // 15 minutes in seconds
  static const int pomodorosUntilLongBreak = 4;

  Task? _currentTask;
  PomodoroState _state = PomodoroState.idle;
  int _remainingSeconds = workDuration;
  int _completedPomodoros = 0;
  int _totalWorkMinutes = 0;
  int _totalBreakMinutes = 0;
  Timer? _timer;
  DateTime? _sessionStartTime;
  List<DateTime> _pomodoroTimestamps = [];

  // Getters
  Task? get currentTask => _currentTask;
  PomodoroState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedPomodoros => _completedPomodoros;
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    int totalSeconds;
    switch (_state) {
      case PomodoroState.working:
        totalSeconds = workDuration;
        break;
      case PomodoroState.shortBreak:
        totalSeconds = shortBreakDuration;
        break;
      case PomodoroState.longBreak:
        totalSeconds = longBreakDuration;
        break;
      default:
        return 0.0;
    }
    return (_totalSeconds - _remainingSeconds) / totalSeconds;
  }

  int get _totalSeconds {
    switch (_state) {
      case PomodoroState.working:
        return workDuration;
      case PomodoroState.shortBreak:
        return shortBreakDuration;
      case PomodoroState.longBreak:
        return longBreakDuration;
      default:
        return workDuration;
    }
  }

  // Calculate estimated pomodoros needed
  int getEstimatedPomodoros(Task task) {
    return (task.durationMinutes / 25).ceil();
  }

  // Initialize pomodoro session
  void startSession(Task task, TaskProvider taskProvider) {
    _currentTask = task;
    _state = PomodoroState.working;
    _remainingSeconds = workDuration;
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
      _remainingSeconds = workDuration;
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
        _completedPomodoros++;
        _totalWorkMinutes += 25;
        _pomodoroTimestamps.add(DateTime.now());

        // Determine break type
        if (_completedPomodoros % pomodorosUntilLongBreak == 0) {
          _state = PomodoroState.longBreak;
          _remainingSeconds = longBreakDuration;
        } else {
          _state = PomodoroState.shortBreak;
          _remainingSeconds = shortBreakDuration;
        }

        // TODO: Show notification
        _showCompletionNotification();
        break;

      case PomodoroState.shortBreak:
        _totalBreakMinutes += 5;
        _startNewPomodoro();
        break;

      case PomodoroState.longBreak:
        _totalBreakMinutes += 15;
        _startNewPomodoro();
        break;

      default:
        break;
    }

    notifyListeners();
  }

  void _startNewPomodoro() {
    _state = PomodoroState.working;
    _remainingSeconds = workDuration;
    _startTimer();
    notifyListeners();
  }

  void _showCompletionNotification() {
    // TODO: Implement actual notification
    // For now, this is a placeholder
    debugPrint('Pomodoro completed! Time for a break.');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}