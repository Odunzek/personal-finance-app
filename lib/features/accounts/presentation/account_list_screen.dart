import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/account_balance.dart';
import '../../../core/models/money.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/account_repository.dart';
import 'account_form_sheet.dart';

class AccountListScreen extends StatefulWidget {
  final Profile profile;
  final AccountRepository accountRepository;
  final TransactionRepository transactionRepository;

  AccountListScreen({
    super.key,
    required this.profile,
    AccountRepository? accountRepository,
    TransactionRepository? transactionRepository,
  }) : accountRepository = accountRepository ?? SupabaseAccountRepository(),
       transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository();

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountsData {
  final List<Account> accounts;
  final List<Transaction> transactions;

  const _AccountsData(this.accounts, this.transactions);
}

class _AccountListScreenState extends State<AccountListScreen> {
  late Future<_AccountsData> _dataFuture;

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

  Future<_AccountsData> _fetch() async {
    final results = await Future.wait([
      widget.accountRepository.listActiveAccounts(widget.profile.id),
      widget.transactionRepository.listTransactions(widget.profile.id),
    ]);
    return _AccountsData(
      results[0] as List<Account>,
      results[1] as List<Transaction>,
    );
  }

  Future<void> _addAccount() async {
    final result = await showAccountFormSheet(context);
    if (result == null) return;
    await widget.accountRepository.createAccount(
      profileId: widget.profile.id,
      name: result.name,
      type: result.type,
      debtKind: result.debtKind,
      startingBalanceMinorUnits: result.startingBalanceMinorUnits,
    );
    _reload();
  }

  Future<void> _deactivateAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          '"${account.name}" will no longer be available for new '
          'transactions. Existing transactions keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.accountRepository.deactivateAccount(account.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(LucideIcons.plus),
      ),
      body: MuralBackground.ambient(
        child: FutureBuilder<_AccountsData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            if (data.accounts.isEmpty) {
              return _EmptyState(onAdd: _addAccount);
            }
            final debtSummary = _debtSummary(context, data);
            final headerCount = debtSummary == null ? 0 : 1;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: data.accounts.length + headerCount,
              itemBuilder: (context, i) {
                if (debtSummary != null && i == 0) return debtSummary;
                final index = i - headerCount;
                final account = data.accounts[index];
                final balance = computeAccountBalance(
                  account,
                  data.transactions,
                );
                final isLiability = account.type == AccountType.liability;
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
                            backgroundColor: isLiability
                                ? Theme.of(context).colorScheme.error
                                      .withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.primary
                                      .withValues(alpha: 0.15),
                            child: Icon(
                              isLiability
                                  ? _debtIcon(account.debtKind)
                                  : LucideIcons.wallet,
                              color: isLiability
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(account.name),
                          subtitle: Text(
                            isLiability
                                ? (account.debtKind?.label ?? 'Debt')
                                : 'Checking / Cash',
                          ),
                          trailing: MoneyText(
                            isLiability ? -balance : balance,
                            fontSize: 16,
                            color: isLiability
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                          onLongPress: () => _deactivateAccount(account),
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
    );
  }

  IconData _debtIcon(DebtKind? kind) => switch (kind) {
    DebtKind.creditCard => LucideIcons.creditCard,
    DebtKind.loan => LucideIcons.landmark,
    DebtKind.bnpl => LucideIcons.repeat,
    DebtKind.shareholderLoan => LucideIcons.handshake,
    DebtKind.other => LucideIcons.creditCard,
    null => LucideIcons.creditCard,
  };

  /// A combined "total debt" card broken down by kind, only shown once
  /// there's more than one debt account to actually total up.
  Widget? _debtSummary(BuildContext context, _AccountsData data) {
    final liabilities = data.accounts
        .where((a) => a.type == AccountType.liability)
        .toList();
    if (liabilities.length < 2) return null;

    final byKind = <DebtKind, int>{};
    for (final account in liabilities) {
      final owed = -computeAccountBalance(account, data.transactions);
      final kind = account.debtKind ?? DebtKind.other;
      byKind[kind] = (byKind[kind] ?? 0) + owed;
    }
    final total = byKind.values.fold<int>(0, (sum, v) => sum + v);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total debt', style: Theme.of(context).textTheme.bodyMedium),
              MoneyText(
                total,
                fontSize: 28,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final entry in byKind.entries)
                    Text(
                      '${entry.key.label}: ${formatMoney(entry.value)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
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
              LucideIcons.wallet,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No accounts yet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your checking account or a credit card to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add an account'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
