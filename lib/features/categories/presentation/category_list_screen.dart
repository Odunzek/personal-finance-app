import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/default_categories.dart';
import '../../../core/models/profile.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/mural_background.dart';
import '../data/category_repository.dart';
import 'category_form_sheet.dart';
import 'category_insights_screen.dart';
import 'category_style_options.dart';

class CategoryListScreen extends StatefulWidget {
  final Profile profile;
  final CategoryRepository categoryRepository;

  CategoryListScreen({
    super.key,
    required this.profile,
    CategoryRepository? categoryRepository,
  }) : categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _categoriesFuture = widget.categoryRepository.listActiveCategories(
        widget.profile.id,
      );
    });
  }

  Future<void> _addCategory() async {
    final result = await showCategoryFormSheet(context);
    if (result == null) return;
    await widget.categoryRepository.createCategory(
      profileId: widget.profile.id,
      name: result.name,
      type: result.type,
      colorArgb: result.colorArgb,
      iconKey: result.iconKey,
    );
    _reload();
  }

  Future<void> _editCategory(Category category) async {
    final result = await showCategoryFormSheet(context, existing: category);
    if (result == null) return;
    if (result.name != category.name) {
      await widget.categoryRepository.renameCategory(category.id, result.name);
    }
    if (result.colorArgb != category.colorArgb) {
      await widget.categoryRepository.recolorCategory(
        category.id,
        result.colorArgb,
      );
    }
    _reload();
  }

  Future<void> _addMissingDefaults() async {
    final existing = await widget.categoryRepository.listActiveCategories(
      widget.profile.id,
    );
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    final missing = kDefaultCategorySeeds.where(
      (seed) => !existingNames.contains(seed.name.toLowerCase()),
    );
    for (final seed in missing) {
      await widget.categoryRepository.createCategory(
        profileId: widget.profile.id,
        name: seed.name,
        type: seed.type,
        colorArgb: seed.colorArgb,
        iconKey: seed.iconKey,
      );
    }
    _reload();
  }

  Future<void> _deactivateCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text(
          '"${category.name}" will no longer be available for new '
          'transactions. Existing transactions keep it.',
        ),
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
    await widget.categoryRepository.deactivateCategory(category.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.displayName),
        actions: [
          IconButton(
            onPressed: _addMissingDefaults,
            icon: const Icon(LucideIcons.sparkles),
            tooltip: 'Add default categories',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(LucideIcons.plus),
      ),
      body: MuralBackground.ambient(
        child: FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AsyncErrorView(onRetry: _reload);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final categories = snapshot.data!;
            if (categories.isEmpty) {
              return _EmptyState(onAdd: _addCategory);
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisExtent: 76,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CategoryBadge(
                          icon: iconForKey(category.iconKey),
                          color: Color(category.colorArgb),
                        ),
                        title: Text(category.name),
                        subtitle: Text(
                          category.type == CategoryType.income
                              ? 'Income'
                              : 'Expense',
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryInsightsScreen(
                              profile: widget.profile,
                              category: category,
                            ),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(LucideIcons.moreVertical),
                          onSelected: (value) {
                            if (value == 'edit') _editCategory(category);
                            if (value == 'remove') {
                              _deactivateCategory(category);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (index * 40).ms, duration: 200.ms)
                    .scale(begin: const Offset(0.97, 0.97));
              },
            );
          },
        ),
      ),
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
              LucideIcons.tags,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a category to start organizing your spending.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add a category'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
