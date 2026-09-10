import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finance_app/features/auth/data/auth_repository.dart';
import 'package:finance_app/features/auth/presentation/sign_in_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  String? lastSignInEmail;
  String? lastSignUpEmail;
  Object? errorToThrow;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastSignInEmail = email;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastSignUpEmail = email;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('shows validation errors on empty submit', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authRepository: repo)),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(repo.lastSignInEmail, isNull);
  });

  testWidgets('submits valid credentials to signIn', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authRepository: repo)),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password1',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(repo.lastSignInEmail, 'a@b.com');
  });

  testWidgets('toggling to sign-up mode calls signUp instead', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authRepository: repo)),
    );

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password1',
    );
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(repo.lastSignUpEmail, 'a@b.com');
  });

  testWidgets('shows a friendly message on sign-in error', (tester) async {
    final repo = _FakeAuthRepository()
      ..errorToThrow = Exception('Invalid login credentials');
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authRepository: repo)),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password1',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
