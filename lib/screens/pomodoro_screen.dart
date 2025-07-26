import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../widgets/pomodoro_timer.dart';

// PomodoroScreen类定义
class PomodoroScreen extends StatefulWidget {
  // 接受要执行的任务
  final Task task;

  const PomodoroScreen({
    Key? key,
    // 必须传入一个任务
    required this.task,
  }) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

// _PomodoroScreenState类和初始化
class _PomodoroScreenState extends State<PomodoroScreen> {
  // 加载番茄时钟状态管理器
  late PomodoroProvider pomodoroProvider;

  @override
  // 创建新的Provider实例
  void initState() {
    super.initState();
    pomodoroProvider = PomodoroProvider();
    // 在第一帧渲染后启动番茄钟会话
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      pomodoroProvider.startSession(widget.task, taskProvider);
    });
  }

  // 清理资源
  @override
  void dispose() {
    pomodoroProvider.dispose(); // 释放计时器资源
    super.dispose();
  }

  // 处理退出时恢复任务状态
  Future<void> _handleExit() async {
    final taskProvider = context.read<TaskProvider>();
    final currentTask = pomodoroProvider.currentTask;

    if (currentTask != null && currentTask.status == TaskStatus.inProgress) {
      // 恢复任务到之前的状态（已安排或待办）
      final previousStatus = currentTask.scheduledStartTime != null
          ? TaskStatus.scheduled  // 如果有计划时间,恢复为已安排
          : TaskStatus.pending;  // 否则恢复为代办

      final updatedTask = currentTask.copyWith(
        status: previousStatus,
        // 保留实际开始时间，以便下次继续
      );

      await taskProvider.updateTask(updatedTask);
    }
  }

  @override
  // 构建UI
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      // 提供Provider给子组件
      value: pomodoroProvider,
      // 监听返回按钮
      child: WillPopScope(
        onWillPop: () async {
          // 显示退出确认
          final shouldPop = await _showExitConfirmation();
          if (shouldPop) {
            // 处理退出逻辑
            await _handleExit();
          }
          return shouldPop;
        },
        // 主界面结构
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Focus Timer'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          // 监听Provider变化
          body: Consumer<PomodoroProvider>(
            builder: (context, provider, child) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // 任务信息卡片
                      _buildTaskInfo(provider),

                      const SizedBox(height: 32),

                      // 计时器显示
                      Expanded(
                        child: PomodoroTimer(
                          timeString: provider.formattedTime,
                          progress: provider.progress,
                          state: provider.state,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 控制按钮
                      _buildControlButtons(provider),

                      const SizedBox(height: 24),

                      // 进度指示器
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

  // 任务信息显示
  Widget _buildTaskInfo(PomodoroProvider provider) {
    // 通过provider计算这个任务预计需要多少个番茄钟
    final estimatedPomodoros = provider.getEstimatedPomodoros(widget.task);
    // 获取当前任务剩余的工作分钟数
    final remainingMinutes = provider.getRemainingWorkMinutes();
    // 获取每个番茄钟的工作时长，默认25分钟
    final workDuration = provider.settings?.workDuration ?? 25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              // 显示任务标题
              widget.task.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // 显示任务时长和预计需要的番茄钟数
              'Duration: ${widget.task.durationMinutes} minutes (≈$estimatedPomodoros × ${workDuration}min)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            // 不足一个完整番茄钟的提示
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
            // 休息时间提示
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

  // 控制按钮
  Widget _buildControlButtons(PomodoroProvider provider) {
    final state = provider.state;

    if (state == PomodoroState.idle) {
      return ElevatedButton.icon(
        // 空闲状态：显示"开始专注"按钮
        onPressed: () => provider.start(),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Focus'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    return Row(
      // 工作/休息状态：显示暂停和放弃按钮
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
          // 暂停状态：显示继续和放弃按钮
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

  // 进度指示器
  Widget _buildProgressIndicator(PomodoroProvider provider) {
    // 预计需要的番茄钟总数
    final estimatedPomodoros = provider.getEstimatedPomodoros(widget.task);
    // 判断是否已达到任务计划时间
    final isTaskTimeCompleted = provider.totalWorkMinutes >= widget.task.durationMinutes;

    // 显示已完成的番茄钟数量
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 火焰图标
            const Icon(Icons.local_fire_department, size: 20),
            const SizedBox(width: 8),
            Text(
              'Completed: ${provider.completedPomodoros}/$estimatedPomodoros',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 显示实际工作时间
        Text(
          'Work time: ${provider.totalWorkMinutes}/${widget.task.durationMinutes} minutes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        // 可视化进度圆点
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            // 生成预计番茄钟数量的圆点
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
        // 条件显示完成按钮
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

  // 对话框方法
  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Focus Timer?'),
        // 退出确认对话框：提醒用户进度会保存但计时器会停止
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
          // 放弃确认对话框：警告用户当前番茄钟不会被计入
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

  // 完成任务
  void _completeTask(PomodoroProvider provider) {
    final taskProvider = context.read<TaskProvider>();
    // 调用Provider完成任务
    provider.completeTask(taskProvider);

    // 关闭页面
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