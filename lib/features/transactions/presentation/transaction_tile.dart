import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/transaction.dart' as model;
import '../../categories/presentation/category_style_options.dart';

class TransactionTile extends StatelessWidget {
  final model.Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == CategoryType.income;
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category != null ? Color(category!.colorArgb) : Colors.grey,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          iconForKey(category?.iconKey ?? 'other'),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        transaction.note?.isNotEmpty == true
            ? transaction.note!
            : (category?.name ?? 'Uncategorized'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          category?.name ?? 'Uncategorized',
          if (showDate) DateFormat.MMMd().format(transaction.occurredAt),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatMoney(
          isIncome ? transaction.amountMinorUnits : -transaction.amountMinorUnits,
          showSign: true,
        ),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }
}
