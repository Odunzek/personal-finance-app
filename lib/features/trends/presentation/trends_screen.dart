import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/month_range.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';

class TrendsScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  TrendsScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsData {
  final List<double> monthlyExpense;
  final List<String> monthLabels;
  final Map<Category, int> spendByCategory;

  const _TrendsData(this.monthlyExpense, this.monthLabels, this.spendByCategory);
}

class _TrendsScreenState extends State<TrendsScreen> {
  late Future<_TrendsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetch();
  }

  Future<_TrendsData> _fetch() async {
    final months = <MonthRange>[];
    var cursor = MonthRange.current();
    for (var i = 0; i < 6; i++) {
      months.insert(0, cursor);
      cursor = cursor.previous();
    }
    final earliest = months.first.start;
    final latest = months.last.endExclusive;

    final results = await Future.wait([
      widget.transactionRepository.listTransactions(
        widget.profile.id,
        from: earliest,
        to: latest,
      ),
      widget.categoryRepository.listActiveCategories(widget.profile.id),
    ]);
    final transactions = results[0] as List<model.Transaction>;
    final categories = {
      for (final c in results[1] as List<Category>) c.id: c,
    };

    final monthlyExpense = List<double>.filled(6, 0);
    final currentMonthSpend = <int, int>{};
    final currentMonth = MonthRange.current();

    for (final t in transactions) {
      if (t.type != CategoryType.expense) continue;
      for (var i = 0; i < months.length; i++) {
        if (!t.occurredAt.isBefore(months[i].start) &&
            t.occurredAt.isBefore(months[i].endExclusive)) {
          monthlyExpense[i] += t.amountMinorUnits / 100;
          break;
        }
      }
      if (!t.occurredAt.isBefore(currentMonth.start) &&
          t.occurredAt.isBefore(currentMonth.endExclusive)) {
        currentMonthSpend[t.categoryId] =
            (currentMonthSpend[t.categoryId] ?? 0) + t.amountMinorUnits;
      }
    }

    final spendByCategory = <Category, int>{
      for (final entry in currentMonthSpend.entries)
        if (categories[entry.key] != null) categories[entry.key]!: entry.value,
    };
    final sortedSpend = Map.fromEntries(
      spendByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return _TrendsData(
      monthlyExpense,
      months.map((m) => m.label).toList(),
      sortedSpend,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrendsData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final maxY = data.monthlyExpense.fold<double>(
          1,
          (m, v) => v > m ? v : m,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Text('Trends', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.trendingUp,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text('Spending, last 6 months', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: BarChart(
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                        BarChartData(
                          maxY: maxY * 1.2,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    data.monthLabels[value.toInt()],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < data.monthlyExpense.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.monthlyExpense[i],
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                    color: i == data.monthlyExpense.length - 1
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.chartPie,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text('Where it went this month', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data.spendByCategory.isEmpty)
                      const Text('No spending recorded this month yet.')
                    else
                      ...data.spendByCategory.entries.toList().asMap().entries.map(
                        (indexed) {
                          final entry = indexed.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(entry.key.colorArgb),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(entry.key.name)),
                                Text(formatMoney(entry.value)),
                              ],
                            ),
                          ).animate().fadeIn(
                            delay: (indexed.key * 50).ms,
                            duration: 200.ms,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
          ],
        );
      },
    );
  }
}

