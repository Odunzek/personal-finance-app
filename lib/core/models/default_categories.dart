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
    colorArgb: 0xFF34A874,
  ),
  DefaultCategorySeed(
    name: 'Transport',
    type: CategoryType.expense,
    iconKey: 'transport',
    colorArgb: 0xFFD9932A,
  ),
  DefaultCategorySeed(
    name: 'Dining',
    type: CategoryType.expense,
    iconKey: 'dining',
    colorArgb: 0xFFE0654A,
  ),
  DefaultCategorySeed(
    name: 'Entertainment',
    type: CategoryType.expense,
    iconKey: 'entertainment',
    colorArgb: 0xFF8B7BC7,
  ),
  DefaultCategorySeed(
    name: 'Utilities',
    type: CategoryType.expense,
    iconKey: 'utilities',
    colorArgb: 0xFF4E8FD6,
  ),
  DefaultCategorySeed(
    name: 'Health',
    type: CategoryType.expense,
    iconKey: 'health',
    colorArgb: 0xFFC56FA0,
  ),
  DefaultCategorySeed(
    name: 'Income',
    type: CategoryType.income,
    iconKey: 'income',
    colorArgb: 0xFF23895F,
  ),
];
