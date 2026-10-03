import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/account.dart';
import '../../../core/models/account_balance.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/orbit_watermark.dart';
import '../../accounts/data/account_repository.dart';
import '../../accounts/presentation/account_detail_screen.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_screen.dart';
import '../../transactions/presentation/transaction_tile.dart';
import 'business_summary_card.dart';

class HomeData {
  final List<model.Transaction> all;
  final Map<int, Category> categoriesById;
  final List<Account> accounts;

  const HomeData(this.all, this.categoriesById, this.accounts);
}

class HomeScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final VoidCallback? onDataChanged;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenWishlist;

  HomeScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
    this.onDataChanged,
    this.onOpenSettings,
    this.onOpenWishlist,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = _fetch();
  }

  Future<HomeData> _fetch() async {
    final results = await Future.wait([
      widget.transactionRepository.listTransactions(widget.profile.id),
      widget.categoryRepository.listActiveCategories(widget.profile.id),
      widget.accountRepository.listActiveAccounts(widget.profile.id),
    ]);
    final transactions = results[0] as List<model.Transaction>;
    final categories = results[1] as List<Category>;
    final accounts = results[2] as List<Account>;
    return HomeData(transactions, {
      for (final c in categories) c.id: c,
    }, accounts);
  }

  Future<void> _reload() async {
    setState(_load);
    await _dataFuture;
  }

  Future<void> _openAccount(Account account) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AccountDetailScreen(account: account)),
    );
    if (changed != true || !mounted) return;
    await _reload();
    // Editing a transaction in there also moves Activity, Budgets and Trends.
    widget.onDataChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AsyncErrorView(onRetry: () => setState(_load));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeData data) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekAgo = now.subtract(const Duration(days: 7));

    final netWorth = data.accounts.fold<int>(
      0,
      (sum, a) => sum + computeAccountBalance(a, data.all),
    );

    var monthIncome = 0;
    var monthExpense = 0;
    var weekNet = 0;
    for (final t in data.all) {
      if (t.isTransfer) continue;
      final signed = t.type == model.TransactionKind.income
          ? t.amountMinorUnits
          : -t.amountMinorUnits;
      if (!t.occurredAt.isBefore(monthStart)) {
        if (t.type == model.TransactionKind.income) {
          monthIncome += t.amountMinorUnits;
        } else {
          monthExpense += t.amountMinorUnits;
        }
      }
      if (!t.occurredAt.isBefore(weekAgo)) {
        weekNet += signed;
      }
    }
    final recent = data.all.take(5).toList();

    final balanceBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.profile.displayName.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.onOpenWishlist != null)
              IconButton(
                onPressed: widget.onOpenWishlist,
                icon: const Icon(LucideIcons.listChecks, size: 20),
                tooltip: 'Wishlist',
                visualDensity: VisualDensity.compact,
              ),
            if (widget.onOpenSettings != null)
              IconButton(
                onPressed: widget.onOpenSettings,
                icon: const Icon(LucideIcons.settings, size: 20),
                tooltip: 'Settings',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Net worth', style: Theme.of(context).textTheme.bodyMedium),
        AnimatedMoneyText(netWorth, fontSize: 46),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              weekNet >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 14,
              color: weekNet >= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            MoneyText(
              weekNet,
              showSign: true,
              fontSize: 14,
              color: weekNet >= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            Text(' this week', style: Theme.of(context).textTheme.bodySmall),
          ],
        ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
      ],
    );

    final accountsRow = data.accounts.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.accounts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final account = data.accounts[i];
                final balance = computeAccountBalance(account, data.all);
                final isLiability = account.type == AccountType.liability;
                return Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openAccount(account),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            account.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          MoneyText(
                            isLiability ? -balance : balance,
                            fontSize: 15,
                            color: isLiability
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );

    Widget recentTile(int i) =>
        TransactionTile(
              transaction: recent[i],
              category: recent[i].categoryId == null
                  ? null
                  : data.categoriesById[recent[i].categoryId],
              accountsById: {for (final a in data.accounts) a.id: a},
              onTap: () async {
                final t = recent[i];
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(
                      transaction: t,
                      category: t.categoryId == null
                          ? null
                          : data.categoriesById[t.categoryId],
                    ),
                  ),
                );
                if (changed == true) {
                  _reload();
                  widget.onDataChanged?.call();
                }
              },
            )
            .animate()
            .fadeIn(delay: (150 + i * 50).ms, duration: 250.ms)
            .slideX(begin: 0.03, end: 0);

    final recentHeader = Text(
      'Recent',
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );

    final recentBody = data.all.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  LucideIcons.walletMinimal,
                  size: 36,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nothing recorded yet',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first transaction to get started.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : Column(
            children: [for (var i = 0; i < recent.length; i++) recentTile(i)],
          );

    final recentCard = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: recentBody,
      ),
    );

    final businessSummaryCard = widget.profile.type == ProfileType.business
        ? BusinessSummaryCard(
            allTransactions: data.all,
            categoriesById: data.categoriesById,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kTabletBreakpoint) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -24,
                    right: -60,
                    child: OrbitWatermark(
                      size: 200,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.14),
                    ),
                  ),
                  balanceBlock,
                ],
              ),
              const SizedBox(height: 16),
              accountsRow,
              const SizedBox(height: 16),
              Row(
                    children: [
                      Expanded(
                        child: _StatCard(label: 'Income', amount: monthIncome),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Expense',
                          amount: monthExpense,
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms)
                  .slideY(begin: 0.08, end: 0),
              if (businessSummaryCard != null) ...[
                const SizedBox(height: 16),
                businessSummaryCard,
              ],
              const SizedBox(height: 24),
              recentHeader,
              const SizedBox(height: 8),
              recentCard,
            ],
          );
        }

        // Tablet: a real two-column dashboard grid (balance | stats), with
        // the recent list spanning the full width below and filling the
        // remaining height — matching the "nav rail plus one wide column"
        // tablet layout from the design, instead of leaving dead space.
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: -16,
                                right: -30,
                                child: OrbitWatermark(
                                  size: 150,
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: 0.14),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  balanceBlock,
                                  const SizedBox(height: 16),
                                  accountsRow,
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Income',
                              amount: monthIncome,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Expense',
                              amount: monthExpense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              if (businessSummaryCard != null) ...[
                const SizedBox(height: 16),
                businessSummaryCard,
              ],
              const SizedBox(height: 20),
              recentHeader,
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(child: recentBody),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int amount;

  const _StatCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            MoneyText(amount, fontSize: 20),
          ],
        ),
      ),
    );
  }
}
