import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Donut sederhana dua segmen (selesai vs pending) dengan celah antarsegmen,
/// gradient stroke, dan label angka di tengah.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.done,
    required this.pending,
    required this.doneColor,
    required this.pendingColor,
    this.size = 148,
  });

  final int done;
  final int pending;
  final Color doneColor;
  final Color pendingColor;
  final double size;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.progressAnimation,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.done + widget.pending;
    final percent = total == 0 ? 0 : (widget.done / total * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(widget.size),
              painter: _DonutPainter(
                done: widget.done,
                pending: widget.pending,
                doneColor: widget.doneColor,
                pendingColor: widget.pendingColor,
                emptyColor: AppSurfaces.elevated,
                progress: _animation.value,
              ),
            ),
            child!,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'selesai',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.done,
    required this.pending,
    required this.doneColor,
    required this.pendingColor,
    required this.emptyColor,
    required this.progress,
  });

  final int done;
  final int pending;
  final Color doneColor;
  final Color pendingColor;
  final Color emptyColor;
  final double progress;

  static const _strokeWidth = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint paintFor(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    final total = done + pending;
    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paintFor(emptyColor));
      return;
    }

    // Celah antarsegmen setara ±3px pada keliling lingkaran.
    final gapAngle = 3.0 / radius;
    final segments = [
      (done, doneColor),
      (pending, pendingColor),
    ].where((s) => s.$1 > 0).toList();

    if (segments.length == 1) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paintFor(segments.single.$2),
      );
      return;
    }

    var startAngle = -math.pi / 2;
    for (final (count, color) in segments) {
      final sweep =
          ((count / total) * math.pi * 2 - gapAngle) * progress;
      canvas.drawArc(
        rect,
        startAngle + gapAngle / 2,
        math.max(sweep, 0.01),
        false,
        paintFor(color),
      );
      startAngle += (count / total) * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      done != oldDelegate.done ||
      pending != oldDelegate.pending ||
      doneColor != oldDelegate.doneColor ||
      pendingColor != oldDelegate.pendingColor ||
      progress != oldDelegate.progress;
}
