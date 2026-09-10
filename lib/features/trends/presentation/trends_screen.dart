import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/month_range.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
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
  final List<double> monthlyIncome;
  final List<String> monthLabels;
  final List<Map<Category, int>> spendByCategoryPerMonth;

  const _TrendsData(
    this.monthlyExpense,
    this.monthlyIncome,
    this.monthLabels,
    this.spendByCategoryPerMonth,
  );
}

class _TrendsScreenState extends State<TrendsScreen> {
  late Future<_TrendsData> _dataFuture;
  int _selectedMonthIndex = 5;

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
    final monthlyIncome = List<double>.filled(6, 0);
    final spendByMonth = List.generate(6, (_) => <int, int>{});

    for (final t in transactions) {
      for (var i = 0; i < months.length; i++) {
        if (!t.occurredAt.isBefore(months[i].start) &&
            t.occurredAt.isBefore(months[i].endExclusive)) {
          if (t.type == CategoryType.expense) {
            monthlyExpense[i] += t.amountMinorUnits / 100;
            spendByMonth[i][t.categoryId] =
                (spendByMonth[i][t.categoryId] ?? 0) + t.amountMinorUnits;
          } else {
            monthlyIncome[i] += t.amountMinorUnits / 100;
          }
          break;
        }
      }
    }

    final spendByCategoryPerMonth = [
      for (final monthSpend in spendByMonth)
        Map.fromEntries(
          [
            for (final entry in monthSpend.entries)
              if (categories[entry.key] != null)
                MapEntry(categories[entry.key]!, entry.value),
          ]..sort((a, b) => b.value.compareTo(a.value)),
        ),
    ];

    return _TrendsData(
      monthlyExpense,
      monthlyIncome,
      months.map((m) => m.label).toList(),
      spendByCategoryPerMonth,
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
        final maxY = [...data.monthlyExpense, ...data.monthlyIncome].fold<double>(
          1,
          (m, v) => v > m ? v : m,
        );
        final breakdown = data.spendByCategoryPerMonth[_selectedMonthIndex];
        final breakdownTotal = breakdown.values.fold<int>(0, (a, b) => a + b);
        final isCurrentMonth = _selectedMonthIndex == 5;

        final chartCard = Card(
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
                    Text(
                      'Income vs expense, last 6 months',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    _LegendDot(color: Theme.of(context).colorScheme.primary, label: 'Income'),
                    const SizedBox(width: 10),
                    _LegendDot(color: Theme.of(context).colorScheme.error, label: 'Expense'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a month to see its breakdown below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                      height: 160,
                      child: BarChart(
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                        BarChartData(
                          maxY: maxY * 1.2,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) =>
                                  Theme.of(context).colorScheme.inverseSurface,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final label = rodIndex == 0 ? 'Income' : 'Expense';
                                return BarTooltipItem(
                                  '$label\n${formatMoney((rod.toY * 100).round())}',
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) return;
                              final index = response?.spot?.touchedBarGroupIndex;
                              if (index == null) return;
                              setState(() => _selectedMonthIndex = index);
                            },
                          ),
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
                                getTitlesWidget: (value, meta) {
                                  final selected = value.toInt() == _selectedMonthIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      data.monthLabels[value.toInt()],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: selected ? FontWeight.w700 : null,
                                        color: selected
                                            ? Theme.of(context).colorScheme.onSurface
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < data.monthlyExpense.length; i++)
                              BarChartGroupData(
                                x: i,
                                barsSpace: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.monthlyIncome[i],
                                    width: 11,
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Theme.of(context).colorScheme.primary
                                            .withValues(alpha: i == _selectedMonthIndex ? 1 : 0.4),
                                        Theme.of(context).colorScheme.primary
                                            .withValues(alpha: i == _selectedMonthIndex ? 0.55 : 0.2),
                                      ],
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: data.monthlyExpense[i],
                                    width: 11,
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Theme.of(context).colorScheme.error
                                            .withValues(alpha: i == _selectedMonthIndex ? 1 : 0.4),
                                        Theme.of(context).colorScheme.error
                                            .withValues(alpha: i == _selectedMonthIndex ? 0.55 : 0.2),
                                      ],
                                    ),
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
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);

        final breakdownCard = Card(
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
                    Text(
                      isCurrentMonth
                          ? 'Where it went this month'
                          : 'Where it went in ${data.monthLabels[_selectedMonthIndex]}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (breakdown.isEmpty)
                  const Text('No spending recorded that month.')
                else
                  ...breakdown.entries.toList().asMap().entries.map(
                    (indexed) {
                      final entry = indexed.value;
                      final share = breakdownTotal == 0 ? 0.0 : entry.value / breakdownTotal;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CategoryBadge(
                                  icon: iconForKey(entry.key.iconKey),
                                  color: Color(entry.key.colorArgb),
                                  size: 28,
                                  iconSize: 14,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(entry.key.name)),
                                Text(
                                  '${(share * 100).round()}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                MoneyText(entry.value, fontSize: 14),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: share),
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surfaceContainerHighest,
                                  color: Color(entry.key.colorArgb),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (indexed.key * 50).ms, duration: 200.ms);
                    },
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= kTabletBreakpoint;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                Text('Trends', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (isTablet)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: chartCard),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: breakdownCard),
                      ],
                    ),
                  )
                else ...[
                  chartCard,
                  const SizedBox(height: 12),
                  breakdownCard,
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
