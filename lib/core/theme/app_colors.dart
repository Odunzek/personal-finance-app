import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const accent = Color(0xFF0FA3A3);
  static const accentHover = Color(0xFF14BDBD);
  static const onAccent = Color(0xFF04201F);
  static const positive = Color(0xFF2F8F6B);
  static const warning = Color(0xFFC98A16);

  static const light = AppPalette(
    background: Color(0xFFFAF7F0),
    card: Color(0xFFFFFFFF),
    bar: Color(0xFFFFFFFF),
    line: Color(0xFFE5E0D5),
    track: Color(0xFFEAE5DA),
    chip: Color(0xFFF0EDE4),
    ink: Color(0xFF12211F),
    muted: Color(0xFF66756F),
    muted2: Color(0xFF98A6A1),
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
    muted2: Color(0xFF5F7370),
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
  });
}
