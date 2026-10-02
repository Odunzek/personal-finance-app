import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/recurring_rule.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../accounts/data/account_repository.dart';
import '../../categories/data/category_repository.dart';
import '../data/recurring_rule_repository.dart';
import 'recurring_rule_form_sheet.dart';

class RecurringRuleListScreen extends StatefulWidget {
  final Profile profile;
  final RecurringRuleRepository recurringRuleRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;

  RecurringRuleListScreen({
    super.key,
    required this.profile,
    RecurringRuleRepository? recurringRuleRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
  }) : recurringRuleRepository =
           recurringRuleRepository ?? SupabaseRecurringRuleRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository();

  @override
  State<RecurringRuleListScreen> createState() =>
      _RecurringRuleListScreenState();
}

class _RecurringRulesData {
  final List<RecurringRule> rules;
  final List<Category> categories;
  final List<Account> accounts;

  const _RecurringRulesData(this.rules, this.categories, this.accounts);
}

class _RecurringRuleListScreenState extends State<RecurringRuleListScreen> {
  late Future<_RecurringRulesData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dataFuture = _fetch();
    });
  }

  Future<_RecurringRulesData> _fetch() async {
    final results = await Future.wait([
      widget.recurringRuleRepository.listActiveRules(widget.profile.id),
      widget.categoryRepository.listActiveCategories(widget.profile.id),
      widget.accountRepository.listActiveAccounts(widget.profile.id),
    ]);
    return _RecurringRulesData(
      results[0] as List<RecurringRule>,
      results[1] as List<Category>,
      results[2] as List<Account>,
    );
  }

  Future<void> _addRule(_RecurringRulesData data) async {
    if (data.categories.isEmpty || data.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a category and an account first.')),
      );
      return;
    }
    final result = await showRecurringRuleFormSheet(
      context,
      categories: data.categories,
      accounts: data.accounts,
    );
    if (result == null) return;
    await widget.recurringRuleRepository.createRule(
      profileId: widget.profile.id,
      accountId: result.accountId,
      categoryId: result.categoryId,
      toAccountId: result.toAccountId,
      type: result.type,
      amountMinorUnits: result.amountMinorUnits,
      frequency: result.frequency,
      nextDueDate: result.nextDueDate,
      note: result.note,
    );
    _reload();
  }

  Future<void> _confirmRemove(RecurringRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this recurring transaction?'),
        content: const Text(
          'Transactions it already created stay in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.recurringRuleRepository.deactivateRule(rule.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      body: MuralBackground.ambient(
        child: FutureBuilder<_RecurringRulesData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AsyncErrorView(onRetry: _reload);
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (data.rules.isEmpty) {
              return _EmptyState(onAdd: () => _addRule(data));
            }
            final categoriesById = {for (final c in data.categories) c.id: c};
            final accountsById = {for (final a in data.accounts) a.id: a};
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: data.rules.length,
              itemBuilder: (context, index) {
                final rule = data.rules[index];
                final category = categoriesById[rule.categoryId];
                final account = accountsById[rule.accountId];
                final toAccount = accountsById[rule.toAccountId];
                final isIncome = rule.type == TransactionKind.income;
                final title = rule.isTransfer
                    ? '${account?.name ?? 'Account'} → ${toAccount?.name ?? 'Account'}'
                    : (category?.name ?? 'Uncategorized');
                final subtitle = rule.isTransfer
                    ? '${rule.frequency.label} · '
                          'next ${DateFormat.MMMd().format(rule.nextDueDate)}'
                    : '${rule.frequency.label} · ${account?.name ?? ''} · '
                          'next ${DateFormat.MMMd().format(rule.nextDueDate)}';
                return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                            child: Icon(
                              rule.isTransfer
                                  ? LucideIcons.arrowRightLeft
                                  : LucideIcons.repeat,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(title),
                          subtitle: Text(subtitle),
                          trailing: MoneyText(
                            rule.isTransfer
                                ? rule.amountMinorUnits
                                : (isIncome
                                      ? rule.amountMinorUnits
                                      : -rule.amountMinorUnits),
                            fontSize: 15,
                          ),
                          onLongPress: () => _confirmRemove(rule),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (index * 40).ms, duration: 200.ms)
                    .slideX(begin: 0.03, end: 0);
              },
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<_RecurringRulesData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return FloatingActionButton(
            onPressed: data == null ? null : () => _addRule(data),
            child: const Icon(LucideIcons.plus),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.repeat,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up rent, salary, or subscriptions once and they\'ll log '
              'themselves on schedule.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAdd, child: const Text('Add one')),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
