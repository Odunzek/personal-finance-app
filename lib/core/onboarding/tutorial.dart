import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/mural_background.dart';

/// Remembers whether the walkthrough has been shown. Stored in secure
/// storage only because that's already a dependency for the PIN — there's
/// nothing sensitive about this flag.
class TutorialStore {
  TutorialStore._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'tutorial_seen_v1';

  /// Defaults to "already seen" if storage throws, so a storage fault can
  /// never trap someone in a walkthrough they can't get rid of.
  static Future<bool> hasSeen() async {
    try {
      return await _storage.read(key: _key) != null;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      await _storage.write(key: _key, value: '1');
    } catch (_) {
      // Worst case it shows once more next launch.
    }
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String body;

  const _Page({required this.icon, required this.title, required this.body});
}

const _pages = [
  _Page(
    icon: LucideIcons.trendingUp,
    title: 'Welcome to Fin Tracker',
    body:
        'Keep personal and business money in separate profiles, on one '
        'account. Switch between them any time from Settings.',
  ),
  _Page(
    icon: LucideIcons.plus,
    title: 'Log it in seconds',
    body:
        'The + button adds money in or out: an amount, a category, and which '
        'account it came from. The date defaults to today.',
  ),
  _Page(
    icon: LucideIcons.arrowRightLeft,
    title: 'Accounts and transfers',
    body:
        'Tap any account to see everything that moved through it. Paying a '
        'card from chequing is a transfer, not an expense — it moves money '
        'between your own accounts without counting as spending.',
  ),
  _Page(
    icon: LucideIcons.chartPie,
    title: 'Budgets and trends',
    body:
        'Set a monthly limit per category and watch it fill. Trends charts '
        'where the money went and forecasts where the balance is heading.',
  ),
  _Page(
    icon: LucideIcons.listChecks,
    title: 'Plan what is next',
    body:
        'The wishlist holds things you mean to buy. Give one a budget, break '
        'it into items, and it turns red if those items outgrow the budget.',
  ),
  _Page(
    icon: LucideIcons.briefcase,
    title: 'Built for the business too',
    body:
        'A business profile adds a mileage log at CRA rates and printable '
        'statements for your records. Find both in Settings.',
  ),
];

/// A short walkthrough. Shown once on first run, and replayable from
/// Settings.
Future<void> showTutorial(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const TutorialScreen(),
      fullscreenDialog: true,
    ),
  );
}

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: MuralBackground.hero(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_isLast ? 'Done' : 'Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.14),
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 40,
                                  color: scheme.primary,
                                ),
                              )
                              .animate(key: ValueKey(i))
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 320.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 28),
                          Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              )
                              .animate(key: ValueKey('t$i'))
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: 0.15, end: 0),
                          const SizedBox(height: 12),
                          Text(
                                page.body,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              )
                              .animate(key: ValueKey('b$i'))
                              .fadeIn(delay: 60.ms, duration: 280.ms)
                              .slideY(begin: 0.15, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _index
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'Start using it' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
