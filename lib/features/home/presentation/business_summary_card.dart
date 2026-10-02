import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../categories/presentation/category_style_options.dart';

enum _Period { month, quarter, year }

/// A proper P&L for business profiles — revenue, expenses, and net income
/// over a selectable period, plus the top expense categories — rather than
/// just a differently-seeded category list. Computed entirely from the
/// transactions Home already has in memory, so switching periods here is
/// instant and never triggers a network fetch.
class BusinessSummaryCard extends StatefulWidget {
  final List<model.Transaction> allTransactions;
  final Map<int, Category> categoriesById;

  const BusinessSummaryCard({
    super.key,
    required this.allTransactions,
    required this.categoriesById,
  });

  @override
  State<BusinessSummaryCard> createState() => _BusinessSummaryCardState();
}

class _BusinessSummaryCardState extends State<BusinessSummaryCard> {
  _Period _period = _Period.month;

  (DateTime, DateTime) _rangeFor(_Period period) {
    final now = DateTime.now();
    switch (period) {
      case _Period.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
        );
      case _Period.quarter:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(now.year, quarterStartMonth, 1),
          DateTime(now.year, quarterStartMonth + 3, 1),
        );
      case _Period.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (start, endExclusive) = _rangeFor(_period);

    var revenue = 0;
    var expense = 0;
    final spentByCategoryId = <int, int>{};
    for (final t in widget.allTransactions) {
      if (t.isTransfer) continue;
      if (t.occurredAt.isBefore(start) ||
          !t.occurredAt.isBefore(endExclusive)) {
        continue;
      }
      if (t.type == model.TransactionKind.income) {
        revenue += t.amountMinorUnits;
      } else {
        expense += t.amountMinorUnits;
        spentByCategoryId[t.categoryId!] =
            (spentByCategoryId[t.categoryId!] ?? 0) + t.amountMinorUnits;
      }
    }
    final netIncome = revenue - expense;

    final topCategories = spentByCategoryId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                      LucideIcons.briefcase,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Business summary',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SegmentedButton<_Period>(
                  segments: const [
                    ButtonSegment(value: _Period.month, label: Text('Month')),
                    ButtonSegment(
                      value: _Period.quarter,
                      label: Text('Quarter'),
                    ),
                    ButtonSegment(value: _Period.year, label: Text('Year')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Revenue',
                    amount: revenue,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Expenses',
                    amount: -expense,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Net income',
                    amount: netIncome,
                    color: netIncome >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            if (topCategories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Top expenses',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final entry in topCategories.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CategoryBadge(
                        icon: iconForKey(
                          widget.categoriesById[entry.key]?.iconKey ?? 'other',
                        ),
                        color: widget.categoriesById[entry.key] != null
                            ? Color(widget.categoriesById[entry.key]!.colorArgb)
                            : null,
                        size: 28,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.categoriesById[entry.key]?.name ??
                              'Uncategorized',
                        ),
                      ),
                      MoneyText(-entry.value, fontSize: 14),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _Figure({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        MoneyText(amount, fontSize: 17, showSign: true, color: color),
      ],
    );
  }
}
