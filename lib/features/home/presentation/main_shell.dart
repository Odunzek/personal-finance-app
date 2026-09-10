import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      floatingActionButton: _index == 4
          ? null
          : FloatingActionButton(
              onPressed: _openQuickAdd,
              child: const Icon(LucideIcons.plus),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.receiptText), label: 'Activity'),
          NavigationDestination(icon: Icon(LucideIcons.chartPie), label: 'Budgets'),
          NavigationDestination(icon: Icon(LucideIcons.trendingUp), label: 'Trends'),
          NavigationDestination(icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
