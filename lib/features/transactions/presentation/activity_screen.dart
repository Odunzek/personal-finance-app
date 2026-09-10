import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../categories/data/category_repository.dart';
import '../data/transaction_repository.dart';
import 'transaction_detail_screen.dart';
import 'transaction_tile.dart';

class ActivityScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  ActivityScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int? _filterCategoryId;
  late Future<_ActivityData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = _fetch();
  }

  Future<_ActivityData> _fetch() async {
    final results = await Future.wait([
      widget.transactionRepository.listTransactions(
        widget.profile.id,
        categoryId: _filterCategoryId,
      ),
      widget.categoryRepository.listActiveCategories(widget.profile.id),
    ]);
    return _ActivityData(
      results[0] as List<model.Transaction>,
      {
        for (final c in results[1] as List<Category>) c.id: c,
      },
    );
  }

  Future<void> _reload() async {
    setState(_load);
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<_ActivityData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${data.transactions.length} items',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filterCategoryId == null,
                              onTap: () =>
                                  setState(() {
                                    _filterCategoryId = null;
                                    _load();
                                  }),
                            ),
                            ...data.categoriesById.values.map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _FilterChip(
                                  label: c.name,
                                  selected: _filterCategoryId == c.id,
                                  onTap: () => setState(() {
                                    _filterCategoryId = c.id;
                                    _load();
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.folderOpen,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Nothing here',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text('No transactions match this filter.'),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                  ),
                )
              else
                ..._buildGroupedSlivers(context, data),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedSlivers(BuildContext context, _ActivityData data) {
    final groups = <String, List<model.Transaction>>{};
    for (final t in data.transactions) {
      final key = DateFormat.yMMMd().format(t.occurredAt);
      groups.putIfAbsent(key, () => []).add(t);
    }
    var animIndex = 0;
    return groups.entries.map((entry) {
      final total = entry.value.fold<int>(
        0,
        (sum, t) =>
            sum + (t.type == CategoryType.income ? t.amountMinorUnits : -t.amountMinorUnits),
      );
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    formatMoney(total, showSign: true),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            SliverList.builder(
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final t = entry.value[index];
                final delay = (animIndex++).clamp(0, 12) * 30;
                return TransactionTile(
                  transaction: t,
                  category: data.categoriesById[t.categoryId],
                  showDate: false,
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(
                          transaction: t,
                          category: data.categoriesById[t.categoryId],
                        ),
                      ),
                    );
                    if (changed == true) _reload();
                  },
                ).animate().fadeIn(delay: delay.ms, duration: 220.ms).slideX(begin: 0.02, end: 0);
              },
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _ActivityData {
  final List<model.Transaction> transactions;
  final Map<int, Category> categoriesById;

  const _ActivityData(this.transactions, this.categoriesById);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
