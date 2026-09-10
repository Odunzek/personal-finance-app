import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/money.dart';

/// Renders a money amount in Bricolage Grotesque — the numeric display font
/// used for every figure in the product (see DESIGN.md). Centralizing this
/// here is what makes that rule actually true across the app, instead of
/// only the one hero balance that used to call the font directly.
class MoneyText extends StatelessWidget {
  final int minorUnits;
  final bool showSign;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const MoneyText(
    this.minorUnits, {
    super.key,
    this.showSign = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  static TextStyle style(
    BuildContext context, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -fontSize * 0.03,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(minorUnits, showSign: showSign),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: style(
        context,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// Same as [MoneyText] but counts up from zero on first build — used for the
/// hero balance figure.
class AnimatedMoneyText extends StatelessWidget {
  final int minorUnits;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const AnimatedMoneyText(
    this.minorUnits, {
    super.key,
    this.fontSize = 46,
    this.fontWeight = FontWeight.w600,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: minorUnits.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        formatMoney(value.round()),
        style: MoneyText.style(
          context,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }
}
