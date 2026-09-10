import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../transactions/data/transaction_repository.dart';
import 'category_style_options.dart';

enum _Granularity { day, week, month, year }

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// How much a category costs (or earns) over time, at whatever zoom level
/// is useful: a bar per year, per month within a chosen year, per ~week or
/// per day within a chosen month. Everything is computed client-side from
/// one unbounded fetch of this category's transactions, so switching
/// granularity or period is instant.
class CategoryInsightsScreen extends StatefulWidget {
  final Profile profile;
  final Category category;
  final TransactionRepository transactionRepository;

  CategoryInsightsScreen({
    super.key,
    required this.profile,
    required this.category,
    TransactionRepository? transactionRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository();

  @override
  State<CategoryInsightsScreen> createState() => _CategoryInsightsScreenState();
}

class _CategoryInsightsScreenState extends State<CategoryInsightsScreen> {
  late Future<List<model.Transaction>> _dataFuture;
  _Granularity _granularity = _Granularity.month;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _dataFuture = widget.transactionRepository.listTransactions(
      widget.profile.id,
      categoryId: widget.category.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryBadge(
              icon: iconForKey(widget.category.iconKey),
              color: Color(widget.category.colorArgb),
              size: 32,
              iconSize: 16,
            ),
            const SizedBox(width: 10),
            Text(widget.category.name),
          ],
        ),
      ),
      body: MuralBackground.ambient(
        child: FutureBuilder<List<model.Transaction>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<model.Transaction> all) {
    final buckets = _bucket(all);
    final total = buckets.fold<int>(0, (sum, b) => sum + b.amountMinorUnits);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        SegmentedButton<_Granularity>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Granularity.day, label: Text('Day')),
            ButtonSegment(value: _Granularity.week, label: Text('Week')),
            ButtonSegment(value: _Granularity.month, label: Text('Month')),
            ButtonSegment(value: _Granularity.year, label: Text('Year')),
          ],
          selected: {_granularity},
          onSelectionChanged: (s) => setState(() => _granularity = s.first),
        ),
        const SizedBox(height: 16),
        if (_granularity != _Granularity.year) _periodPicker(context),
        if (_granularity != _Granularity.year) const SizedBox(height: 16),
        Text('Total', style: Theme.of(context).textTheme.bodyMedium),
        MoneyText(total, fontSize: 32),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: _granularity == _Granularity.day
                ? const EdgeInsets.fromLTRB(16, 20, 16, 16)
                : const EdgeInsets.fromLTRB(8, 20, 20, 12),
            child: _granularity == _Granularity.day
                ? _calendarHeatmap(context, buckets)
                : SizedBox(height: 220, child: _chart(context, buckets)),
          ),
        ),
      ],
    );
  }

  Widget _calendarHeatmap(BuildContext context, List<_Bucket> buckets) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(widget.category.colorArgb);
    final maxAmount = buckets.fold<int>(
      0,
      (m, b) => b.amountMinorUnits > m ? b.amountMinorUnits : m,
    );
    // Dart's DateTime.weekday is 1=Mon..7=Sun; map to a Sun-first calendar
    // grid (0=Sun..6=Sat) so it reads the way a physical calendar does.
    final firstWeekday = DateTime(_year, _month, 1).weekday % 7;
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final cells = <Widget>[
      for (final label in weekdayLabels)
        Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      for (var i = 0; i < firstWeekday; i++) const SizedBox.shrink(),
      for (final bucket in buckets)
        _HeatmapDay(
          day: int.parse(bucket.label),
          amountMinorUnits: bucket.amountMinorUnits,
          intensity: maxAmount == 0 ? 0.0 : bucket.amountMinorUnits / maxAmount,
          isToday: DateUtils.isSameDay(
            DateTime(_year, _month, int.parse(bucket.label)),
            DateTime.now(),
          ),
          color: color,
          onTap: () {
            final date = DateTime(_year, _month, int.parse(bucket.label));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                content: Text(
                  '${DateFormat.MMMd().format(date)} · '
                  '${formatMoney(bucket.amountMinorUnits)}',
                ),
              ),
            );
          },
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _periodPicker(BuildContext context) {
    final showMonth =
        _granularity == _Granularity.day || _granularity == _Granularity.week;
    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() {
            if (showMonth) {
              if (_month == 1) {
                _month = 12;
                _year--;
              } else {
                _month--;
              }
            } else {
              _year--;
            }
          }),
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        Expanded(
          child: Text(
            showMonth ? '${_monthNames[_month - 1]} $_year' : '$_year',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => setState(() {
            final now = DateTime.now();
            final atLimit = showMonth
                ? (_year == now.year && _month == now.month)
                : _year == now.year;
            if (atLimit) return;
            if (showMonth) {
              if (_month == 12) {
                _month = 1;
                _year++;
              } else {
                _month++;
              }
            } else {
              _year++;
            }
          }),
          icon: const Icon(LucideIcons.chevronRight),
        ),
      ],
    );
  }

  List<_Bucket> _bucket(List<model.Transaction> all) {
    switch (_granularity) {
      case _Granularity.year:
        final byYear = <int, int>{};
        for (final t in all) {
          byYear[t.occurredAt.year] =
              (byYear[t.occurredAt.year] ?? 0) + t.amountMinorUnits;
        }
        if (byYear.isEmpty) byYear[DateTime.now().year] = 0;
        final years = byYear.keys.toList()..sort();
        return [for (final y in years) _Bucket('$y', byYear[y]!)];

      case _Granularity.month:
        final byMonth = List<int>.filled(12, 0);
        for (final t in all) {
          if (t.occurredAt.year == _year) {
            byMonth[t.occurredAt.month - 1] += t.amountMinorUnits;
          }
        }
        return [
          for (var m = 0; m < 12; m++) _Bucket(_monthNames[m], byMonth[m]),
        ];

      case _Granularity.week:
        final daysInMonth = DateTime(_year, _month + 1, 0).day;
        final weekCount = ((daysInMonth - 1) ~/ 7) + 1;
        final byWeek = List<int>.filled(weekCount, 0);
        for (final t in all) {
          if (t.occurredAt.year == _year && t.occurredAt.month == _month) {
            final w = (t.occurredAt.day - 1) ~/ 7;
            byWeek[w] += t.amountMinorUnits;
          }
        }
        return [
          for (var w = 0; w < weekCount; w++) _Bucket('Wk ${w + 1}', byWeek[w]),
        ];

      case _Granularity.day:
        final daysInMonth = DateTime(_year, _month + 1, 0).day;
        final byDay = List<int>.filled(daysInMonth, 0);
        for (final t in all) {
          if (t.occurredAt.year == _year && t.occurredAt.month == _month) {
            byDay[t.occurredAt.day - 1] += t.amountMinorUnits;
          }
        }
        return [
          for (var d = 0; d < daysInMonth; d++) _Bucket('${d + 1}', byDay[d]),
        ];
    }
  }

  int? _currentBarIndex(List<_Bucket> buckets) {
    final now = DateTime.now();
    switch (_granularity) {
      case _Granularity.year:
        final i = buckets.indexWhere((b) => b.label == '${now.year}');
        return i == -1 ? null : i;
      case _Granularity.month:
        return _year == now.year ? now.month - 1 : null;
      case _Granularity.week:
        if (_year != now.year || _month != now.month) return null;
        return (now.day - 1) ~/ 7;
      case _Granularity.day:
        return null;
    }
  }

  Widget _chart(BuildContext context, List<_Bucket> buckets) {
    final maxY = buckets.fold<double>(
      1,
      (m, b) => b.amountMinorUnits / 100 > m ? b.amountMinorUnits / 100 : m,
    );
    final showEveryLabel = buckets.length <= 12;
    final currentIndex = _currentBarIndex(buckets);
    final nonZero = buckets.where((b) => b.amountMinorUnits != 0).toList();
    final average = nonZero.isEmpty
        ? 0.0
        : nonZero.fold<int>(0, (s, b) => s + b.amountMinorUnits) /
              nonZero.length /
              100;
    final color = Color(widget.category.colorArgb);
    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        extraLinesData: average > 0 && buckets.length > 1
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: average,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    strokeWidth: 1,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      labelResolver: (_) => 'avg',
                    ),
                  ),
                ],
              )
            : null,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${buckets[groupIndex].label}\n${formatMoney(rod.toY.round() * 100)}',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
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
                if (index < 0 || index >= buckets.length) {
                  return const SizedBox.shrink();
                }
                if (!showEveryLabel && index % 5 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[index].label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].amountMinorUnits / 100,
                  width: buckets.length > 20 ? 6 : 14,
                  borderRadius: BorderRadius.circular(4),
                  color: currentIndex == null || currentIndex == i
                      ? color
                      : color.withValues(alpha: 0.45),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Bucket {
  final String label;
  final int amountMinorUnits;

  const _Bucket(this.label, this.amountMinorUnits);
}

class _HeatmapDay extends StatelessWidget {
  final int day;
  final int amountMinorUnits;
  final double intensity;
  final bool isToday;
  final Color color;
  final VoidCallback onTap;

  const _HeatmapDay({
    required this.day,
    required this.amountMinorUnits,
    required this.intensity,
    required this.isToday,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSpend = amountMinorUnits != 0;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasSpend
              ? color.withValues(alpha: 0.15 + intensity * 0.7)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: color, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: hasSpend && intensity > 0.45
                ? Colors.white
                : scheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
