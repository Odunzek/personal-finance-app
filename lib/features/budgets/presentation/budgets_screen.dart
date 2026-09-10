import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/budget.dart';
import '../../../core/models/category.dart';
import '../../../core/models/month_range.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/budget_ring.dart';
import '../../../core/widgets/money_text.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/budget_repository.dart';
import 'budget_edit_sheet.dart';
import 'savings_target_edit_sheet.dart';
import 'yearly_savings_goal_card.dart';

class BudgetsScreen extends StatefulWidget {
  final Profile profile;
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;

  BudgetsScreen({
    super.key,
    required this.profile,
    BudgetRepository? budgetRepository,
    CategoryRepository? categoryRepository,
    TransactionRepository? transactionRepository,
  }) : budgetRepository = budgetRepository ?? SupabaseBudgetRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository();

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsData {
  final List<Category> categories;
  final List<Budget> budgets;
  final SavingsTarget? savingsTarget;
  final int monthIncome;
  final int monthExpense;
  final Map<int, int> spentByCategoryId;

  const _BudgetsData({
    required this.categories,
    required this.budgets,
    required this.savingsTarget,
    required this.monthIncome,
    required this.monthExpense,
    required this.spentByCategoryId,
  });
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Future<_BudgetsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = _fetch();
  }

  Future<void> _reload() async {
    setState(_load);
    await _dataFuture;
  }

  Future<_BudgetsData> _fetch() async {
    final month = MonthRange.current();
    final results = await Future.wait([
      widget.categoryRepository.listActiveCategories(widget.profile.id),
      widget.budgetRepository.listBudgetsForMonth(
        widget.profile.id,
        month.start,
      ),
      widget.budgetRepository.getSavingsTarget(widget.profile.id, month.start),
      widget.transactionRepository.listTransactions(
        widget.profile.id,
        from: month.start,
        to: month.endExclusive,
      ),
    ]);
    final categories = results[0] as List<Category>;
    final budgets = results[1] as List<Budget>;
    final savingsTarget = results[2] as SavingsTarget?;
    final transactions = results[3] as List<model.Transaction>;

    var income = 0;
    var expense = 0;
    final spentByCategoryId = <int, int>{};
    for (final t in transactions) {
      if (t.isTransfer) continue;
      if (t.type == model.TransactionKind.income) {
        income += t.amountMinorUnits;
      } else {
        expense += t.amountMinorUnits;
        spentByCategoryId[t.categoryId!] =
            (spentByCategoryId[t.categoryId!] ?? 0) + t.amountMinorUnits;
      }
    }

    return _BudgetsData(
      categories: categories,
      budgets: budgets,
      savingsTarget: savingsTarget,
      monthIncome: income,
      monthExpense: expense,
      spentByCategoryId: spentByCategoryId,
    );
  }

  Future<void> _editSavingsTarget(_BudgetsData data) async {
    final result = await showSavingsTargetEditSheet(
      context,
      initialTargetMinorUnits: data.savingsTarget?.targetMinorUnits ?? 0,
      savedSoFarMinorUnits: data.monthIncome - data.monthExpense,
    );
    if (result == null) return;
    await widget.budgetRepository.upsertSavingsTarget(
      profileId: widget.profile.id,
      month: MonthRange.current().start,
      targetMinorUnits: result,
    );
    _reload();
  }

  Future<void> _editBudget(
    _BudgetsData data,
    Category category,
    Budget? existing,
  ) async {
    final result = await showBudgetEditSheet(
      context,
      category: category,
      initialLimitMinorUnits: existing?.limitMinorUnits ?? 10000,
      spentMinorUnits: data.spentByCategoryId[category.id] ?? 0,
      hasBudget: existing != null,
    );
    if (result == null) return;
    if (result.remove && existing != null) {
      await widget.budgetRepository.deleteBudget(existing.id);
    } else {
      await widget.budgetRepository.upsertBudget(
        profileId: widget.profile.id,
        categoryId: category.id,
        month: MonthRange.current().start,
        limitMinorUnits: result.limitMinorUnits,
      );
    }
    _reload();
  }

  Future<void> _pickCategoryToBudget(_BudgetsData data) async {
    final budgetedIds = data.budgets.map((b) => b.categoryId).toSet();
    final candidates = data.categories
        .where(
          (c) => c.type == CategoryType.expense && !budgetedIds.contains(c.id),
        )
        .toList();
    if (candidates.isEmpty) return;
    final picked = await showModalBottomSheet<Category>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: candidates
              .map(
                (c) => ListTile(
                  title: Text(c.name),
                  onTap: () => Navigator.of(context).pop(c),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) _editBudget(data, picked, null);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<_BudgetsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final month = MonthRange.current();
          final categoriesById = {for (final c in data.categories) c.id: c};

          final totalLimit = data.budgets.fold<int>(
            0,
            (sum, b) => sum + b.limitMinorUnits,
          );
          final totalSpent = data.budgets.fold<int>(
            0,
            (sum, b) => sum + (data.spentByCategoryId[b.categoryId] ?? 0),
          );
          final savedSoFar = data.monthIncome - data.monthExpense;
          final savingsRatio =
              data.savingsTarget == null ||
                  data.savingsTarget!.targetMinorUnits == 0
              ? 0.0
              : (savedSoFar / data.savingsTarget!.targetMinorUnits)
                    .clamp(0, 1)
                    .toDouble();

          final savingsCard = Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () => _editSavingsTarget(data),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    BudgetRing(
                      ratio: savingsRatio,
                      color: Theme.of(context).colorScheme.primary,
                      size: 64,
                      strokeWidth: 7,
                      center: Text(
                        '${(savingsRatio * 100).round()}%',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.piggyBank,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Savings target',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (data.savingsTarget == null)
                            const Text('Tap to set a monthly savings goal')
                          else
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                MoneyText(savedSoFar, fontSize: 15),
                                const Text(' of your '),
                                MoneyText(
                                  data.savingsTarget!.targetMinorUnits,
                                  fontSize: 15,
                                ),
                                const Text(' goal'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);

          final leftToSpendCard =
              Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.wallet,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Left to spend',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          MoneyText(
                            (totalLimit - totalSpent).clamp(0, 1 << 62),
                            fontSize: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 300.ms)
                  .slideY(begin: 0.05, end: 0);

          Widget budgetCard(int budgetIndex, Budget b) {
            final category = categoriesById[b.categoryId];
            if (category == null) return const SizedBox.shrink();
            final spent = data.spentByCategoryId[b.categoryId] ?? 0;
            final ratio = b.limitMinorUnits == 0
                ? 0.0
                : (spent / b.limitMinorUnits).clamp(0, 1.5);
            final color = ratio >= 1
                ? Theme.of(context).colorScheme.error
                : ratio >= 0.7
                ? const Color(0xFFC98A16)
                : Theme.of(context).colorScheme.primary;
            return Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _editBudget(data, category, b),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          BudgetRing(
                            ratio: ratio.toDouble(),
                            color: color,
                            size: 44,
                            strokeWidth: 5,
                            center: Text(
                              '${(ratio * 100).round()}%',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    MoneyText(spent, fontSize: 13),
                                    Text(
                                      ' of ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    MoneyText(b.limitMinorUnits, fontSize: 13),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: (budgetIndex * 60).ms, duration: 250.ms)
                .slideY(begin: 0.05, end: 0);
          }

          final addBudgetTile = InkWell(
            onTap: () => _pickCategoryToBudget(data),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, size: 18),
                  SizedBox(width: 8),
                  Text('Add a budget'),
                ],
              ),
            ),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= kTabletBreakpoint;

              final topRow = isTablet
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: savingsCard),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: leftToSpendCard),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        savingsCard,
                        const SizedBox(height: 12),
                        leftToSpendCard,
                      ],
                    );

              final budgetSection = data.budgets.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No budgets set yet. Tap below to add one.'),
                    )
                  : isTablet
                  ? Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: data.budgets.asMap().entries.map((indexed) {
                        final width = (constraints.maxWidth - 40 - 12) / 2;
                        return SizedBox(
                          width: width,
                          child: budgetCard(indexed.key, indexed.value),
                        );
                      }).toList(),
                    )
                  : Column(
                      children: data.budgets
                          .asMap()
                          .entries
                          .map(
                            (indexed) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: budgetCard(indexed.key, indexed.value),
                            ),
                          )
                          .toList(),
                    );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budgets',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        month.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  topRow,
                  const SizedBox(height: 20),
                  budgetSection,
                  const SizedBox(height: 8),
                  addBudgetTile,
                  const SizedBox(height: 24),
                  YearlySavingsGoalCard(
                    profile: widget.profile,
                    budgetRepository: widget.budgetRepository,
                    transactionRepository: widget.transactionRepository,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
