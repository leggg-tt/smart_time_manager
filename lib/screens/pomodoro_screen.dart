import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../widgets/pomodoro_timer.dart';

class PomodoroScreen extends StatefulWidget {
  final Task task;

  const PomodoroScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late PomodoroProvider pomodoroProvider;

  @override
  void initState() {
    super.initState();
    pomodoroProvider = PomodoroProvider();
    // Start session after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      pomodoroProvider.startSession(widget.task, taskProvider);
    });
  }

  @override
  void dispose() {
    pomodoroProvider.dispose();
    super.dispose();
  }

  // 处理退出时恢复任务状态
  Future<void> _handleExit() async {
    final taskProvider = context.read<TaskProvider>();
    final currentTask = pomodoroProvider.currentTask;

    if (currentTask != null && currentTask.status == TaskStatus.inProgress) {
      // 恢复任务到之前的状态（已安排或待办）
      final previousStatus = currentTask.scheduledStartTime != null
          ? TaskStatus.scheduled
          : TaskStatus.pending;

      final updatedTask = currentTask.copyWith(
        status: previousStatus,
        // 保留实际开始时间，以便下次继续
      );

      await taskProvider.updateTask(updatedTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: pomodoroProvider,
      child: WillPopScope(
        onWillPop: () async {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop) {
            await _handleExit();
          }
          return shouldPop;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Focus Timer'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Consumer<PomodoroProvider>(
            builder: (context, provider, child) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Task info
                      _buildTaskInfo(provider),

                      const SizedBox(height: 32),

                      // Timer display
                      Expanded(
                        child: PomodoroTimer(
                          timeString: provider.formattedTime,
                          progress: provider.progress,
                          state: provider.state,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Control buttons
                      _buildControlButtons(provider),

                      const SizedBox(height: 24),

                      // Progress indicator
                      _buildProgressIndicator(provider),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfo(PomodoroProvider provider) {
    final estimatedPomodoros = provider.getEstimatedPomodoros(widget.task);
    final remainingMinutes = provider.getRemainingWorkMinutes();
    final workDuration = provider.settings?.workDuration ?? 25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${widget.task.durationMinutes} minutes (≈$estimatedPomodoros × ${workDuration}min)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            if (remainingMinutes > 0 && remainingMinutes < workDuration &&
                provider.state == PomodoroState.working) ...[
              const SizedBox(height: 4),
              Text(
                'This pomodoro: $remainingMinutes minutes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (provider.state == PomodoroState.shortBreak ||
                provider.state == PomodoroState.longBreak) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_cafe,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.state == PomodoroState.shortBreak
                        ? 'Take a short break!'
                        : 'Time for a long break!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(PomodoroProvider provider) {
    final state = provider.state;

    if (state == PomodoroState.idle) {
      return ElevatedButton.icon(
        onPressed: () => provider.start(),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Focus'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state == PomodoroState.working ||
            state == PomodoroState.shortBreak ||
            state == PomodoroState.longBreak) ...[
          // 改进的 Pause 按钮样式
          ElevatedButton.icon(
            onPressed: () => provider.pause(),
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          if (state == PomodoroState.shortBreak || state == PomodoroState.longBreak)
            TextButton.icon(
              onPressed: () => provider.skipBreak(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip Break'),
            )
          else
          // 改进的 Give Up 按钮样式，使用 OutlinedButton
            OutlinedButton.icon(
              onPressed: () => _showAbandonConfirmation(provider),
              icon: const Icon(Icons.stop),
              label: const Text('Give Up'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ] else if (state == PomodoroState.paused) ...[
          // Resume 按钮保持绿色，表示积极行动
          ElevatedButton.icon(
            onPressed: () => provider.start(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          // Give Up 按钮保持一致的样式
          OutlinedButton.icon(
            onPressed: () => _showAbandonConfirmation(provider),
            icon: const Icon(Icons.stop),
            label: const Text('Give Up'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(PomodoroProvider provider) {
    final estimatedPomodoros = provider.getEstimatedPomodoros(widget.task);
    final isTaskTimeCompleted = provider.totalWorkMinutes >= widget.task.durationMinutes;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 20),
            const SizedBox(width: 8),
            Text(
              'Completed: ${provider.completedPomodoros}/$estimatedPomodoros',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Show actual work minutes
        Text(
          'Work time: ${provider.totalWorkMinutes}/${widget.task.durationMinutes} minutes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            estimatedPomodoros,
                (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.radio_button_checked,
                size: 16,
                color: index < provider.completedPomodoros
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isTaskTimeCompleted || provider.state == PomodoroState.idle && provider.completedPomodoros > 0)
          ElevatedButton.icon(
            onPressed: () => _completeTask(provider),
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
      ],
    );
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Focus Timer?'),
        content: const Text(
          'Your progress will be saved, but the timer will stop. The task will return to its previous status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showAbandonConfirmation(PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give up current pomodoro?'),
        content: const Text(
          'This pomodoro won\'t be counted. The task will return to its previous status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              provider.abandon();
              Navigator.of(context).pop();

              // 恢复任务状态
              await _handleExit();

              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Give Up'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _completeTask(PomodoroProvider provider) {
    final taskProvider = context.read<TaskProvider>();
    provider.completeTask(taskProvider);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task completed with ${provider.completedPomodoros} pomodoros!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}