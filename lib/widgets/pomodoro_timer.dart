import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../providers/pomodoro_provider.dart';

class PomodoroTimer extends StatelessWidget {
  final String timeString;
  final double progress;
  final PomodoroState state;

  const PomodoroTimer({
    Key? key,
    required this.timeString,
    required this.progress,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.7;
    final strokeWidth = size * 0.06;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              progressColor: _getProgressColor(context),
              strokeWidth: strokeWidth,
            ),
          ),

          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeString,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
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

  Color _getProgressColor(BuildContext context) {
    switch (state) {
      case PomodoroState.working:
        return Theme.of(context).colorScheme.primary;
      case PomodoroState.shortBreak:
        return Colors.green;
      case PomodoroState.longBreak:
        return Colors.blue;
      case PomodoroState.paused:
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getStateText() {
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

class CircularProgressPainter extends CustomPainter {
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}