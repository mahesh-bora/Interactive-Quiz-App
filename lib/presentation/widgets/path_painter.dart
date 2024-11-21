import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/question_provider.dart';

class LevelPathPainter extends CustomPainter {
  final int activeLevel;
  final double progress;
  final List<Offset> positions;
  final int lastDrawnLevel;

  final AnimationController? animationController;

  LevelPathPainter({
    required this.activeLevel,
    required this.progress,
    required this.positions,
    required this.lastDrawnLevel,
    this.animationController,
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

    final fullPath = Path();
    fullPath.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 0; i < positions.length - 1; i++) {
      final current = positions[i];
      final next = positions[i + 1];
      final midY = (current.dy + next.dy) / 2;

      fullPath.cubicTo(current.dx, midY, next.dx, midY, next.dx, next.dy);
    }

    fullPath.cubicTo(
        positions.last.dx, positions.last.dy + 100, 300, 900 - 100, 300, 900);

    canvas.drawPath(fullPath, inactivePaint);

    // Slow, gradual green path animation
    final completedPath = Path();
    completedPath.moveTo(positions[0].dx, positions[0].dy);

    int segmentsToFill = (lastDrawnLevel + 1);

    for (int i = 0; i < segmentsToFill - 1; i++) {
      final current = positions[i];
      final next = positions[i + 1];
      final midY = (current.dy + next.dy) / 2;

      // For the last segment, use progress to partially fill
      if (i == segmentsToFill - 2) {
        final partialPath = Path();
        partialPath.moveTo(current.dx, current.dy);
        partialPath.cubicTo(current.dx, midY, next.dx, midY, next.dx, next.dy);

        PathMetric pathMetric = partialPath.computeMetrics().first;
        Path extractedPath =
            pathMetric.extractPath(0.0, pathMetric.length * progress);

        canvas.drawPath(completedPath, activePaint);
        canvas.drawPath(extractedPath, activePaint);
      } else {
        completedPath.cubicTo(
            current.dx, midY, next.dx, midY, next.dx, next.dy);
        canvas.drawPath(completedPath, activePaint);
      }
    }

    // If Verbs level is unlocked, draw the full green extension
    if (isVerbsUnlocked(activeLevel)) {
      final verbsExtensionPath = Path();
      verbsExtensionPath.moveTo(positions.last.dx, positions.last.dy);
      verbsExtensionPath.cubicTo(
          positions.last.dx, positions.last.dy + 100, 300, 900 - 100, 300, 900);
      canvas.drawPath(verbsExtensionPath, activePaint);
    }
  }

  // Helper method to check if Verbs level is unlocked
  bool isVerbsUnlocked(int activeLevel) {
    return activeLevel == 5;
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
