import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/account_balance.dart';
import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../categories/data/category_repository.dart';
import '../data/account_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_screen.dart';
import '../../transactions/presentation/transaction_tile.dart';

/// Everything that has moved through one account, newest first, under its
/// current balance. Opened by tapping an account in the list.
class AccountDetailScreen extends StatefulWidget {
  final Account account;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;

  AccountDetailScreen({
    super.key,
    required this.account,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository();

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountData {
  final List<Transaction> transactions;
  final Map<int, Category> categoriesById;
  final Map<int, Account> accountsById;

  const _AccountData(this.transactions, this.categoriesById, this.accountsById);
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late Future<_AccountData> _dataFuture;
  bool _changed = false;

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

  Future<_AccountData> _fetch() async {
    final profileId = widget.account.profileId;
    // Every transaction, filtered in Dart rather than by account_id in the
    // query: a transfer *into* this account doesn't carry its id in
    // account_id, so a server-side filter would silently drop half of them.
    final results = await Future.wait([
      widget.transactionRepository.listTransactions(profileId),
      widget.categoryRepository.listAllCategories(profileId),
      // listAll, not active: a removed account still has to be nameable on
      // the other side of an old transfer.
      widget.accountRepository.listAllAccounts(profileId),
    ]);
    final all = results[0] as List<Transaction>;
    return _AccountData(
      all
          .where((t) => transactionTouchesAccount(t, widget.account.id))
          .toList(),
      {for (final c in results[1] as List<Category>) c.id: c},
      {for (final a in results[2] as List<Account>) a.id: a},
    );
  }

  Future<void> _openTransaction(Transaction t, Category? category) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TransactionDetailScreen(transaction: t, category: category),
      ),
    );
    if (changed == true) {
      _changed = true;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiability = widget.account.type == AccountType.liability;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: Text(widget.account.name),
        ),
        body: MuralBackground.ambient(
          child: FutureBuilder<_AccountData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AsyncErrorView(onRetry: _reload);
              }
              final data = snapshot.data;
              if (data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final balance = computeAccountBalance(
                widget.account,
                data.transactions,
              );
              var moneyIn = 0;
              var moneyOut = 0;
              for (final t in data.transactions) {
                final delta = signedAmountForAccount(t, widget.account.id);
                if (delta >= 0) {
                  moneyIn += delta;
                } else {
                  moneyOut -= delta;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: data.transactions.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _Header(
                      account: widget.account,
                      balance: balance,
                      moneyIn: moneyIn,
                      moneyOut: moneyOut,
                      isLiability: isLiability,
                      count: data.transactions.length,
                    );
                  }
                  final t = data.transactions[i - 1];
                  final category = data.categoriesById[t.categoryId];
                  return TransactionTile(
                        transaction: t,
                        category: category,
                        accountsById: data.accountsById,
                        focalAccountId: widget.account.id,
                        onTap: () => _openTransaction(t, category),
                      )
                      .animate()
                      .fadeIn(
                        delay: ((i - 1).clamp(0, 12) * 30).ms,
                        duration: 200.ms,
                      )
                      .slideX(begin: 0.02, end: 0);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Account account;
  final int balance;
  final int moneyIn;
  final int moneyOut;
  final bool isLiability;
  final int count;

  const _Header({
    required this.account,
    required this.balance,
    required this.moneyIn,
    required this.moneyOut,
    required this.isLiability,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiability ? 'Owed' : 'Balance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                MoneyText(
                  isLiability ? -balance : balance,
                  fontSize: 32,
                  color: isLiability ? scheme.error : null,
                ),
                const SizedBox(height: 4),
                Text(
                  isLiability
                      ? (account.debtKind?.label ?? 'Debt')
                      : 'Checking / Cash',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _Flow(
                        label: 'In',
                        amount: moneyIn,
                        icon: LucideIcons.arrowDownLeft,
                        color: scheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _Flow(
                        label: 'Out',
                        amount: moneyOut,
                        icon: LucideIcons.arrowUpRight,
                        color: scheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          count == 0
              ? 'No activity yet'
              : '$count transaction${count == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (count == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nothing has moved through this account yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _Flow extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  const _Flow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              formatMoney(amount),
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
