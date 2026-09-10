import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/category.dart';
import 'package:finance_app/core/models/profile.dart';
import 'package:finance_app/features/accounts/data/account_repository.dart';
import 'package:finance_app/features/auth/data/auth_repository.dart';
import 'package:finance_app/features/categories/data/category_repository.dart';
import 'package:finance_app/features/profiles/data/profile_repository.dart';
import 'package:finance_app/features/profiles/presentation/profile_list_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeProfileRepository implements ProfileRepository {
  final List<Profile> profiles;
  int nextId = 1;

  _FakeProfileRepository([List<Profile>? initial]) : profiles = initial ?? [];

  @override
  Future<List<Profile>> listProfiles() async => profiles;

  @override
  Future<Profile> createProfile({
    required String displayName,
    required String currencyCode,
    ProfileType type = ProfileType.personal,
  }) async {
    final profile = Profile(
      id: nextId++,
      displayName: displayName,
      currencyCode: currencyCode,
      sortOrder: 0,
      type: type,
    );
    profiles.add(profile);
    return profile;
  }

  @override
  Future<void> renameProfile(int id, String displayName) async {}

  @override
  Future<void> deleteProfile(int id) async {
    profiles.removeWhere((p) => p.id == id);
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> created = [];
  int nextId = 1;

  @override
  Future<List<Category>> listActiveCategories(int profileId) async =>
      created.where((c) => c.profileId == profileId).toList();

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
    created.add(category);
    return category;
  }

  @override
  Future<void> renameCategory(int id, String name) async {}

  @override
  Future<void> recolorCategory(int id, int colorArgb) async {}

  @override
  Future<void> deactivateCategory(int id) async {}
}

class _FakeAccountRepository implements AccountRepository {
  final List<Account> created = [];
  int nextId = 1;

  @override
  Future<List<Account>> listActiveAccounts(int profileId) async =>
      created.where((a) => a.profileId == profileId).toList();

  @override
  Future<Account> createAccount({
    required int profileId,
    required String name,
    required AccountType type,
    DebtKind? debtKind,
    required int startingBalanceMinorUnits,
  }) async {
    final account = Account(
      id: nextId++,
      profileId: profileId,
      name: name,
      type: type,
      debtKind: debtKind,
      startingBalanceMinorUnits: startingBalanceMinorUnits,
      isActive: true,
      sortOrder: 0,
    );
    created.add(account);
    return account;
  }

  @override
  Future<void> renameAccount(int id, String name) async {}

  @override
  Future<void> deactivateAccount(int id) async {}
}

void main() {
  testWidgets('shows empty state with no profiles', (tester) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileListScreen(
          authRepository: _FakeAuthRepository(),
          profileRepository: repo,
          categoryRepository: _FakeCategoryRepository(),
          accountRepository: _FakeAccountRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Create your first profile'), findsOneWidget);
  });

  testWidgets('adding another profile calls createProfile and lists it', (
    tester,
  ) async {
    // Start with one profile already present so creating a second one stays
    // on this screen (only the very first profile ever auto-continues into
    // the main app shell).
    final repo = _FakeProfileRepository([
      const Profile(
        id: 1,
        displayName: 'Existing',
        currencyCode: 'CAD',
        sortOrder: 0,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileListScreen(
          authRepository: _FakeAuthRepository(),
          profileRepository: repo,
          categoryRepository: _FakeCategoryRepository(),
          accountRepository: _FakeAccountRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Profile name'),
      'Personal',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(repo.profiles.map((p) => p.displayName), ['Existing', 'Personal']);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Existing'), findsOneWidget);
  });
}
