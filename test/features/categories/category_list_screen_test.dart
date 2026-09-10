import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/category.dart';
import 'package:finance_app/core/models/profile.dart';
import 'package:finance_app/features/categories/data/category_repository.dart';
import 'package:finance_app/features/categories/presentation/category_list_screen.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> categories;
  int nextId = 1;
  int? deactivatedId;
  String? renamedTo;

  _FakeCategoryRepository([List<Category>? initial])
    : categories = initial ?? [];

  @override
  Future<List<Category>> listActiveCategories(int profileId) async =>
      categories.where((c) => c.isActive).toList();

  @override
  Future<Category> createCategory({
    required int profileId,
    required String name,
    required CategoryType type,
    required int colorArgb,
    required String iconKey,
  }) async {
    final category = Category(
      id: nextId++,
      profileId: profileId,
      name: name,
      type: type,
      colorArgb: colorArgb,
      iconKey: iconKey,
      isActive: true,
      sortOrder: 0,
    );
    categories.add(category);
    return category;
  }

  @override
  Future<void> renameCategory(int id, String name) async {
    renamedTo = name;
  }

  @override
  Future<void> recolorCategory(int id, int colorArgb) async {}

  @override
  Future<void> deactivateCategory(int id) async {
    deactivatedId = id;
    categories.removeWhere((c) => c.id == id);
  }
}

final _testProfile = const Profile(
  id: 1,
  displayName: 'Personal',
  currencyCode: 'CAD',
  sortOrder: 0,
);

void main() {
  testWidgets('shows empty state with no categories', (tester) async {
    final repo = _FakeCategoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListScreen(profile: _testProfile, categoryRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No categories yet'), findsOneWidget);
  });

  testWidgets('lists existing categories', (tester) async {
    final repo = _FakeCategoryRepository([
      const Category(
        id: 1,
        profileId: 1,
        name: 'Groceries',
        type: CategoryType.expense,
        colorArgb: 0xFF5CA2AC,
        iconKey: 'groceries',
        isActive: true,
        sortOrder: 0,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListScreen(profile: _testProfile, categoryRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
  });

  testWidgets('adding a category calls createCategory', (tester) async {
    final repo = _FakeCategoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListScreen(profile: _testProfile, categoryRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Dining');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(repo.categories.single.name, 'Dining');
    expect(find.text('Dining'), findsOneWidget);
  });
}
