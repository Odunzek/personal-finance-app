import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/export/transactions_csv.dart';
import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/notifications/reminder_service.dart';
import '../../../core/security/pin_setup_screen.dart';
import '../../../core/security/pin_vault.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../main.dart';
import '../../accounts/data/account_repository.dart';
import '../../accounts/presentation/account_list_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../budgets/data/budget_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../profiles/presentation/profile_list_screen.dart';
import '../../recurring/data/recurring_rule_repository.dart';
import '../../recurring/presentation/recurring_rule_list_screen.dart';
import '../../transactions/data/transaction_repository.dart';

class SettingsScreen extends StatefulWidget {
  final Profile profile;
  final AuthRepository authRepository;
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final RecurringRuleRepository recurringRuleRepository;

  /// Called after returning from a screen that may have changed data other
  /// tabs depend on (categories, accounts), so the shell can refresh them.
  final VoidCallback? onDataChanged;

  SettingsScreen({
    super.key,
    required this.profile,
    required this.authRepository,
    this.onDataChanged,
    TransactionRepository? transactionRepository,
    BudgetRepository? budgetRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
    RecurringRuleRepository? recurringRuleRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       budgetRepository = budgetRepository ?? SupabaseBudgetRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository(),
       recurringRuleRepository =
           recurringRuleRepository ?? SupabaseRecurringRuleRepository();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetting = false;
  bool _exporting = false;
  bool _hasPin = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loadedSecurityState = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final hasPin = await PinVault.hasPin();
    final reminderEnabled = await ReminderService.instance.isEnabled();
    final reminderTime = await ReminderService.instance.getTime();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _reminderEnabled = reminderEnabled;
      _reminderTime = reminderTime;
      _loadedSecurityState = true;
    });
  }

  Future<void> _openAppLock() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PinSetupScreen(hasPin: _hasPin)),
    );
    if (changed == true) _loadSecurityState();
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (enabled) {
      final picked = await showTimePicker(
        context: context,
        initialTime: _reminderTime,
      );
      if (picked == null) return;
      await ReminderService.instance.setReminder(picked);
      setState(() {
        _reminderEnabled = true;
        _reminderTime = picked;
      });
    } else {
      await ReminderService.instance.cancel();
      setState(() => _reminderEnabled = false);
    }
  }

  Future<void> _changeReminderTime() async {
    if (!_reminderEnabled) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    await ReminderService.instance.setReminder(picked);
    setState(() => _reminderTime = picked);
  }

  Future<void> _signOut() async {
    await widget.authRepository.signOut();
    if (!mounted) return;
    // Sign-out happens from deep inside MainShell's navigation stack, below
    // which AuthGate's route was already popped when the profile was first
    // opened (pushAndRemoveUntil) — so nothing is left listening to the auth
    // stream to bring back the sign-in screen. Rebuild it explicitly.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthGate()),
      (route) => false,
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final results = await Future.wait([
        widget.transactionRepository.listTransactions(widget.profile.id),
        widget.categoryRepository.listActiveCategories(widget.profile.id),
        widget.accountRepository.listActiveAccounts(widget.profile.id),
      ]);
      final transactions = results[0] as List<model.Transaction>;
      final categories = results[1] as List<Category>;
      final accounts = results[2] as List<Account>;

      final csv = buildTransactionsCsv(
        transactions: transactions,
        categoriesById: {for (final c in categories) c.id: c},
        accountsById: {for (final a in accounts) a.id: a},
      );

      final dir = await getTemporaryDirectory();
      final safeName = widget.profile.displayName.replaceAll(
        RegExp(r'[^A-Za-z0-9]+'),
        '_',
      );
      final file = File('${dir.path}/kinscope_${safeName}_transactions.csv');
      await file.writeAsString(csv);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Kinscope transactions — ${widget.profile.displayName}',
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmResetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset data?'),
        content: Text(
          'This permanently deletes every transaction, budget, and savings '
          'target for "${widget.profile.displayName}". Your categories and '
          'profile stay in place, so you can start fresh right away. This '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resetting = true);
    try {
      await widget.transactionRepository.deleteAllForProfile(widget.profile.id);
      await widget.budgetRepository.deleteAllForProfile(widget.profile.id);
      await widget.recurringRuleRepository.deleteAllForProfile(
        widget.profile.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared. Starting fresh.')),
      );
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.users),
                title: const Text('Profiles'),
                trailing: Text(widget.profile.displayName),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileListScreen(
                      authRepository: widget.authRepository,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.tags),
                title: const Text('Categories'),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryListScreen(profile: widget.profile),
                    ),
                  );
                  widget.onDataChanged?.call();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.wallet),
                title: const Text('Accounts'),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AccountListScreen(profile: widget.profile),
                    ),
                  );
                  widget.onDataChanged?.call();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.repeat),
                title: const Text('Recurring'),
                subtitle: const Text(
                  'Rent, salary, subscriptions on autopilot',
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RecurringRuleListScreen(profile: widget.profile),
                    ),
                  );
                  widget.onDataChanged?.call();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.sun),
                title: const Text('Appearance'),
                trailing: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, _) {
                    final effectiveIsDark =
                        mode == ThemeMode.dark ||
                        (mode == ThemeMode.system &&
                            MediaQuery.platformBrightnessOf(context) ==
                                Brightness.dark);
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {
                        effectiveIsDark ? ThemeMode.dark : ThemeMode.light,
                      },
                      onSelectionChanged: (s) =>
                          themeModeNotifier.value = s.first,
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.info),
                title: const Text('About'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Kinscope',
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        if (_loadedSecurityState)
          Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.lock),
                      title: const Text('App lock'),
                      subtitle: Text(
                        _hasPin ? 'On · PIN required to open the app' : 'Off',
                      ),
                      onTap: _openAppLock,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.bellRing),
                      title: const Text('Daily reminder'),
                      subtitle: Text(
                        _reminderEnabled
                            ? 'On · ${_reminderTime.format(context)} · tap to change'
                            : 'Off · nudges you to log today\'s spending',
                      ),
                      onTap: _reminderEnabled ? _changeReminderTime : null,
                      trailing: Switch(
                        value: _reminderEnabled,
                        onChanged: _toggleReminder,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 40.ms, duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: _exporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.download),
                title: const Text('Export data'),
                subtitle: const Text('Share all transactions as a CSV file'),
                onTap: _exporting ? null : _exportCsv,
              ),
            )
            .animate()
            .fadeIn(delay: 60.ms, duration: 300.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: _resetting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        LucideIcons.rotateCcw,
                        color: Theme.of(context).colorScheme.error,
                      ),
                title: const Text('Reset data'),
                subtitle: const Text(
                  'Clear all transactions, budgets, and goals',
                ),
                textColor: Theme.of(context).colorScheme.error,
                onTap: _resetting ? null : _confirmResetData,
              ),
            )
            .animate()
            .fadeIn(delay: 80.ms, duration: 300.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  LucideIcons.logOut,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Sign out'),
                textColor: Theme.of(context).colorScheme.error,
                onTap: _signOut,
              ),
            )
            .animate()
            .fadeIn(delay: 120.ms, duration: 300.ms)
            .slideY(begin: 0.05, end: 0),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: content,
          ),
        ),
      ],
    );
  }
}
