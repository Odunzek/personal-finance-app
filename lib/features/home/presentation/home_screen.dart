import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/orbit_watermark.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_screen.dart';
import '../../transactions/presentation/transaction_tile.dart';

class HomeData {
  final List<model.Transaction> all;
  final Map<int, Category> categoriesById;

  const HomeData(this.all, this.categoriesById);
}

class HomeScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final VoidCallback? onDataChanged;

  HomeScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    this.onDataChanged,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

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
    ]);
    final transactions = results[0] as List<model.Transaction>;
    final categories = results[1] as List<Category>;
    return HomeData(
      transactions,
      {for (final c in categories) c.id: c},
    );
  }

  Future<void> _reload() async {
    setState(_load);
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.all.isEmpty) {
            return _buildEmpty(context);
          }
          return _buildContent(context, data);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Text(
          widget.profile.displayName.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text('Total balance', style: Theme.of(context).textTheme.bodyMedium),
        const MoneyText(0, fontSize: 46),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.walletMinimal,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing recorded yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your first transaction to get started.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, HomeData data) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekAgo = now.subtract(const Duration(days: 7));

    var balance = 0;
    var monthIncome = 0;
    var monthExpense = 0;
    var weekNet = 0;
    for (final t in data.all) {
      final signed = t.type == CategoryType.income
          ? t.amountMinorUnits
          : -t.amountMinorUnits;
      balance += signed;
      if (!t.occurredAt.isBefore(monthStart)) {
        if (t.type == CategoryType.income) {
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
        Text(
          widget.profile.displayName.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text('Total balance', style: Theme.of(context).textTheme.bodyMedium),
        AnimatedMoneyText(balance, fontSize: 46),
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

    Widget recentTile(int i) => TransactionTile(
      transaction: recent[i],
      category: data.categoriesById[recent[i].categoryId],
      onTap: () async {
        final t = recent[i];
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transaction: t,
              category: data.categoriesById[t.categoryId],
            ),
          ),
        );
        if (changed == true) {
          _reload();
          widget.onDataChanged?.call();
        }
      },
    ).animate().fadeIn(delay: (150 + i * 50).ms, duration: 250.ms).slideX(begin: 0.03, end: 0);

    final recentHeader = Text(
      'Recent',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    final recentCard = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [for (var i = 0; i < recent.length; i++) recentTile(i)]),
      ),
    );

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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  balanceBlock,
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Income', amount: monthIncome)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Expense', amount: monthExpense)),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 24),
              recentHeader,
              const SizedBox(height: 8),
              recentCard,
            ],
          );
        }

        // Tablet: a real two-column dashboard grid (balance | stats), with
        // the recent list spanning the full width below — matching the
        // "nav rail plus one wide column" tablet layout from the design.
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
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
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                              ),
                            ),
                            balanceBlock,
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
                        Expanded(child: _StatCard(label: 'Income', amount: monthIncome)),
                        const SizedBox(height: 12),
                        Expanded(child: _StatCard(label: 'Expense', amount: monthExpense)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),
            recentHeader,
            const SizedBox(height: 8),
            recentCard,
          ],
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
