import 'package:flutter/material.dart';

/// A decorative backdrop of layered orbit-arc strokes, echoing the two
/// compass arcs in the Kinscope mark. Every arc is anchored exactly at a
/// canvas corner (or edge midpoint) and only ever sweeps the quarter-turn
/// facing into the canvas — that's what keeps a bold arc from ever
/// ballooning into a diagonal slash across centered content, no matter how
/// large its radius gets.
///
/// Two intensities:
/// - [MuralBackground.hero] — bold, for a mostly-empty canvas behind a
///   single centered form (sign-in).
/// - [MuralBackground.ambient] — a much quieter texture sized to sit behind
///   dense, edge-to-edge content (the main tabs, list screens) without
///   competing with cards or text.
class MuralBackground extends StatelessWidget {
  final Widget child;
  final List<_Stroke> _strokes;

  const MuralBackground.hero({super.key, required this.child})
    : _strokes = _heroStrokes;

  const MuralBackground.ambient({super.key, required this.child})
    : _strokes = _ambientStrokes;

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
                strokes: _strokes,
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

// Top-right corner: the logo's outer bow, scaled into a hero moment.
// Interior-facing quarter for a (1,0) anchor is [pi/2, pi]; both arcs sit
// inside that with a little organic overshoot on the outer edges, which
// only ever pushes further off-canvas, never toward the center.
const _heroStrokes = [
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.40,
    startAngle: 1.42,
    sweepAngle: 1.75,
    strokeWidthFactor: 0.012,
    opacity: 0.18,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
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
    centerFactor: Offset(0, 1),
    radiusFactor: 0.40,
    startAngle: 4.55,
    sweepAngle: 1.75,
    strokeWidthFactor: 0.011,
    opacity: 0.16,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
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

// Same corners, same safe-quarter geometry, but scaled down and faded
// hard — this sits behind edge-to-edge cards and lists, so it has to read
// as page texture, not decoration competing with data.
const _ambientStrokes = [
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.20,
    startAngle: 1.42,
    sweepAngle: 1.75,
    strokeWidthFactor: 0.008,
    opacity: 0.07,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.13,
    startAngle: 1.75,
    sweepAngle: 1.35,
    strokeWidthFactor: 0.006,
    opacity: 0.05,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.20,
    startAngle: 4.55,
    sweepAngle: 1.75,
    strokeWidthFactor: 0.007,
    opacity: 0.06,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.12,
    startAngle: 4.85,
    sweepAngle: 1.30,
    strokeWidthFactor: 0.005,
    opacity: 0.04,
    useSecondary: true,
  ),
];

class _MuralPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final Color primary;
  final Color secondary;

  _MuralPainter({
    required this.strokes,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;
    for (final s in strokes) {
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
      oldDelegate.strokes != strokes ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}
