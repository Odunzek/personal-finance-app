import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// A fade-through route transition: the outgoing page fades out and slides
/// back a touch while the incoming one fades up into place. Replaces the
/// default Android zoom, which reads as a jolt on dense list screens.
class _FadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: incoming,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(incoming),
        child: child,
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  /// Shared across every button variant so that two buttons sitting in the
  /// same row match in corner radius and height.
  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );
  static const _buttonMinSize = Size(0, 52);
  static const _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

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
      // Material's default Android route transition is a zoom that reads as a
      // jolt on a dense list screen. A shared fade-through is calmer and
      // matches the in-screen fade/slide used throughout.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughTransitionBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionBuilder(),
        },
      ),
      textTheme: bodyFont.apply(bodyColor: p.ink, displayColor: p.ink),
      // The seeded scheme's surface-container roles are a cold neutral grey
      // derived from the accent's hue, which clashed badly with the warm
      // cream background in light mode (account chips and the nav bar read as
      // dirty grey panels). Pinning them to the palette's own warm tones --
      // and the variant/outline roles with them -- keeps every surface in one
      // family instead of two.
      colorScheme: seededScheme.copyWith(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.card,
        onSurface: p.ink,
        error: p.over,
        onSurfaceVariant: p.muted,
        outline: p.muted2,
        outlineVariant: p.line,
        surfaceContainerLowest: p.card,
        surfaceContainerLow: Color.lerp(p.background, p.card, 0.6),
        surfaceContainer: Color.lerp(p.background, p.chip, 0.5),
        surfaceContainerHigh: Color.lerp(p.background, p.chip, 0.8),
        surfaceContainerHighest: p.chip,
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
      // Every button shape is defined here rather than per-call-site. Only
      // ElevatedButton used to be themed, so an Elevated (14px radius) next to
      // an Outlined or Text button (Material's default stadium) rounded
      // differently and sat at a different height -- visibly mismatched
      // wherever two appeared in the same row.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          padding: _buttonPadding,
          minimumSize: _buttonMinSize,
          shape: _buttonShape,
          textStyle: _buttonTextStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          padding: _buttonPadding,
          minimumSize: _buttonMinSize,
          shape: _buttonShape,
          textStyle: _buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accentText,
          padding: _buttonPadding,
          minimumSize: _buttonMinSize,
          shape: _buttonShape,
          side: BorderSide(color: p.line),
          textStyle: _buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.accent,
          selectedForegroundColor: p.onAccent,
          side: BorderSide(color: p.line),
          shape: _buttonShape,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accent.withValues(alpha: 0.18),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: p.accent,
        backgroundColor: p.chip,
        checkmarkColor: p.onAccent,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // A flat label color left selected chips rendering ink-on-accent --
        // near-white text on light violet in dark mode, which was unreadable.
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? p.onAccent : p.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
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
