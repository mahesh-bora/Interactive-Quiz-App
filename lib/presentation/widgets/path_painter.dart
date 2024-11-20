import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/question_provider.dart';

class LevelPathPainter extends CustomPainter {
  final int activeLevel;
  final double progress;
  final List<Offset> positions;
  final int lastDrawnLevel;

  LevelPathPainter({
    required this.activeLevel,
    required this.progress,
    required this.positions,
    required this.lastDrawnLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activeLevel < 0) return;

    final inactivePaint = Paint()
      ..color = Color(0xFF464758)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Draw the full path in inactive color
    final fullPath = Path();
    fullPath.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 0; i < positions.length - 1; i++) {
      final current = positions[i];
      final next = positions[i + 1];
      final midY = (current.dy + next.dy) / 2;

      fullPath.cubicTo(current.dx, midY, next.dx, midY, next.dx, next.dy);
    }

    canvas.drawPath(fullPath, inactivePaint);

    // Draw green path for completed levels
    final greenPath = Path();
    greenPath.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 0; i < lastDrawnLevel + 1; i++) {
      final current = positions[i];
      if (i < lastDrawnLevel) {
        final next = positions[i + 1];
        final midY = (current.dy + next.dy) / 2;

        greenPath.cubicTo(current.dx, midY, next.dx, midY, next.dx, next.dy);
      }
    }

    canvas.drawPath(greenPath, activePaint);

    // Draw animated path for the current active segment
    if (activeLevel > lastDrawnLevel) {
      final activePath = Path();
      activePath.moveTo(
          positions[lastDrawnLevel].dx, positions[lastDrawnLevel].dy);

      for (int i = lastDrawnLevel; i <= activeLevel; i++) {
        final current = positions[i];
        if (i < activeLevel) {
          final next = positions[i + 1];
          final midY = (current.dy + next.dy) / 2;

          activePath.cubicTo(current.dx, midY, next.dx, midY, next.dx, next.dy);
        }
      }

      // Animate only the active segment
      PathMetrics pathMetrics = activePath.computeMetrics();
      Path animatedPath = Path();

      for (PathMetric metric in pathMetrics) {
        double length = metric.length;
        Path extractPath = metric.extractPath(0, length * progress);
        animatedPath.addPath(extractPath, Offset.zero);
      }

      canvas.drawPath(animatedPath, activePaint);
    }
  }

  @override
  bool shouldRepaint(LevelPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeLevel != activeLevel ||
        oldDelegate.lastDrawnLevel != lastDrawnLevel;
  }

  /// Static method to get the active level from the context
  static int getActiveLevelFromState(BuildContext context) {
    final questionState = context.read<QuestionState>();
    final levels = [
      "Adjectives",
      "Adverbs",
      "Conjunctions",
      "Prefix & Suffix",
      "Sentence Structure",
      "Verbs"
    ];

    for (int i = levels.length - 1; i >= 0; i--) {
      if (questionState.isLevelUnlocked(levels[i])) {
        return i;
      }
    }
    return 0; // Default to the first level
  }
}
