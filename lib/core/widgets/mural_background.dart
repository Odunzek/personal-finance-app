import 'package:flutter/material.dart';

import 'orbit_watermark.dart';

/// A full-bleed decorative backdrop built from the same orbit-arc motif as
/// [OrbitWatermark], layered at a few sizes and low opacities. Meant to sit
/// behind hero screens (sign-in) as a quiet brand "mural" — never behind
/// dense text content, where a single small watermark reads better.
class MuralBackground extends StatelessWidget {
  final Widget child;

  const MuralBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: OrbitWatermark(
            size: 320,
            color: primary.withValues(alpha: 0.10),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -90,
          child: OrbitWatermark(
            size: 360,
            color: primary.withValues(alpha: 0.07),
          ),
        ),
        Positioned(
          bottom: 60,
          right: -40,
          child: OrbitWatermark(
            size: 140,
            color: primary.withValues(alpha: 0.09),
          ),
        ),
        child,
      ],
    );
  }
}
