import 'package:flutter/material.dart';

/// A faint decorative echo of the two compass arcs in the Kinscope mark —
/// a quiet signature touch behind hero content, not a literal logo redraw.
class OrbitWatermark extends StatelessWidget {
  final double size;
  final Color color;

  const OrbitWatermark({super.key, this.size = 220, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _OrbitPainter(color: color),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;

  _OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.03
      ..strokeCap = StrokeCap.round;

    final outer = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(outer, -1.65, 1.2, false, paint);

    final inner = Rect.fromCircle(center: center, radius: radius * 0.82);
    canvas.drawArc(inner, 0.35, 1.05, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
