import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/profile.dart';
import '../../../core/onboarding/tutorial.dart';
import '../../../core/recurring/recurring_rule_runner.dart';
import '../../../core/widgets/mural_background.dart';
import '../../auth/data/auth_repository.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../recurring/data/recurring_rule_repository.dart';
import '../../recurring/presentation/recurring_rule_list_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../wishlist/presentation/wishlist_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/activity_screen.dart';
import '../../transactions/presentation/quick_add_screen.dart';
import '../../trends/presentation/trends_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  final Profile profile;
  final AuthRepository authRepository;
  final RecurringRuleRepository recurringRuleRepository;
  final TransactionRepository transactionRepository;

  MainShell({
    super.key,
    required this.profile,
    required this.authRepository,
    RecurringRuleRepository? recurringRuleRepository,
    TransactionRepository? transactionRepository,
  }) : recurringRuleRepository =
           recurringRuleRepository ?? SupabaseRecurringRuleRepository(),
       transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _catchUpRecurringRules();
    _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    if (await TutorialStore.hasSeen()) return;
    if (!mounted) return;
    // Marked seen before showing, not after: dismissing it any way at all
    // (back gesture included) still counts as having seen it.
    await TutorialStore.markSeen();
    if (mounted) await showTutorial(context);
  }

  Future<void> _catchUpRecurringRules() async {
    try {
      final createdAny = await RecurringRuleRunner.catchUp(
        recurringRuleRepository: widget.recurringRuleRepository,
        transactionRepository: widget.transactionRepository,
        profileId: widget.profile.id,
      );
      if (createdAny && mounted) setState(() => _refreshTick++);
    } catch (_) {
      // Offline at launch — skip silently; the next profile open catches up,
      // and rules advance per-occurrence so nothing is double-created.
    }
  }

  Future<void> _openQuickAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuickAddScreen(profile: widget.profile),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) setState(() => _refreshTick++);
  }

  void _bumpRefresh() => setState(() => _refreshTick++);

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          profile: widget.profile,
          authRepository: widget.authRepository,
          onDataChanged: _bumpRefresh,
        ),
      ),
    );
  }

  Future<void> _openWishlist() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WishlistScreen(profile: widget.profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        key: ValueKey('home-$_refreshTick'),
        profile: widget.profile,
        onOpenSettings: _openSettings,
        onOpenWishlist: _openWishlist,
        onDataChanged: _bumpRefresh,
      ),
      ActivityScreen(
        key: ValueKey('activity-$_refreshTick'),
        profile: widget.profile,
        onDataChanged: _bumpRefresh,
      ),
      BudgetsScreen(
        key: ValueKey('budgets-$_refreshTick'),
        profile: widget.profile,
      ),
      TrendsScreen(
        key: ValueKey('trends-$_refreshTick'),
        profile: widget.profile,
      ),
      RecurringRuleListScreen(
        key: ValueKey('recurring-$_refreshTick'),
        profile: widget.profile,
      ),
    ];

    final destinations = const [
      NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
      NavigationDestination(
        icon: Icon(LucideIcons.receiptText),
        label: 'Activity',
      ),
      NavigationDestination(icon: Icon(LucideIcons.chartPie), label: 'Budgets'),
      NavigationDestination(
        icon: Icon(LucideIcons.trendingUp),
        label: 'Trends',
      ),
      NavigationDestination(icon: Icon(LucideIcons.repeat), label: 'Recurring'),
    ];
    final railDestinations = const [
      NavigationRailDestination(
        icon: Icon(LucideIcons.house),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.receiptText),
        label: Text('Activity'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.chartPie),
        label: Text('Budgets'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.trendingUp),
        label: Text('Trends'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.repeat),
        label: Text('Recurring'),
      ),
    ];
    final isTablet = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
    final fab = _index == 4
        ? null
        : FloatingActionButton(
            onPressed: _openQuickAdd,
            child: const Icon(LucideIcons.plus),
          );

    if (isTablet) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                leading: fab,
                destinations: railDestinations,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: MuralBackground.ambient(
                  child: IndexedStack(index: _index, children: tabs),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: MuralBackground.ambient(
          child: IndexedStack(index: _index, children: tabs),
        ),
      ),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
