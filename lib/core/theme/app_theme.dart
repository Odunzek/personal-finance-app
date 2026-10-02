import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    // Seed the whole Material 3 color scheme from this theme's own accent so
    // derived roles (primaryContainer, secondaryContainer, etc. - used by
    // FAB, chips, SegmentedButton) land in that same family instead of
    // Flutter's generic default purple, then pin the specific roles we have
    // exact brand values for on top. Light and dark intentionally use
    // different accents (teal vs. violet), so this seeds per-palette rather
    // than from one shared constant.
    final seededScheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: seededScheme, useMaterial3: true);
    final bodyFont = GoogleFonts.ibmPlexSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: bodyFont.apply(bodyColor: p.ink, displayColor: p.ink),
      colorScheme: seededScheme.copyWith(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.card,
        onSurface: p.ink,
        error: p.over,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bar,
        foregroundColor: p.ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.55)
            : p.accent.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.accent,
          selectedForegroundColor: p.onAccent,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: p.accent,
        labelStyle: TextStyle(color: p.ink),
        secondarySelectedColor: p.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
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
