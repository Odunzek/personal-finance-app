import 'package:flutter/material.dart';

/// A decorative backdrop of layered orbit-arc strokes, soft colour washes and
/// scattered points, echoing the two compass arcs in the Kinscope mark.
///
/// Every arc is anchored exactly at a canvas corner (or edge midpoint) and
/// only ever sweeps the quarter-turn facing into the canvas — that's what
/// keeps a bold arc from ever ballooning into a diagonal slash across
/// centered content, no matter how large its radius gets.
///
/// Two intensities:
/// - [MuralBackground.hero] — bold, for a mostly-empty canvas behind a
///   single centered form (sign-in, splash).
/// - [MuralBackground.ambient] — a quieter texture sized to sit behind
///   dense, edge-to-edge content (the main tabs, list screens) without
///   competing with cards or text.
class MuralBackground extends StatelessWidget {
  final Widget child;
  final List<_Stroke> _strokes;
  final List<_Glow> _glows;
  final List<_Dot> _dots;

  const MuralBackground.hero({super.key, required this.child})
    : _strokes = _heroStrokes,
      _glows = _heroGlows,
      _dots = _heroDots;

  const MuralBackground.ambient({super.key, required this.child})
    : _strokes = _ambientStrokes,
      _glows = _ambientGlows,
      _dots = _ambientDots;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _MuralPainter(
                  strokes: _strokes,
                  glows: _glows,
                  dots: _dots,
                  primary: scheme.primary,
                  secondary: scheme.tertiary,
                  // A light accent on a dark ground reads far hotter than the
                  // same alpha of teal on cream, so dark mode is damped to
                  // keep the backdrop from competing with the content.
                  intensity: isDark ? 0.72 : 1.0,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A soft radial wash anchored off-canvas. Does most of the work of making a
/// page feel like a designed surface rather than a flat fill — and, being a
/// gradient rather than a line, adds depth without competing with the text
/// sitting on top of it.
class _Glow {
  final Offset centerFactor;
  final double radiusFactor;
  final double opacity;
  final bool useSecondary;

  const _Glow({
    required this.centerFactor,
    required this.radiusFactor,
    required this.opacity,
    this.useSecondary = false,
  });
}

class _Stroke {
  /// Arc center as a fraction of canvas width/height — always a corner
  /// (0/1, 0/1) or an edge midpoint, never inside the canvas.
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

/// A small filled point, placed near the edges to break up flat margins —
/// the "constellation" the arcs orbit.
class _Dot {
  final Offset centerFactor;
  final double radiusFactor;
  final double opacity;
  final bool useSecondary;

  const _Dot({
    required this.centerFactor,
    required this.radiusFactor,
    required this.opacity,
    this.useSecondary = false,
  });
}

// Interior-facing quarters, by anchor:
//   (1,0) top-right     -> [pi/2, pi]        ~ [1.57, 3.14]
//   (0,1) bottom-left   -> [3pi/2, 2pi]      ~ [4.71, 6.28]
//   (0,0) top-left      -> [0, pi/2]         ~ [0, 1.57]
//   (1,1) bottom-right  -> [pi, 3pi/2]       ~ [3.14, 4.71]
// Small overshoot past those bounds only ever pushes further off-canvas.

const _heroGlows = [
  _Glow(centerFactor: Offset(1, 0.02), radiusFactor: 0.95, opacity: 0.20),
  _Glow(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.80,
    opacity: 0.16,
    useSecondary: true,
  ),
  _Glow(centerFactor: Offset(0.1, 0.05), radiusFactor: 0.45, opacity: 0.08),
];

const _heroStrokes = [
  // Top-right: the logo's outer bow, scaled into a hero moment.
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.52,
    startAngle: 1.40,
    sweepAngle: 1.80,
    strokeWidthFactor: 0.013,
    opacity: 0.26,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.40,
    startAngle: 1.52,
    sweepAngle: 1.70,
    strokeWidthFactor: 0.010,
    opacity: 0.20,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.28,
    startAngle: 1.75,
    sweepAngle: 1.35,
    strokeWidthFactor: 0.008,
    opacity: 0.16,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.17,
    startAngle: 1.95,
    sweepAngle: 1.05,
    strokeWidthFactor: 0.006,
    opacity: 0.12,
  ),
  // Bottom-left: a quieter second constellation, mirrored anchor, different
  // rhythm so the two don't read as one repeated shape.
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.50,
    startAngle: 4.52,
    sweepAngle: 1.78,
    strokeWidthFactor: 0.012,
    opacity: 0.22,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.38,
    startAngle: 4.70,
    sweepAngle: 1.60,
    strokeWidthFactor: 0.009,
    opacity: 0.17,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.26,
    startAngle: 4.88,
    sweepAngle: 1.28,
    strokeWidthFactor: 0.007,
    opacity: 0.13,
    useSecondary: true,
  ),
  // Opposite corners, lightly — enough to close the composition.
  _Stroke(
    centerFactor: Offset(0, 0),
    radiusFactor: 0.30,
    startAngle: 0.06,
    sweepAngle: 1.42,
    strokeWidthFactor: 0.007,
    opacity: 0.11,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(1, 1),
    radiusFactor: 0.32,
    startAngle: 3.20,
    sweepAngle: 1.40,
    strokeWidthFactor: 0.007,
    opacity: 0.11,
  ),
  // Edge-anchored rings breaking up the empty mid-margins. Centered exactly
  // on the edge, so at most each bulges in by its own radius.
  _Stroke(
    centerFactor: Offset(1, 0.46),
    radiusFactor: 0.12,
    startAngle: 0.6,
    sweepAngle: 2.4,
    strokeWidthFactor: 0.014,
    opacity: 0.18,
  ),
  _Stroke(
    centerFactor: Offset(0, 0.62),
    radiusFactor: 0.08,
    startAngle: 4.9,
    sweepAngle: 2.3,
    strokeWidthFactor: 0.010,
    opacity: 0.13,
    useSecondary: true,
  ),
];

const _heroDots = [
  _Dot(centerFactor: Offset(0.90, 0.13), radiusFactor: 0.011, opacity: 0.26),
  _Dot(
    centerFactor: Offset(0.82, 0.21),
    radiusFactor: 0.007,
    opacity: 0.18,
    useSecondary: true,
  ),
  _Dot(centerFactor: Offset(0.10, 0.84), radiusFactor: 0.010, opacity: 0.22),
  _Dot(
    centerFactor: Offset(0.19, 0.91),
    radiusFactor: 0.006,
    opacity: 0.15,
    useSecondary: true,
  ),
  _Dot(centerFactor: Offset(0.95, 0.62), radiusFactor: 0.005, opacity: 0.14),
];

// Same corners, same safe-quarter geometry, scaled down and faded — this
// sits behind edge-to-edge cards and lists, so it has to read as page
// texture, not decoration competing with data.
const _ambientGlows = [
  _Glow(centerFactor: Offset(1, 0.04), radiusFactor: 0.78, opacity: 0.12),
  _Glow(
    centerFactor: Offset(0, 0.96),
    radiusFactor: 0.62,
    opacity: 0.09,
    useSecondary: true,
  ),
];

const _ambientStrokes = [
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.30,
    startAngle: 1.45,
    sweepAngle: 1.78,
    strokeWidthFactor: 0.009,
    opacity: 0.13,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.20,
    startAngle: 1.70,
    sweepAngle: 1.45,
    strokeWidthFactor: 0.007,
    opacity: 0.10,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(1, 0),
    radiusFactor: 0.12,
    startAngle: 1.92,
    sweepAngle: 1.08,
    strokeWidthFactor: 0.006,
    opacity: 0.08,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.30,
    startAngle: 4.58,
    sweepAngle: 1.74,
    strokeWidthFactor: 0.008,
    opacity: 0.12,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.19,
    startAngle: 4.86,
    sweepAngle: 1.34,
    strokeWidthFactor: 0.006,
    opacity: 0.09,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(0, 1),
    radiusFactor: 0.11,
    startAngle: 5.05,
    sweepAngle: 1.02,
    strokeWidthFactor: 0.005,
    opacity: 0.07,
  ),
  _Stroke(
    centerFactor: Offset(0, 0),
    radiusFactor: 0.17,
    startAngle: 0.10,
    sweepAngle: 1.34,
    strokeWidthFactor: 0.006,
    opacity: 0.07,
    useSecondary: true,
  ),
  _Stroke(
    centerFactor: Offset(1, 1),
    radiusFactor: 0.18,
    startAngle: 3.26,
    sweepAngle: 1.30,
    strokeWidthFactor: 0.006,
    opacity: 0.07,
  ),
  _Stroke(
    centerFactor: Offset(1, 0.46),
    radiusFactor: 0.07,
    startAngle: 0.6,
    sweepAngle: 2.4,
    strokeWidthFactor: 0.010,
    opacity: 0.09,
  ),
  _Stroke(
    centerFactor: Offset(0, 0.62),
    radiusFactor: 0.05,
    startAngle: 4.9,
    sweepAngle: 2.2,
    strokeWidthFactor: 0.008,
    opacity: 0.07,
    useSecondary: true,
  ),
];

const _ambientDots = [
  _Dot(centerFactor: Offset(0.92, 0.10), radiusFactor: 0.0075, opacity: 0.15),
  _Dot(
    centerFactor: Offset(0.85, 0.17),
    radiusFactor: 0.0045,
    opacity: 0.11,
    useSecondary: true,
  ),
  _Dot(centerFactor: Offset(0.08, 0.88), radiusFactor: 0.0065, opacity: 0.13),
  _Dot(
    centerFactor: Offset(0.15, 0.93),
    radiusFactor: 0.004,
    opacity: 0.10,
    useSecondary: true,
  ),
];

class _MuralPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<_Glow> glows;
  final List<_Dot> dots;
  final Color primary;
  final Color secondary;
  final double intensity;

  _MuralPainter({
    required this.strokes,
    required this.glows,
    required this.dots,
    required this.primary,
    required this.secondary,
    required this.intensity,
  });

  Color _color(bool useSecondary, double opacity) =>
      (useSecondary ? secondary : primary).withValues(
        alpha: (opacity * intensity).clamp(0.0, 1.0),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;

    // Washes first, so the line work sits over them rather than being
    // muddied by a gradient painted on top.
    for (final g in glows) {
      final center = Offset(
        g.centerFactor.dx * size.width,
        g.centerFactor.dy * size.height,
      );
      final radius = g.radiusFactor * scale;
      final base = g.useSecondary ? secondary : primary;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            base.withValues(alpha: (g.opacity * intensity).clamp(0.0, 1.0)),
            base.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    for (final s in strokes) {
      final center = Offset(
        s.centerFactor.dx * size.width,
        s.centerFactor.dy * size.height,
      );
      final radius = s.radiusFactor * scale;
      final paint = Paint()
        ..color = _color(s.useSecondary, s.opacity)
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

    for (final d in dots) {
      final center = Offset(
        d.centerFactor.dx * size.width,
        d.centerFactor.dy * size.height,
      );
      canvas.drawCircle(
        center,
        (d.radiusFactor * scale).clamp(1.5, 14),
        Paint()..color = _color(d.useSecondary, d.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.glows != glows ||
      oldDelegate.dots != dots ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.intensity != intensity;
}
