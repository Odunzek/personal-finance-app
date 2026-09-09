import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const accent = Color(0xFF5CA2AC);
  static const accentHover = Color(0xFF14BDBD);
  static const onAccent = Color(0xFF04201F);
  static const warning = Color(0xFFC98A16);

  static const light = AppPalette(
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

  static const dark = AppPalette(
    background: Color(0xFF0F1A1C),
    card: Color(0xFF162426),
    bar: Color(0xFF132022),
    line: Color(0xFF233436),
    track: Color(0xFF1E2E30),
    chip: Color(0xFF1C2C2E),
    ink: Color(0xFFEEF3F1),
    muted: Color(0xFF8DA39E),
    muted2: Color(0xFF7A8F8A),
    accentText: Color(0xFF7FC3CC),
    positive: Color(0xFF59BE93),
    over: Color(0xFFE0765A),
    warnText: Color(0xFFD9A63A),
    debtBg: Color(0xFF122B2A),
    debtLine: Color(0xFF1F4645),
  );
}

class AppPalette {
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
