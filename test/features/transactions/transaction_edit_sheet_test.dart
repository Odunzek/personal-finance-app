import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/account.dart';
import 'package:finance_app/core/models/category.dart';
import 'package:finance_app/core/models/transaction.dart';
import 'package:finance_app/features/transactions/presentation/transaction_edit_sheet.dart';

const _groceries = Category(
  id: 1,
  profileId: 1,
  name: 'Groceries',
  type: CategoryType.expense,
  colorArgb: 0xFF5CA2AC,
  iconKey: 'groceries',
  isActive: true,
  sortOrder: 0,
);

const _dining = Category(
  id: 2,
  profileId: 1,
  name: 'Dining',
  type: CategoryType.expense,
  colorArgb: 0xFFE0654A,
  iconKey: 'dining',
  isActive: true,
  sortOrder: 1,
);

const _salary = Category(
  id: 3,
  profileId: 1,
  name: 'Salary',
  type: CategoryType.income,
  colorArgb: 0xFF34A874,
  iconKey: 'salary',
  isActive: true,
  sortOrder: 2,
);

const _cash = Account(
  id: 10,
  profileId: 1,
  name: 'Cash',
  type: AccountType.asset,
  debtKind: null,
  startingBalanceMinorUnits: 0,
  isActive: true,
  sortOrder: 0,
);

const _savings = Account(
  id: 11,
  profileId: 1,
  name: 'Savings',
  type: AccountType.asset,
  debtKind: null,
  startingBalanceMinorUnits: 0,
  isActive: true,
  sortOrder: 1,
);

final _expense = Transaction(
  id: 100,
  profileId: 1,
  accountId: _cash.id,
  categoryId: _groceries.id,
  transferAccountId: null,
  amountMinorUnits: 1250,
  type: TransactionKind.expense,
  occurredAt: DateTime(2026, 3, 5),
  note: 'milk',
);

/// Holds whatever the sheet returns, so a test can act on the sheet and then
/// assert on the result after it closes.
class _Opened {
  TransactionEditResult? result;
}

Future<_Opened> _open(WidgetTester tester, {Transaction? transaction}) async {
  // The sheet is tall; the default 600px test surface would leave Save and
  // the pickers off-screen and unhittable.
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              opened.result = await showTransactionEditSheet(
                context,
                transaction: transaction ?? _expense,
                categories: const [_groceries, _dining, _salary],
                accounts: const [_cash, _savings],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saving untouched keeps the original shape', (tester) async {
    final opened = await _open(tester);
    await _save(tester);

    expect(opened.result!.type, TransactionKind.expense);
    expect(opened.result!.categoryId, _groceries.id);
    expect(opened.result!.accountId, _cash.id);
    expect(opened.result!.amountMinorUnits, 1250);
    expect(opened.result!.transferAccountId, isNull);
  });

  testWidgets('changing the category is reported back', (tester) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(opened.result!.categoryId, _dining.id);
    expect(opened.result!.type, TransactionKind.expense);
    expect(opened.result!.transferAccountId, isNull);
  });

  testWidgets('switching to Income replaces an expense-only category', (
    tester,
  ) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);

    await _save(tester);

    expect(opened.result!.type, TransactionKind.income);
    expect(opened.result!.categoryId, _salary.id);
  });

  testWidgets('switching to Transfer clears the category and defaults the '
      'destination', (tester) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    expect(find.text('From account'), findsOneWidget);
    expect(find.text('To account'), findsOneWidget);
    expect(find.text('Category'), findsNothing);

    await _save(tester);

    expect(opened.result!.type, TransactionKind.transfer);
    expect(opened.result!.categoryId, isNull);
    expect(opened.result!.transferAccountId, _savings.id);
    expect(opened.result!.accountId, _cash.id);
  });

  testWidgets('a transfer can be converted back to an expense', (tester) async {
    final transfer = Transaction(
      id: 101,
      profileId: 1,
      accountId: _cash.id,
      categoryId: null,
      transferAccountId: _savings.id,
      amountMinorUnits: 5000,
      type: TransactionKind.transfer,
      occurredAt: DateTime(2026, 3, 6),
    );
    final opened = await _open(tester, transaction: transfer);

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(opened.result!.type, TransactionKind.expense);
    expect(opened.result!.transferAccountId, isNull);
    expect(opened.result!.categoryId, _groceries.id);
  });

  testWidgets('an amount with too many decimals blocks saving', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField).first, '12.345');
    await _save(tester);

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.textContaining('Enter an amount'), findsOneWidget);
  });
}
