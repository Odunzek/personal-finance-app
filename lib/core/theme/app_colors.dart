import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// The literal brand teal — some categories (like the default "Groceries"
  /// seed) are colored exactly this, and get a special on-brand gradient in
  /// category_badge.dart regardless of which accent the active theme uses.
  static const brandTeal = Color(0xFF5CA2AC);

  static const warning = Color(0xFFC98A16);

  static const light = AppPalette(
    accent: Color(0xFF5CA2AC),
    onAccent: Color(0xFF04201F),
    background: Color(0xFFFAF7F0),
    card: Color(0xFFFFFFFF),
    bar: Color(0xFFFFFFFF),
    line: Color(0xFFE5E0D5),
    track: Color(0xFFEAE5DA),
    chip: Color(0xFFF0EDE4),
    ink: Color(0xFF131E1D),
    muted: Color(0xFF5C6A65),
    muted2: Color(0xFF5A6863),
    accentText: Color(0xFF2C6E79),
    positive: Color(0xFF1F6B4F),
    over: Color(0xFFA93B1F),
    warnText: Color(0xFF8A5A16),
    debtBg: Color(0xFFEDF5F6),
    debtLine: Color(0xFFC6DFE3),
  );

  // "Midnight Indigo" — cooler, bluer base than the original teal-on-black,
  // with a soft violet accent reserved for dark mode (light mode keeps the
  // brand teal). Positive/over keep a teal/coral family so money-flow colors
  // stay readable and distinct from the violet accent.
  static const dark = AppPalette(
    accent: Color(0xFF9C8CFF),
    onAccent: Color(0xFF15102E),
    background: Color(0xFF11121C),
    card: Color(0xFF1A1C2B),
    bar: Color(0xFF14151F),
    line: Color(0xFF282A3C),
    track: Color(0xFF232539),
    chip: Color(0xFF20222F),
    ink: Color(0xFFECEBF5),
    muted: Color(0xFF8C8BA3),
    muted2: Color(0xFF78768C),
    accentText: Color(0xFFB4A8FF),
    positive: Color(0xFF4FC9C2),
    over: Color(0xFFEC7A7A),
    warnText: Color(0xFFE0A552),
    debtBg: Color(0xFF231A33),
    debtLine: Color(0xFF362A4A),
  );
}

class AppPalette {
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color card;
  final Color bar;
  final Color line;
  final Color track;
  final Color chip;
  final Color ink;
  final Color muted;
  final Color muted2;
  final Color accentText;
  final Color positive;
  final Color over;
  final Color warnText;
  final Color debtBg;
  final Color debtLine;

  const AppPalette({
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.card,
    required this.bar,
    required this.line,
    required this.track,
    required this.chip,
    required this.ink,
    required this.muted,
    required this.muted2,
    required this.accentText,
    required this.positive,
    required this.over,
    required this.warnText,
    required this.debtBg,
    required this.debtLine,
  });
}
