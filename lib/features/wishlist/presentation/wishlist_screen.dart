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

  const _WishlistData(this.items, this.categories);
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<_WishlistData> _dataFuture;

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
    return _WishlistData(
      results[0] as List<WishlistItem>,
      results[1] as List<Category>,
    );
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
        title: const Text('Remove this item?'),
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
            final estimatedTotal = data.items
                .where((i) => !i.isDone)
                .fold<int>(
                  0,
                  (sum, i) => sum + (i.estimatedPriceMinorUnits ?? 0),
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
                final category = categoriesById[item.categoryId];
                return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _toggleDone(item),
                          onLongPress: () => _confirmDelete(item),
                          child: Opacity(
                            opacity: item.isDone ? 0.5 : 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _Checkbox(checked: item.isDone),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                decoration: item.isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        if (category != null) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                iconForKey(category.iconKey),
                                                size: 12,
                                                color: Color(
                                                  category.colorArgb,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                category.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (item.estimatedPriceMinorUnits != null)
                                    MoneyText(
                                      item.estimatedPriceMinorUnits!,
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(item),
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 17,
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _Checkbox extends StatelessWidget {
  final bool checked;

  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: checked ? scheme.primary : scheme.outline,
          width: 1.6,
        ),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: 14, color: scheme.onPrimary)
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
