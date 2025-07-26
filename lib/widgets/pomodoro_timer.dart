import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../providers/pomodoro_provider.dart';

// PomodoroTimer类定义
class PomodoroTimer extends StatelessWidget {
  final String timeString;  // 显示的时间字符串
  final double progress;  // 进度值
  final PomodoroState state;  // 当前番茄钟的状态

  // PomodoroTimer类定义
  const PomodoroTimer({
    Key? key,
    required this.timeString,  // 显示的时间字符串
    required this.progress,  // 进度值
    required this.state,  // 当前番茄钟的状态
  }) : super(key: key);

  // 构建方法
  @override
  Widget build(BuildContext context) {
    // 直径
    final size = MediaQuery.of(context).size.width * 0.7;
    //  圆环的粗细
    final strokeWidth = size * 0.06;

    //  计时器居中
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 自定义绘制圆形进度条
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              progressColor: _getProgressColor(context),
              strokeWidth: strokeWidth,
            ),
          ),

          // 时间显示
          Column(
            // 让Column只占用必要的空间
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeString,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              // 状态文本
              const SizedBox(height: 8),
              Text(
                // 显示当前状态的文本描述
                _getStateText(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 状态颜色映射
  Color _getProgressColor(BuildContext context) {
    switch (state) {
      // 工作状态
      case PomodoroState.working:
        return Theme.of(context).colorScheme.primary;
      case PomodoroState.shortBreak:  // 短休息
        return Colors.green;
      case PomodoroState.longBreak:  // 长休息
        return Colors.blue;
      case PomodoroState.paused:  // 暂停
        return Colors.orange;
      default:  // 默认
        return Theme.of(context).colorScheme.primary;
    }
  }

  // 状态文本映射
  String _getStateText() {
    // 将枚举状态转换为用户友好的英文描述
    switch (state) {
      case PomodoroState.working:
        return 'Focus Time';
      case PomodoroState.shortBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break';
      case PomodoroState.paused:
        return 'Paused';
      default:
        return 'Ready';
    }
  }
}

// 自定义画笔类
class CircularProgressPainter extends CustomPainter {
  // 继承CustomPainter以实现自定义绘制
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  // paint方法,核心绘画逻辑
  @override
  void paint(Canvas canvas, Size size) {
    // 计算圆心坐标
    final center = Offset(size.width / 2, size.height / 2);
    // 计算半径(确保圆环不会被裁剪)
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度条画笔设置
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      // 只绘制轮廓不填充
      ..style = PaintingStyle.stroke
      // 圆形端点，使进度条看起来更柔和
      ..strokeCap = StrokeCap.round;

    // 绘制进度弧
    final sweepAngle = 2 * math.pi * progress;  // 扫过的角度
    canvas.drawArc(
      // 创建包含圆的矩形区域
      Rect.fromCircle(center: center, radius: radius),
      // 起始角度
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  // 优化重新画
  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}