import 'package:flutter/material.dart';

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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.2,
          colors: [
            Color.lerp(base, Colors.white, 0.18)!,
            base,
            Color.lerp(base, Colors.black, 0.22)!,
          ],
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
