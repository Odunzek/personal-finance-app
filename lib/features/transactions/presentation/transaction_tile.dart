import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../categories/presentation/category_style_options.dart';

class TransactionTile extends StatelessWidget {
  final model.Transaction transaction;
  final Category? category;
  final Map<int, Account>? accountsById;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.accountsById,
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (transaction.isTransfer) {
      final toName =
          accountsById?[transaction.transferAccountId]?.name ?? 'account';
      final fromName = accountsById?[transaction.accountId]?.name ?? 'account';
      return ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: CategoryBadge(
          icon: LucideIcons.arrowRightLeft,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 40,
          iconSize: 18,
        ),
        title: Text(
          transaction.note?.isNotEmpty == true ? transaction.note! : 'Transfer',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            '$fromName → $toName',
            if (showDate) DateFormat.MMMd().format(transaction.occurredAt),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: MoneyText(transaction.amountMinorUnits),
      );
    }

    final isIncome = transaction.type == model.TransactionKind.income;
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CategoryBadge(
        icon: iconForKey(category?.iconKey ?? 'other'),
        color: category != null ? Color(category!.colorArgb) : null,
        size: 40,
        iconSize: 18,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              transaction.note?.isNotEmpty == true
                  ? transaction.note!
                  : (category?.name ?? 'Uncategorized'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (transaction.isRecurring) ...[
            const SizedBox(width: 6),
            Icon(
              LucideIcons.repeat,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          category?.name ?? 'Uncategorized',
          if (showDate) DateFormat.MMMd().format(transaction.occurredAt),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: MoneyText(
        isIncome ? transaction.amountMinorUnits : -transaction.amountMinorUnits,
        showSign: true,
        color: color,
      ),
    );
  }
}
