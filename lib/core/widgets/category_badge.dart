import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The brand teal's real shading ramp, lifted from the gradient used in the
/// full-color Kinscope logo SVGs — used instead of a generic lighten/darken
/// whenever a badge's color is the brand accent itself, so that one specific
/// case reads as genuinely on-brand rather than algorithmically approximated.
const _brandTealHighlight = Color(0xFF8AC8D0);
const _brandTealShadow = Color(0xFF1C4A52);

/// A circular, gently gradient-shaded token for a category's icon — used
/// everywhere a category shows up (transactions, category list, quick-add)
/// so its color reads as a real badge rather than a small flat square.
class CategoryBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  const CategoryBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.outlineVariant;
    final isBrandTeal = base.toARGB32() == AppColors.accent.toARGB32();
    final highlight = isBrandTeal
        ? _brandTealHighlight
        : Color.lerp(base, Colors.white, 0.18)!;
    final shadow = isBrandTeal
        ? _brandTealShadow
        : Color.lerp(base, Colors.black, 0.22)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.2,
          colors: [highlight, base, shadow],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
