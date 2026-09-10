import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/account_balance.dart';
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
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: data.accounts.length,
              itemBuilder: (context, index) {
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
                                  ? LucideIcons.creditCard
                                  : LucideIcons.wallet,
                              color: isLiability
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(account.name),
                          subtitle: Text(
                            isLiability ? 'Credit card' : 'Checking / Cash',
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
