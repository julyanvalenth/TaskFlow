import 'package:flutter/material.dart';

/// Mark Lumo (bentuk flame/droplet) dari path SVG logo, viewBox 24x24.
/// Pakai [CustomPainter] supaya tetap tajam di semua resolusi tanpa aset
/// per density.
class LumoMark extends StatelessWidget {
  const LumoMark({super.key, this.size = 24, this.color = const Color(0xFF021024)});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LumoMarkPainter(color: color),
    );
  }
}

class _LumoMarkPainter extends CustomPainter {
  _LumoMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    // Titik & kurva diterjemahkan langsung dari atribut `d` path SVG asli:
    // "M12 2c1.4 4.6-4.6 6.8-4.6 12.4A4.6 4.6 0 0012 19a4.6 4.6 0 004.6-4.6
    //  c0-2.3-1.15-4-2.3-5.75-1.7 2.3-2.3 2.9-2.3 4.6"
    final path = Path()
      ..moveTo(12, 2)
      ..cubicTo(13.4, 6.6, 7.4, 8.8, 7.4, 14.4)
      ..arcToPoint(
        const Offset(12, 19),
        radius: const Radius.circular(4.6),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(16.6, 14.4),
        radius: const Radius.circular(4.6),
        clockwise: false,
      )
      ..cubicTo(16.6, 12.1, 15.45, 10.4, 14.3, 8.65)
      ..cubicTo(12.6, 10.95, 12.0, 11.55, 12.0, 13.25);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LumoMarkPainter oldDelegate) => oldDelegate.color != color;
}

/// [LumoMark] di dalam kotak rounded gradient ice blue dengan highlight kaca.
/// Dipakai di splash, onboarding, dan login/register.
class LumoMarkTile extends StatelessWidget {
  const LumoMarkTile({super.key, this.size = 72, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = size * (22 / 72);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5483B3), Color(0xFFC1E8FF)],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF5483B3).withValues(alpha: 0.4),
                  blurRadius: size * (40 / 72),
                  offset: Offset(0, size * (12 / 72)),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 0.7,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          LumoMark(size: size * (46 / 96), color: const Color(0xFF021024)),
        ],
      ),
    );
  }
}
