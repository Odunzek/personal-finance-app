import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'mural_background.dart';

/// The brief wordmark animation on cold start. Layered above everything in
/// [MaterialApp.builder] rather than used as a route, so it covers the lock
/// screen too and leaves the navigator untouched when it goes.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1750),
  );

  // One controller driving staggered intervals, so the mark, the two words,
  // the rule under them, and the final fade-out stay in lockstep no matter
  // how the device is performing.
  late final _markScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.36, curve: Curves.easeOutBack),
  );
  late final _markFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.28, curve: Curves.easeOut),
  );
  late final _wordOne = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.22, 0.52, curve: Curves.easeOutCubic),
  );
  late final _wordTwo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.30, 0.62, curve: Curves.easeOutCubic),
  );
  late final _rule = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.46, 0.76, curve: Curves.easeOutCubic),
  );
  late final _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.84, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 1 - _exit.value,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: MuralBackground.hero(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _markFade.value,
                      child: Transform.scale(
                        scale: 0.6 + _markScale.value * 0.4,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.trendingUp,
                            size: 36,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Word('Fin', _wordOne, scheme.onSurface),
                        const SizedBox(width: 10),
                        _Word('Tracker', _wordTwo, scheme.primary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // A rule that draws outward from the centre, giving the
                    // wordmark something to settle onto.
                    Container(
                      width: 120 * _rule.value,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0),
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Word extends StatelessWidget {
  final String text;
  final Animation<double> animation;
  final Color color;

  const _Word(this.text, this.animation, this.color);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: animation.value,
      child: Transform.translate(
        offset: Offset(0, (1 - animation.value) * 14),
        child: Text(
          text,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            color: color,
          ),
        ),
      ),
    );
  }
}
