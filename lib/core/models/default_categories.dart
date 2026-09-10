import 'category.dart';

class DefaultCategorySeed {
  final String name;
  final CategoryType type;
  final String iconKey;
  final int colorArgb;

  const DefaultCategorySeed({
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorArgb,
  });
}

/// Seeded automatically into every newly created profile, so it's usable
/// right away instead of starting from a blank category list. Matches the
/// icon keys in `category_style_options.dart`.
const kDefaultCategorySeeds = [
  DefaultCategorySeed(
    name: 'Groceries',
    type: CategoryType.expense,
    iconKey: 'groceries',
    colorArgb: 0xFF5CA2AC,
  ),
  DefaultCategorySeed(
    name: 'Housing',
    type: CategoryType.expense,
    iconKey: 'housing',
    colorArgb: 0xFF2F8F6B,
  ),
  DefaultCategorySeed(
    name: 'Transport',
    type: CategoryType.expense,
    iconKey: 'transport',
    colorArgb: 0xFFC98A16,
  ),
  DefaultCategorySeed(
    name: 'Dining',
    type: CategoryType.expense,
    iconKey: 'dining',
    colorArgb: 0xFFA93B1F,
  ),
  DefaultCategorySeed(
    name: 'Entertainment',
    type: CategoryType.expense,
    iconKey: 'entertainment',
    colorArgb: 0xFF6B5CA0,
  ),
  DefaultCategorySeed(
    name: 'Utilities',
    type: CategoryType.expense,
    iconKey: 'utilities',
    colorArgb: 0xFF3B6EA9,
  ),
  DefaultCategorySeed(
    name: 'Health',
    type: CategoryType.expense,
    iconKey: 'health',
    colorArgb: 0xFFA05C8A,
  ),
  DefaultCategorySeed(
    name: 'Income',
    type: CategoryType.income,
    iconKey: 'income',
    colorArgb: 0xFF1F6B4F,
  ),
];
