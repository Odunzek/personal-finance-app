import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/account.dart';
import '../../../core/models/account_balance.dart';
import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/month_range.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/models/recurring_rule.dart';
import '../../accounts/data/account_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_insights_screen.dart';
import '../../categories/presentation/category_style_options.dart';
import '../../recurring/data/recurring_rule_repository.dart';
import '../../transactions/data/transaction_repository.dart';

class TrendsScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final RecurringRuleRepository recurringRuleRepository;

  TrendsScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
    RecurringRuleRepository? recurringRuleRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository(),
       recurringRuleRepository =
           recurringRuleRepository ?? SupabaseRecurringRuleRepository();

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsData {
  final List<double> monthlyExpense;
  final List<double> monthlyIncome;
  final List<String> monthLabels;
  final List<Map<Category, int>> spendByCategoryPerMonth;
  final List<double> netWorthByMonthEnd;
  final List<double> debtByMonthEnd;
  final int todayNetWorthMinorUnits;
  final List<RecurringRule> activeRules;

  const _TrendsData(
    this.monthlyExpense,
    this.monthlyIncome,
    this.monthLabels,
    this.spendByCategoryPerMonth,
    this.netWorthByMonthEnd,
    this.debtByMonthEnd,
    this.todayNetWorthMinorUnits,
    this.activeRules,
  );
}

class _TrendsScreenState extends State<TrendsScreen> {
  late Future<_TrendsData> _dataFuture;
  int _selectedMonthIndex = 5;
  int _forecastDays = 30;

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
      // Net worth at each checkpoint depends on every transaction since the
      // account was opened, not just the last 6 months, so this is fetched
      // unbounded rather than reusing the windowed query above.
      widget.transactionRepository.listTransactions(widget.profile.id),
      widget.accountRepository.listActiveAccounts(widget.profile.id),
      widget.recurringRuleRepository.listActiveRules(widget.profile.id),
    ]);
    final transactions = results[0] as List<model.Transaction>;
    final categories = {for (final c in results[1] as List<Category>) c.id: c};
    final allTransactions = results[2] as List<model.Transaction>;
    final accounts = results[3] as List<Account>;
    final activeRules = results[4] as List<RecurringRule>;

    var todayNetWorth = 0;
    for (final account in accounts) {
      todayNetWorth += computeAccountBalance(account, allTransactions);
    }

    final netWorthByMonthEnd = <double>[];
    final debtByMonthEnd = <double>[];
    for (final month in months) {
      final upToMonthEnd = allTransactions
          .where((t) => t.occurredAt.isBefore(month.endExclusive))
          .toList();
      var netWorth = 0;
      var debt = 0;
      for (final account in accounts) {
        final balance = computeAccountBalance(account, upToMonthEnd);
        netWorth += balance;
        if (account.type == AccountType.liability && balance < 0) {
          debt += -balance;
        }
      }
      netWorthByMonthEnd.add(netWorth / 100);
      debtByMonthEnd.add(debt / 100);
    }

    final monthlyExpense = List<double>.filled(6, 0);
    final monthlyIncome = List<double>.filled(6, 0);
    final spendByMonth = List.generate(6, (_) => <int, int>{});

    for (final t in transactions) {
      if (t.isTransfer) continue;
      for (var i = 0; i < months.length; i++) {
        if (!t.occurredAt.isBefore(months[i].start) &&
            t.occurredAt.isBefore(months[i].endExclusive)) {
          if (t.type == model.TransactionKind.expense) {
            monthlyExpense[i] += t.amountMinorUnits / 100;
            spendByMonth[i][t.categoryId!] =
                (spendByMonth[i][t.categoryId!] ?? 0) + t.amountMinorUnits;
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
      netWorthByMonthEnd,
      debtByMonthEnd,
      todayNetWorth,
      activeRules,
    );
  }

  /// Projects net worth forward [days] from today using every active
  /// recurring rule's known future occurrences — a plain forecast built
  /// entirely from already-scheduled money, not a prediction of new
  /// spending. Transfers are skipped since they move balance between the
  /// profile's own accounts and never change its total.
  List<double> _forecastSeries(_TrendsData data, int days) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final horizon = todayDateOnly.add(Duration(days: days));

    final deltasByDay = <DateTime, int>{};
    for (final rule in data.activeRules) {
      if (rule.isTransfer) continue;
      var due = rule.nextDueDate;
      var iterations = 0;
      while (!due.isAfter(horizon) && iterations < 500) {
        if (!due.isBefore(todayDateOnly)) {
          final dayKey = DateTime(due.year, due.month, due.day);
          final signed = rule.type == model.TransactionKind.income
              ? rule.amountMinorUnits
              : -rule.amountMinorUnits;
          deltasByDay[dayKey] = (deltasByDay[dayKey] ?? 0) + signed;
        }
        due = rule.frequency.next(due);
        iterations++;
      }
    }

    final series = <double>[];
    var running = data.todayNetWorthMinorUnits;
    for (var i = 0; i <= days; i++) {
      final day = todayDateOnly.add(Duration(days: i));
      if (i > 0) running += deltasByDay[day] ?? 0;
      series.add(running / 100);
    }
    return series;
  }

  Widget _buildForecastCard(BuildContext context, _TrendsData data) {
    final series = _forecastSeries(data, _forecastDays);
    final start = series.first;
    final end = series.last;
    final rising = end >= start;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cash flow forecast',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 30, label: Text('30 days')),
                    ButtonSegment(value: 90, label: Text('90 days')),
                  ],
                  selected: {_forecastDays},
                  onSelectionChanged: (s) =>
                      setState(() => _forecastDays = s.first),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Based on today\'s balance plus every scheduled recurring '
              'rule — not a prediction of new spending.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItems: (spots) => spots.map((s) {
                        final day = DateTime.now().add(
                          Duration(days: s.x.round()),
                        );
                        return LineTooltipItem(
                          '${DateFormat.MMMd().format(day)}\n'
                          '${formatMoney((s.y * 100).round())}',
                          TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
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
                        interval: (_forecastDays / 3).roundToDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= series.length) {
                            return const SizedBox.shrink();
                          }
                          final day = DateTime.now().add(Duration(days: index));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.MMMd().format(day),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (series.length - 1).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < series.length; i++)
                          FlSpot(i.toDouble(), series[i]),
                      ],
                      isCurved: true,
                      color: rising
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color:
                            (rising
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error)
                                .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        final maxY = [
          ...data.monthlyExpense,
          ...data.monthlyIncome,
        ].fold<double>(1, (m, v) => v > m ? v : m);
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                    _LegendDot(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'Income',
                    ),
                    _LegendDot(
                      color: Theme.of(context).colorScheme.error,
                      label: 'Expense',
                    ),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onInverseSurface,
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
                              final selected =
                                  value.toInt() == _selectedMonthIndex;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data.monthLabels[value.toInt()],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : null,
                                        color: selected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
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
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(
                                      alpha: i == _selectedMonthIndex ? 1 : 0.4,
                                    ),
                                    Theme.of(context).colorScheme.primary
                                        .withValues(
                                          alpha: i == _selectedMonthIndex
                                              ? 0.55
                                              : 0.2,
                                        ),
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
                                    Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(
                                      alpha: i == _selectedMonthIndex ? 1 : 0.4,
                                    ),
                                    Theme.of(context).colorScheme.error
                                        .withValues(
                                          alpha: i == _selectedMonthIndex
                                              ? 0.55
                                              : 0.2,
                                        ),
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
                  ...breakdown.entries.toList().asMap().entries.map((indexed) {
                    final entry = indexed.value;
                    final share = breakdownTotal == 0
                        ? 0.0
                        : entry.value / breakdownTotal;
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryInsightsScreen(
                            profile: widget.profile,
                            category: entry.key,
                          ),
                        ),
                      ),
                      child: Padding(
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
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
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
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                      value: value,
                                      minHeight: 6,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      color: Color(entry.key.colorArgb),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: (indexed.key * 50).ms,
                      duration: 200.ms,
                    );
                  }),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);

        final hasDebt = data.debtByMonthEnd.any((d) => d > 0);
        final netWorthCard =
            Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.lineChart,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Net worth, last 6 months',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            _LegendDot(
                              color: Theme.of(context).colorScheme.primary,
                              label: 'Net worth',
                            ),
                            if (hasDebt)
                              _LegendDot(
                                color: Theme.of(context).colorScheme.error,
                                label: 'Debt owed',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            duration: 700.ms,
                            curve: Curves.easeOutCubic,
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) =>
                                      Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                  getTooltipItems: (spots) => spots.map((s) {
                                    final label = s.barIndex == 0
                                        ? 'Net worth'
                                        : 'Debt owed';
                                    return LineTooltipItem(
                                      '$label\n${formatMoney((s.y * 100).round())}',
                                      TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onInverseSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList(),
                                ),
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
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.round();
                                      if (index < 0 ||
                                          index >= data.monthLabels.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          data.monthLabels[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              minX: 0,
                              maxX: (data.monthLabels.length - 1).toDouble(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (
                                      var i = 0;
                                      i < data.netWorthByMonthEnd.length;
                                      i++
                                    )
                                      FlSpot(
                                        i.toDouble(),
                                        data.netWorthByMonthEnd[i],
                                      ),
                                  ],
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                if (hasDebt)
                                  LineChartBarData(
                                    spots: [
                                      for (
                                        var i = 0;
                                        i < data.debtByMonthEnd.length;
                                        i++
                                      )
                                        FlSpot(
                                          i.toDouble(),
                                          data.debtByMonthEnd[i],
                                        ),
                                    ],
                                    isCurved: true,
                                    color: Theme.of(context).colorScheme.error,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 140.ms, duration: 300.ms)
                .slideY(begin: 0.05, end: 0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= kTabletBreakpoint;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                Text(
                  'Trends',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
                const SizedBox(height: 12),
                netWorthCard,
                const SizedBox(height: 12),
                _buildForecastCard(context, data),
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
