import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/wishlist_item.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
import '../data/wishlist_repository.dart';
import 'wishlist_item_form_sheet.dart';

class WishlistScreen extends StatefulWidget {
  final Profile profile;
  final WishlistRepository wishlistRepository;
  final CategoryRepository categoryRepository;

  WishlistScreen({
    super.key,
    required this.profile,
    WishlistRepository? wishlistRepository,
    CategoryRepository? categoryRepository,
  }) : wishlistRepository = wishlistRepository ?? SupabaseWishlistRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistData {
  final List<WishlistItem> items;
  final List<Category> categories;
  final Map<int, List<WishlistPart>> partsByItemId;

  const _WishlistData(this.items, this.categories, this.partsByItemId);

  List<WishlistPart> partsOf(int itemId) => partsByItemId[itemId] ?? const [];
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<_WishlistData> _dataFuture;
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dataFuture = _fetch();
    });
  }

  Future<_WishlistData> _fetch() async {
    final results = await Future.wait([
      widget.wishlistRepository.listItems(widget.profile.id),
      widget.categoryRepository.listActiveCategories(widget.profile.id),
    ]);
    final items = results[0] as List<WishlistItem>;
    final parts = await widget.wishlistRepository.listParts(
      items.map((i) => i.id).toList(),
    );
    final byItem = <int, List<WishlistPart>>{};
    for (final p in parts) {
      byItem.putIfAbsent(p.wishlistItemId, () => []).add(p);
    }
    return _WishlistData(items, results[1] as List<Category>, byItem);
  }

  Future<void> _addPart(WishlistItem item) async {
    final result = await showWishlistPartFormSheet(
      context,
      itemName: item.name,
    );
    if (result == null) return;
    try {
      await widget.wishlistRepository.createPart(
        wishlistItemId: item.id,
        name: result.name,
        estimatedPriceMinorUnits: result.estimatedPriceMinorUnits,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Adding');
      return;
    }
    if (mounted) {
      setState(() => _expandedIds.add(item.id));
      _reload();
    }
  }

  Future<void> _editItem(WishlistItem item, _WishlistData data) async {
    final result = await showWishlistItemFormSheet(
      context,
      categories: data.categories,
      existing: item,
    );
    if (result == null) return;
    try {
      await widget.wishlistRepository.updateItem(
        id: item.id,
        name: result.name,
        estimatedPriceMinorUnits: result.estimatedPriceMinorUnits,
        categoryId: result.categoryId,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Saving');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _editPart(WishlistPart part, WishlistItem item) async {
    final result = await showWishlistPartFormSheet(
      context,
      itemName: item.name,
      existing: part,
    );
    if (result == null) return;
    try {
      await widget.wishlistRepository.updatePart(
        id: part.id,
        name: result.name,
        estimatedPriceMinorUnits: result.estimatedPriceMinorUnits,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Saving');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _togglePart(WishlistPart part) async {
    try {
      await widget.wishlistRepository.setPartDone(part.id, !part.isDone);
    } catch (_) {
      if (mounted) showActionError(context, 'Updating');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _deletePart(WishlistPart part) async {
    try {
      await widget.wishlistRepository.deletePart(part.id);
    } catch (_) {
      if (mounted) showActionError(context, 'Removing');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _addItem(_WishlistData data) async {
    final result = await showWishlistItemFormSheet(
      context,
      categories: data.categories,
    );
    if (result == null) return;
    try {
      await widget.wishlistRepository.createItem(
        profileId: widget.profile.id,
        name: result.name,
        estimatedPriceMinorUnits: result.estimatedPriceMinorUnits,
        categoryId: result.categoryId,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Adding');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _toggleDone(WishlistItem item) async {
    try {
      await widget.wishlistRepository.setDone(item.id, !item.isDone);
    } catch (_) {
      if (mounted) showActionError(context, 'Updating');
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _confirmDelete(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from wishlist?'),
        content: Text('"${item.name}" will be removed from your wishlist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.wishlistRepository.deleteItem(item.id);
    } catch (_) {
      if (mounted) showActionError(context, 'Removing');
      return;
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: MuralBackground.ambient(
        child: FutureBuilder<_WishlistData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AsyncErrorView(onRetry: _reload);
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (data.items.isEmpty) {
              return _EmptyState(onAdd: () => _addItem(data));
            }
            final categoriesById = {for (final c in data.categories) c.id: c};
            final pending = data.items.where((i) => !i.isDone).length;
            // What's still outstanding: for an item broken into parts, only
            // the parts not yet bought, so the number drops as a build is
            // assembled piece by piece.
            final estimatedTotal = data.items
                .where((i) => !i.isDone)
                .fold<int>(
                  0,
                  (sum, i) =>
                      sum +
                      WishlistTotals.of(
                        i,
                        data.partsOf(i.id),
                      ).remainingMinorUnits,
                );
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: data.items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      estimatedTotal > 0
                          ? '$pending planned · ~${formatMoney(estimatedTotal)} estimated'
                          : '$pending planned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final item = data.items[index - 1];
                return _WishlistTile(
                      item: item,
                      category: categoriesById[item.categoryId],
                      parts: data.partsOf(item.id),
                      expanded: _expandedIds.contains(item.id),
                      onToggleExpanded: () => setState(() {
                        if (!_expandedIds.remove(item.id)) {
                          _expandedIds.add(item.id);
                        }
                      }),
                      onToggleDone: () => _toggleDone(item),
                      onEdit: () => _editItem(item, data),
                      onDelete: () => _confirmDelete(item),
                      onAddPart: () => _addPart(item),
                      onTogglePart: _togglePart,
                      onEditPart: (part) => _editPart(part, item),
                      onDeletePart: _deletePart,
                    )
                    .animate()
                    .fadeIn(delay: (index * 30).ms, duration: 200.ms)
                    .slideX(begin: 0.03, end: 0);
              },
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<_WishlistData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return FloatingActionButton(
            onPressed: data == null ? null : () => _addItem(data),
            child: const Icon(LucideIcons.plus),
          );
        },
      ),
    );
  }
}

/// One wishlist row. An item with parts shows its rolled-up total and how far
/// along it is, and expands to let each piece be priced and ticked off.
class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  final Category? category;
  final List<WishlistPart> parts;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddPart;
  final ValueChanged<WishlistPart> onTogglePart;
  final ValueChanged<WishlistPart> onEditPart;
  final ValueChanged<WishlistPart> onDeletePart;

  const _WishlistTile({
    required this.item,
    required this.category,
    required this.parts,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
    required this.onAddPart,
    required this.onTogglePart,
    required this.onEditPart,
    required this.onDeletePart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = WishlistTotals.of(item, parts);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(expanded ? 0 : 16),
              ),
              onTap: totals.hasParts ? onToggleExpanded : onToggleDone,
              onLongPress: onDelete,
              child: Opacity(
                opacity: item.isDone ? 0.5 : 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleDone,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: _Checkbox(checked: item.isDone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            if (category != null || totals.hasParts) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (category != null) ...[
                                    Icon(
                                      iconForKey(category!.iconKey),
                                      size: 12,
                                      color: Color(category!.colorArgb),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      category!.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                  if (category != null && totals.hasParts)
                                    Text(
                                      '  ·  ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  if (totals.hasParts)
                                    Text(
                                      '${totals.acquiredPartCount} of '
                                      '${totals.partCount} items',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: scheme.primary),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (totals.budgetMinorUnits > 0 ||
                          totals.partsTotalMinorUnits > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // The item's own budget stays the headline figure
                            // once it has parts, so going over it is visible
                            // rather than silently becoming the new total.
                            MoneyText(
                              totals.hasBudget
                                  ? totals.budgetMinorUnits
                                  : totals.partsTotalMinorUnits,
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            // Only the overrun: when under budget the bar's
                            // own caption below already says the same thing.
                            if (totals.isOverBudget)
                              Text(
                                '${formatMoney(totals.overByMinorUnits)} over',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                      if (totals.hasParts)
                        Icon(
                          expanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreVertical, size: 17),
                        tooltip: 'More',
                        onSelected: (v) {
                          if (v == 'edit') onEdit();
                          if (v == 'add') onAddPart();
                          if (v == 'delete') onDelete();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'add',
                            child: Text(
                              totals.hasParts ? 'Add an item' : 'Break it down',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (totals.hasParts && totals.hasBudget)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _BudgetBar(totals: totals),
              ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 8),
                child: Column(
                  children: [
                    Divider(color: scheme.outlineVariant, height: 1),
                    for (final part in parts)
                      _PartRow(
                        part: part,
                        onToggle: () => onTogglePart(part),
                        onEdit: () => onEditPart(part),
                        onDelete: () => onDeletePart(part),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// How far the parts have eaten into the item's budget. Fills with the
/// accent up to the budget, then switches wholly to the error colour once
/// they overrun it — a bar that simply caps at full would hide the overrun,
/// which is the one thing worth seeing.
class _BudgetBar extends StatelessWidget {
  final WishlistTotals totals;

  const _BudgetBar({required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = totals.partsTotalMinorUnits / totals.budgetMinorUnits;
    final over = totals.isOverBudget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              over ? scheme.error : scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          over
              ? '${formatMoney(totals.partsTotalMinorUnits)} listed against a '
                    '${formatMoney(totals.budgetMinorUnits)} budget'
              : '${formatMoney(totals.partsTotalMinorUnits)} of '
                    '${formatMoney(totals.budgetMinorUnits)} planned',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: over ? scheme.error : scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PartRow extends StatelessWidget {
  final WishlistPart part;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PartRow({
    required this.part,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: part.isDone ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              _Checkbox(checked: part.isDone, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  part.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: part.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (part.estimatedPriceMinorUnits != null)
                MoneyText(
                  part.estimatedPriceMinorUnits!,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 15),
                tooltip: 'More',
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final double size;

  const _Checkbox({required this.checked, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: checked ? scheme.primary : scheme.outline,
          width: 1.6,
        ),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: size * 0.64, color: scheme.onPrimary)
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.listChecks,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing on your wishlist yet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep a running list of things you mean to buy, so you don\'t forget them next time you\'re out.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add something'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
