import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/profile.dart';
import '../../auth/data/auth_repository.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transactions/presentation/activity_screen.dart';
import '../../transactions/presentation/quick_add_screen.dart';
import '../../trends/presentation/trends_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  final Profile profile;
  final AuthRepository authRepository;

  const MainShell({
    super.key,
    required this.profile,
    required this.authRepository,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshTick = 0;

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

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        key: ValueKey('home-$_refreshTick'),
        profile: widget.profile,
      ),
      ActivityScreen(
        key: ValueKey('activity-$_refreshTick'),
        profile: widget.profile,
      ),
      BudgetsScreen(
        key: ValueKey('budgets-$_refreshTick'),
        profile: widget.profile,
      ),
      TrendsScreen(
        key: ValueKey('trends-$_refreshTick'),
        profile: widget.profile,
      ),
      SettingsScreen(
        profile: widget.profile,
        authRepository: widget.authRepository,
        onDataChanged: _bumpRefresh,
      ),
    ];

    final destinations = const [
      NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
      NavigationDestination(icon: Icon(LucideIcons.receiptText), label: 'Activity'),
      NavigationDestination(icon: Icon(LucideIcons.chartPie), label: 'Budgets'),
      NavigationDestination(icon: Icon(LucideIcons.trendingUp), label: 'Trends'),
      NavigationDestination(icon: Icon(LucideIcons.settings), label: 'Settings'),
    ];
    final railDestinations = const [
      NavigationRailDestination(icon: Icon(LucideIcons.house), label: Text('Home')),
      NavigationRailDestination(icon: Icon(LucideIcons.receiptText), label: Text('Activity')),
      NavigationRailDestination(icon: Icon(LucideIcons.chartPie), label: Text('Budgets')),
      NavigationRailDestination(icon: Icon(LucideIcons.trendingUp), label: Text('Trends')),
      NavigationRailDestination(icon: Icon(LucideIcons.settings), label: Text('Settings')),
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
              Expanded(child: IndexedStack(index: _index, children: tabs)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
