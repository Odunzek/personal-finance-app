import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final bodyFont = GoogleFonts.ibmPlexSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: bodyFont.apply(bodyColor: p.ink, displayColor: p.ink),
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        surface: p.card,
        onSurface: p.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bar,
        foregroundColor: p.ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: p.track,
      ),
    );
  }

  static TextStyle amountStyle(BuildContext context, {double size = 46}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: -size * 0.048,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
