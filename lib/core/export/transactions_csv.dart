import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Builds a CSV of [transactions], one row per transaction, newest first.
/// Amounts are written as plain decimal dollars (not minor units) since this
/// is meant for a human opening it in a spreadsheet, not round-tripping back
/// into the app.
String buildTransactionsCsv({
  required List<Transaction> transactions,
  required Map<int, Category> categoriesById,
  required Map<int, Account> accountsById,
}) {
  final sorted = [...transactions]
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  final buffer = StringBuffer('Date,Type,Account,Category,Note,Amount\n');
  for (final t in sorted) {
    final account = accountsById[t.accountId]?.name ?? '';
    final date =
        '${t.occurredAt.year.toString().padLeft(4, '0')}-'
        '${t.occurredAt.month.toString().padLeft(2, '0')}-'
        '${t.occurredAt.day.toString().padLeft(2, '0')}';

    String type;
    String category;
    String amount;
    switch (t.type) {
      case TransactionKind.transfer:
        type = 'Transfer';
        category = accountsById[t.transferAccountId]?.name ?? '';
        amount = _dollars(t.amountMinorUnits);
      case TransactionKind.income:
        type = 'Income';
        category = categoriesById[t.categoryId]?.name ?? '';
        amount = _dollars(t.amountMinorUnits);
      case TransactionKind.expense:
        type = 'Expense';
        category = categoriesById[t.categoryId]?.name ?? '';
        amount = _dollars(-t.amountMinorUnits);
    }

    buffer.writeln(
      [
        date,
        type,
        account,
        category,
        t.note ?? '',
        amount,
      ].map(_csvField).join(','),
    );
  }
  return buffer.toString();
}

String _dollars(int minorUnits) => (minorUnits / 100).toStringAsFixed(2);

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
