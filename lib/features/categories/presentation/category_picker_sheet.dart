import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/widgets/category_badge.dart';
import 'category_style_options.dart';

/// Picks one category from [categories], grouped under Expense/Income headers
/// so it's obvious that choosing an income category turns the transaction into
/// income. Returns null if dismissed.
Future<Category?> showCategoryPickerSheet(
  BuildContext context, {
  required List<Category> categories,
  int? selectedId,
  String title = 'Move to category',
}) {
  final expense = categories
      .where((c) => c.type == CategoryType.expense)
      .toList();
  final income = categories
      .where((c) => c.type == CategoryType.income)
      .toList();

  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final group in [
              (label: 'Expense', items: expense),
              (label: 'Income', items: income),
            ])
              if (group.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Text(
                    group.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                for (final c in group.items)
                  ListTile(
                    leading: CategoryBadge(
                      icon: iconForKey(c.iconKey),
                      color: Color(c.colorArgb),
                      size: 36,
                      iconSize: 18,
                    ),
                    title: Text(c.name),
                    trailing: c.id == selectedId
                        ? const Icon(LucideIcons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(c),
                  ),
              ],
          ],
        ),
      ),
    ),
  );
}
