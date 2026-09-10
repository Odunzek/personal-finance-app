import 'package:flutter/material.dart';

/// A full-bleed decorative backdrop of layered orbit-arc strokes, echoing
/// the two compass arcs in the Kinscope mark blown up into a real
/// composition rather than a small repeated sticker. Every arc is anchored
/// exactly at a canvas corner (or edge midpoint) and only ever sweeps the
/// quarter-turn facing into the canvas — that's what keeps a bold arc from
/// ever ballooning into a diagonal slash across the centered content, no
/// matter how large its radius gets. Meant for hero screens (sign-in) —
/// never behind dense text, where a single small watermark reads better.
class MuralBackground extends StatelessWidget {
  final Widget child;

  const MuralBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _MuralPainter(
                primary: scheme.primary,
                secondary: scheme.secondary,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Stroke {
  /// Arc center as a fraction of canvas width/height — always a corner
  /// (0/1, 0/1) or edge midpoint, never inside the canvas.
  final Offset centerFactor;
  final double radiusFactor;
  final double startAngle;
  final double sweepAngle;
  final double strokeWidthFactor;
  final double opacity;
  final bool useSecondary;

  const _Stroke({
    required this.centerFactor,
    required this.radiusFactor,
    required this.startAngle,
    required this.sweepAngle,
    required this.strokeWidthFactor,
    required this.opacity,
    this.useSecondary = false,
  });
}

class _MuralPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  _MuralPainter({required this.primary, required this.secondary});

  static final _strokes = [
    // Top-right corner: the logo's outer bow, scaled into the hero moment.
    // Interior-facing quarter for a (1,0) anchor is [pi/2, pi]; both arcs
    // sit inside that with a little organic overshoot on the outer edges,
    // which only ever pushes further off-canvas, never toward the center.
    _Stroke(
      centerFactor: const Offset(1, 0),
      radiusFactor: 0.40,
      startAngle: 1.42,
      sweepAngle: 1.75,
      strokeWidthFactor: 0.012,
      opacity: 0.18,
    ),
    _Stroke(
      centerFactor: const Offset(1, 0),
      radiusFactor: 0.28,
      startAngle: 1.75,
      sweepAngle: 1.35,
      strokeWidthFactor: 0.009,
      opacity: 0.12,
      useSecondary: true,
    ),
    // Bottom-left corner: a quieter second constellation, mirrored anchor,
    // different rhythm so the two don't read as one repeated shape.
    _Stroke(
      centerFactor: const Offset(0, 1),
      radiusFactor: 0.40,
      startAngle: 4.55,
      sweepAngle: 1.75,
      strokeWidthFactor: 0.011,
      opacity: 0.16,
    ),
    _Stroke(
      centerFactor: const Offset(0, 1),
      radiusFactor: 0.27,
      startAngle: 4.85,
      sweepAngle: 1.30,
      strokeWidthFactor: 0.008,
      opacity: 0.10,
      useSecondary: true,
    ),
    // A small ring anchored on the right edge, breaking up the empty
    // mid-right margin. Centered exactly on the edge, so at most it bulges
    // in by its own radius — a fraction of the corner arcs' reach.
    _Stroke(
      centerFactor: Offset(1, 0.46),
      radiusFactor: 0.10,
      startAngle: 0.6,
      sweepAngle: 2.4,
      strokeWidthFactor: 0.014,
      opacity: 0.14,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;
    for (final s in _strokes) {
      final center = Offset(
        s.centerFactor.dx * size.width,
        s.centerFactor.dy * size.height,
      );
      final radius = s.radiusFactor * scale;
      final paint = Paint()
        ..color = (s.useSecondary ? secondary : primary).withValues(
          alpha: s.opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s.strokeWidthFactor * scale).clamp(1.5, 18)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        s.startAngle,
        s.sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}
