import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A decorative backdrop echoing the two compass arcs in the Kinscope mark,
/// built from four layers: soft radial washes, orbit arcs, compass-bezel tick
/// rings, and a scattering of points.
///
/// Every arc and tick ring is anchored exactly at a canvas corner (or edge
/// midpoint) and only ever sweeps the quarter-turn facing into the canvas —
/// that's what keeps a bold arc from ever ballooning into a diagonal slash
/// across centered content, no matter how large its radius gets.
///
/// Two intensities:
/// - [MuralBackground.hero] — bold, for a mostly-empty canvas behind a
///   single centered form (sign-in, splash).
/// - [MuralBackground.ambient] — a quieter texture sized to sit behind
///   dense, edge-to-edge content (the main tabs, list screens) without
///   competing with cards or text.
class MuralBackground extends StatelessWidget {
  final Widget child;
  final _MuralSpec _spec;

  const MuralBackground.hero({super.key, required this.child}) : _spec = _hero;

  const MuralBackground.ambient({super.key, required this.child})
    : _spec = _ambient;

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
                  spec: _spec,
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

class _MuralSpec {
  final List<_Glow> glows;
  final List<_Stroke> strokes;
  final List<_TickArc> tickArcs;
  final List<_Dot> dots;

  /// How many tiny points to scatter across the margins, and how strongly.
  final int fieldCount;
  final double fieldOpacity;

  /// One knob over every layer's alpha, so the whole backdrop can be dialled
  /// up or down without touching sixty individual opacities.
  final double opacityScale;

  const _MuralSpec({
    required this.glows,
    required this.strokes,
    required this.tickArcs,
    required this.dots,
    required this.fieldCount,
    required this.fieldOpacity,
    this.opacityScale = 1.0,
  });
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

/// A ring of short radial ticks, like the bezel of a compass or the scale on
/// an instrument — the motif that most directly ties the backdrop to the
/// mark, and the one that makes the composition read as drawn rather than
/// as a few stray curves.
class _TickArc {
  final Offset centerFactor;
  final double radiusFactor;
  final double startAngle;
  final double sweepAngle;
  final int count;
  final double tickLengthFactor;
  final double strokeWidthFactor;
  final double opacity;
  final bool useSecondary;

  const _TickArc({
    required this.centerFactor,
    required this.radiusFactor,
    required this.startAngle,
    required this.sweepAngle,
    required this.count,
    required this.tickLengthFactor,
    required this.strokeWidthFactor,
    required this.opacity,
    this.useSecondary = false,
  });
}

/// A small filled point — the "constellation" the arcs orbit.
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

const _hero = _MuralSpec(
  fieldCount: 54,
  fieldOpacity: 0.11,
  glows: [
    _Glow(centerFactor: Offset(1, 0.02), radiusFactor: 0.95, opacity: 0.20),
    _Glow(
      centerFactor: Offset(0, 1),
      radiusFactor: 0.80,
      opacity: 0.16,
      useSecondary: true,
    ),
    _Glow(centerFactor: Offset(0.08, 0.04), radiusFactor: 0.46, opacity: 0.09),
    _Glow(
      centerFactor: Offset(1, 0.98),
      radiusFactor: 0.42,
      opacity: 0.08,
      useSecondary: true,
    ),
  ],
  strokes: [
    // Top-right: the logo's outer bow, scaled into a hero moment.
    _Stroke(
      centerFactor: Offset(1, 0),
      radiusFactor: 0.62,
      startAngle: 1.38,
      sweepAngle: 1.82,
      strokeWidthFactor: 0.006,
      opacity: 0.14,
    ),
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
      radiusFactor: 0.46,
      startAngle: 1.60,
      sweepAngle: 1.52,
      strokeWidthFactor: 0.005,
      opacity: 0.13,
      useSecondary: true,
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
      radiusFactor: 0.22,
      startAngle: 1.86,
      sweepAngle: 1.18,
      strokeWidthFactor: 0.004,
      opacity: 0.12,
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
      radiusFactor: 0.60,
      startAngle: 4.50,
      sweepAngle: 1.80,
      strokeWidthFactor: 0.005,
      opacity: 0.12,
      useSecondary: true,
    ),
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
      radiusFactor: 0.44,
      startAngle: 4.76,
      sweepAngle: 1.48,
      strokeWidthFactor: 0.004,
      opacity: 0.11,
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
    _Stroke(
      centerFactor: Offset(0, 1),
      radiusFactor: 0.18,
      startAngle: 5.02,
      sweepAngle: 1.08,
      strokeWidthFactor: 0.004,
      opacity: 0.10,
    ),
    // Opposite corners — enough to close the composition.
    _Stroke(
      centerFactor: Offset(0, 0),
      radiusFactor: 0.38,
      startAngle: 0.04,
      sweepAngle: 1.46,
      strokeWidthFactor: 0.005,
      opacity: 0.09,
    ),
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
      centerFactor: Offset(0, 0),
      radiusFactor: 0.21,
      startAngle: 0.14,
      sweepAngle: 1.28,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
    ),
    _Stroke(
      centerFactor: Offset(1, 1),
      radiusFactor: 0.40,
      startAngle: 3.18,
      sweepAngle: 1.44,
      strokeWidthFactor: 0.005,
      opacity: 0.09,
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
    _Stroke(
      centerFactor: Offset(1, 1),
      radiusFactor: 0.23,
      startAngle: 3.30,
      sweepAngle: 1.24,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
    ),
    // Edge-anchored rings breaking up the empty mid-margins. Centered exactly
    // on an edge, so at most each bulges in by its own radius.
    _Stroke(
      centerFactor: Offset(1, 0.46),
      radiusFactor: 0.12,
      startAngle: 0.6,
      sweepAngle: 2.4,
      strokeWidthFactor: 0.014,
      opacity: 0.18,
    ),
    _Stroke(
      centerFactor: Offset(1, 0.46),
      radiusFactor: 0.17,
      startAngle: 0.9,
      sweepAngle: 1.9,
      strokeWidthFactor: 0.004,
      opacity: 0.10,
      useSecondary: true,
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
    _Stroke(
      centerFactor: Offset(0, 0.62),
      radiusFactor: 0.13,
      startAngle: 5.1,
      sweepAngle: 1.9,
      strokeWidthFactor: 0.004,
      opacity: 0.09,
    ),
    _Stroke(
      centerFactor: Offset(0.5, 0),
      radiusFactor: 0.10,
      startAngle: 0.35,
      sweepAngle: 2.45,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
    ),
    _Stroke(
      centerFactor: Offset(0.5, 1),
      radiusFactor: 0.11,
      startAngle: 3.50,
      sweepAngle: 2.45,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
      useSecondary: true,
    ),
  ],
  tickArcs: [
    _TickArc(
      centerFactor: Offset(1, 0),
      radiusFactor: 0.345,
      startAngle: 1.62,
      sweepAngle: 1.48,
      count: 26,
      tickLengthFactor: 0.022,
      strokeWidthFactor: 0.0035,
      opacity: 0.17,
    ),
    _TickArc(
      centerFactor: Offset(0, 1),
      radiusFactor: 0.325,
      startAngle: 4.74,
      sweepAngle: 1.46,
      count: 24,
      tickLengthFactor: 0.020,
      strokeWidthFactor: 0.0035,
      opacity: 0.15,
      useSecondary: true,
    ),
    _TickArc(
      centerFactor: Offset(1, 0.46),
      radiusFactor: 0.145,
      startAngle: 0.85,
      sweepAngle: 1.95,
      count: 13,
      tickLengthFactor: 0.013,
      strokeWidthFactor: 0.003,
      opacity: 0.12,
    ),
  ],
  dots: [
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
    _Dot(centerFactor: Offset(0.06, 0.33), radiusFactor: 0.006, opacity: 0.13),
    _Dot(
      centerFactor: Offset(0.72, 0.07),
      radiusFactor: 0.0045,
      opacity: 0.12,
      useSecondary: true,
    ),
    _Dot(centerFactor: Offset(0.30, 0.96), radiusFactor: 0.005, opacity: 0.12),
  ],
);

// Same corners, same safe-quarter geometry, scaled down and faded — this
// sits behind edge-to-edge cards and lists, so it has to read as page
// texture, not decoration competing with data.
const _ambient = _MuralSpec(
  // Cards and lists are opaque, so the backdrop only ever shows through the
  // margins and gaps — it can run much stronger than a literal reading of
  // "ambient" suggests before it competes with anything.
  opacityScale: 1.9,
  fieldCount: 46,
  fieldOpacity: 0.07,
  glows: [
    _Glow(centerFactor: Offset(1, 0.04), radiusFactor: 0.78, opacity: 0.12),
    _Glow(
      centerFactor: Offset(0, 0.96),
      radiusFactor: 0.62,
      opacity: 0.09,
      useSecondary: true,
    ),
    _Glow(centerFactor: Offset(0.04, 0.06), radiusFactor: 0.34, opacity: 0.05),
  ],
  strokes: [
    _Stroke(
      centerFactor: Offset(1, 0),
      radiusFactor: 0.38,
      startAngle: 1.43,
      sweepAngle: 1.80,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
    ),
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
      radiusFactor: 0.25,
      startAngle: 1.62,
      sweepAngle: 1.54,
      strokeWidthFactor: 0.0035,
      opacity: 0.08,
      useSecondary: true,
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
      radiusFactor: 0.38,
      startAngle: 4.55,
      sweepAngle: 1.76,
      strokeWidthFactor: 0.004,
      opacity: 0.08,
      useSecondary: true,
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
      radiusFactor: 0.24,
      startAngle: 4.74,
      sweepAngle: 1.50,
      strokeWidthFactor: 0.0035,
      opacity: 0.08,
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
      radiusFactor: 0.24,
      startAngle: 0.08,
      sweepAngle: 1.38,
      strokeWidthFactor: 0.0035,
      opacity: 0.06,
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
      radiusFactor: 0.25,
      startAngle: 3.22,
      sweepAngle: 1.36,
      strokeWidthFactor: 0.0035,
      opacity: 0.06,
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
      centerFactor: Offset(1, 0.46),
      radiusFactor: 0.105,
      startAngle: 0.9,
      sweepAngle: 1.9,
      strokeWidthFactor: 0.003,
      opacity: 0.06,
      useSecondary: true,
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
    _Stroke(
      centerFactor: Offset(0, 0.62),
      radiusFactor: 0.085,
      startAngle: 5.1,
      sweepAngle: 1.9,
      strokeWidthFactor: 0.003,
      opacity: 0.05,
    ),
    _Stroke(
      centerFactor: Offset(0.5, 1),
      radiusFactor: 0.08,
      startAngle: 3.50,
      sweepAngle: 2.45,
      strokeWidthFactor: 0.003,
      opacity: 0.05,
    ),
  ],
  tickArcs: [
    _TickArc(
      centerFactor: Offset(1, 0),
      radiusFactor: 0.225,
      startAngle: 1.62,
      sweepAngle: 1.46,
      count: 22,
      tickLengthFactor: 0.016,
      strokeWidthFactor: 0.003,
      opacity: 0.10,
    ),
    _TickArc(
      centerFactor: Offset(0, 1),
      radiusFactor: 0.215,
      startAngle: 4.76,
      sweepAngle: 1.42,
      count: 20,
      tickLengthFactor: 0.014,
      strokeWidthFactor: 0.003,
      opacity: 0.09,
      useSecondary: true,
    ),
  ],
  dots: [
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
    _Dot(centerFactor: Offset(0.96, 0.58), radiusFactor: 0.004, opacity: 0.09),
    _Dot(centerFactor: Offset(0.04, 0.30), radiusFactor: 0.004, opacity: 0.08),
  ],
);

class _MuralPainter extends CustomPainter {
  final _MuralSpec spec;
  final Color primary;
  final Color secondary;
  final double intensity;

  _MuralPainter({
    required this.spec,
    required this.primary,
    required this.secondary,
    required this.intensity,
  });

  double _alpha(double opacity) =>
      (opacity * intensity * spec.opacityScale).clamp(0.0, 1.0);

  Color _color(bool useSecondary, double opacity) =>
      (useSecondary ? secondary : primary).withValues(alpha: _alpha(opacity));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;

    // Washes first, so the line work sits over them rather than being
    // muddied by a gradient painted on top.
    for (final g in spec.glows) {
      final center = Offset(
        g.centerFactor.dx * size.width,
        g.centerFactor.dy * size.height,
      );
      final radius = g.radiusFactor * scale;
      final base = g.useSecondary ? secondary : primary;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            base.withValues(alpha: _alpha(g.opacity)),
            base.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    _paintField(canvas, size, scale);

    for (final s in spec.strokes) {
      final center = Offset(
        s.centerFactor.dx * size.width,
        s.centerFactor.dy * size.height,
      );
      final paint = Paint()
        ..color = _color(s.useSecondary, s.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s.strokeWidthFactor * scale).clamp(1.0, 18)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: s.radiusFactor * scale),
        s.startAngle,
        s.sweepAngle,
        false,
        paint,
      );
    }

    for (final t in spec.tickArcs) {
      final center = Offset(
        t.centerFactor.dx * size.width,
        t.centerFactor.dy * size.height,
      );
      final inner = t.radiusFactor * scale;
      final outer = inner + t.tickLengthFactor * scale;
      final paint = Paint()
        ..color = _color(t.useSecondary, t.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (t.strokeWidthFactor * scale).clamp(1.0, 6)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < t.count; i++) {
        // Every 4th tick runs long, the way a bezel marks its major
        // divisions — without it the ring reads as uniform hatching.
        final isMajor = i % 4 == 0;
        final angle = t.startAngle + t.sweepAngle * (i / (t.count - 1));
        final dir = Offset(math.cos(angle), math.sin(angle));
        final end = inner + (outer - inner) * (isMajor ? 1.0 : 0.55);
        canvas.drawLine(center + dir * inner, center + dir * end, paint);
      }
    }

    for (final d in spec.dots) {
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

  /// A fine scatter of points across the whole canvas, thinned toward the
  /// middle so the densest texture sits in the margins where content isn't.
  /// Generated from a fixed seed so it never shimmers between repaints.
  void _paintField(Canvas canvas, Size size, double scale) {
    final random = math.Random(20261002);
    final paint = Paint();
    for (var i = 0; i < spec.fieldCount; i++) {
      final fx = random.nextDouble();
      final fy = random.nextDouble();
      // Distance from centre, 0 at the middle and 1 at an edge.
      final edgeness = math.max((fx - 0.5).abs(), (fy - 0.5).abs()) * 2;
      if (random.nextDouble() > edgeness) continue;
      final useSecondary = random.nextBool();
      paint.color = _color(
        useSecondary,
        spec.fieldOpacity * (0.45 + edgeness * 0.55),
      );
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        (0.0022 + random.nextDouble() * 0.0026) * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) =>
      oldDelegate.spec != spec ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.intensity != intensity;
}
