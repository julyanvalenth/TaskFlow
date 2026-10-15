import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Progress bar putus-putus. Segmen yang terisi menyala, sisanya redup,
/// dan warnanya beranimasi saat nilai berubah.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.value,
    this.segments = 8,
    this.height = 5,
    this.gap = 4,
    this.fillColor = Colors.white,
    this.trackColor = const Color(0x33FFFFFF),
  });

  /// Nilai 0.0 sampai 1.0.
  final double value;
  final int segments;
  final double height;
  final double gap;
  final Color fillColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * segments).round();

    return Row(
      children: [
        for (int i = 0; i < segments; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.progressAnimation,
              curve: Curves.easeOutCubic,
              height: height,
              decoration: BoxDecoration(
                color: i < filled ? fillColor : trackColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
