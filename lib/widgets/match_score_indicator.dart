import 'package:flutter/material.dart';

class MatchScoreIndicator extends StatelessWidget {
  final double score; // 0.0 to 1.0
  final List<String> reasons;
  final bool expanded;

  const MatchScoreIndicator({
    Key? key,
    required this.score,
    required this.reasons,
    this.expanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIcon(),
              color: _getColor(),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getLabel(),
              style: TextStyle(
                color: _getColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                color: _getColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (expanded && reasons.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: _getColor()),
                ),
                Expanded(
                  child: Text(
                    reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Color _getColor() {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getIcon() {
    if (score >= 0.8) return Icons.check_circle;
    if (score >= 0.6) return Icons.info;
    return Icons.warning;
  }

  String _getLabel() {
    if (score >= 0.8) return 'Excellent Match';
    if (score >= 0.6) return 'Good Match';
    if (score >= 0.4) return 'Fair Match';
    return 'Poor Match';
  }
}