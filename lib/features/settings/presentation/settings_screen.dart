import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/export/statement_pdf.dart';
import '../../../core/export/transactions_csv.dart';
import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/notifications/reminder_service.dart';
import '../../../core/security/pin_setup_screen.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/mural_background.dart';
import '../../../core/security/pin_vault.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../main.dart';
import '../../accounts/data/account_repository.dart';
import '../../accounts/presentation/account_list_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../budgets/data/budget_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../mileage/presentation/mileage_screen.dart';
import '../../profiles/presentation/profile_list_screen.dart';
import '../../recurring/data/recurring_rule_repository.dart';
import '../../recurring/presentation/recurring_rule_list_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import 'statement_options_sheet.dart';

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
  bool _printing = false;
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
        // All, not just active: archived categories/accounts must still
        // export by name rather than as blanks.
        widget.categoryRepository.listAllCategories(widget.profile.id),
        widget.accountRepository.listAllAccounts(widget.profile.id),
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
    } catch (_) {
      if (mounted) showActionError(context, 'Export');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _printStatement() async {
    final accounts = await widget.accountRepository.listActiveAccounts(
      widget.profile.id,
    );
    if (!mounted) return;
    final options = await showStatementOptionsSheet(
      context,
      accounts: accounts,
    );
    if (options == null) return;

    setState(() => _printing = true);
    try {
      final results = await Future.wait([
        widget.transactionRepository.listTransactions(
          widget.profile.id,
          from: options.from,
          // The repository's `to` is exclusive; the picker's To is a date at
          // midnight, so pass the following calendar day or every
          // transaction on the chosen final day falls out of the statement.
          to: DateTime(options.to.year, options.to.month, options.to.day + 1),
        ),
        // All, not just active: the statement's history must resolve names
        // for categories and accounts archived since.
        widget.categoryRepository.listAllCategories(widget.profile.id),
        widget.accountRepository.listAllAccounts(widget.profile.id),
      ]);
      final allInRange = results[0] as List<model.Transaction>;
      final categories = results[1] as List<Category>;
      final allAccounts = results[2] as List<Account>;
      // Filtering by accountId alone only matches the "from" side of a
      // transfer, so a statement for e.g. Visa would miss money transferred
      // into it from Cash. Match either side, same as computeAccountBalance.
      final accountId = options.account?.id;
      final transactions = accountId == null
          ? allInRange
          : allInRange
                .where(
                  (t) =>
                      t.accountId == accountId ||
                      t.transferAccountId == accountId,
                )
                .toList();

      final doc = await buildStatementPdf(
        profile: widget.profile,
        account: options.account,
        from: options.from,
        to: options.to,
        transactions: transactions,
        categoriesById: {for (final c in categories) c.id: c},
        accountsById: {for (final a in allAccounts) a.id: a},
      );

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (_) {
      if (mounted) showActionError(context, 'Generating the statement');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _confirmResetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset data?'),
        content: Text(
          'This permanently deletes every transaction, budget, savings '
          'target, and recurring rule for "${widget.profile.displayName}". '
          'Your categories, accounts, wishlist, and the profile itself stay '
          'in place, so you can start fresh right away. This cannot be '
          'undone.',
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
      widget.onDataChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared. Starting fresh.')),
      );
    } catch (_) {
      // The three deletes run in sequence, so a mid-way failure can leave a
      // partial reset — surface it so the user knows to run it again.
      if (mounted) {
        showActionError(context, 'Reset (it may be partial — run it again)');
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              if (widget.profile.type == ProfileType.business) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.car),
                  title: const Text('Mileage log'),
                  subtitle: const Text(
                    'Track business trips for the CRA per-km deduction',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MileageScreen(profile: widget.profile),
                    ),
                  ),
                ),
              ],
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
                leading: _printing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.printer),
                title: const Text('Print statement'),
                subtitle: const Text(
                  'Generate a printable PDF for an account and date range',
                ),
                onTap: _printing ? null : _printStatement,
              ),
            )
            .animate()
            .fadeIn(delay: 70.ms, duration: 300.ms)
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

    // This screen is pushed as its own route (not a MainShell tab), so it
    // needs its own Scaffold — without one, the route paints over the raw
    // window background, which reads as black in light mode.
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: MuralBackground.ambient(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
