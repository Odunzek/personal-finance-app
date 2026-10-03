import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/account.dart';
import '../models/account_balance.dart';
import '../models/category.dart';
import '../models/profile.dart';
import '../models/transaction.dart';

String _money(int minorUnits) => (minorUnits.abs() / 100).toStringAsFixed(2);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// One account's figures for the statement period.
class StatementSection {
  final Account account;
  final int openingMinorUnits;
  final List<Transaction> rows;
  final int incomeMinorUnits;
  final int expenseMinorUnits;
  final int transferInMinorUnits;
  final int transferOutMinorUnits;

  const StatementSection({
    required this.account,
    required this.openingMinorUnits,
    required this.rows,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.transferInMinorUnits,
    required this.transferOutMinorUnits,
  });

  int get closingMinorUnits =>
      openingMinorUnits +
      incomeMinorUnits -
      expenseMinorUnits +
      transferInMinorUnits -
      transferOutMinorUnits;

  int get totalInMinorUnits => incomeMinorUnits + transferInMinorUnits;
  int get totalOutMinorUnits => expenseMinorUnits + transferOutMinorUnits;
}

/// Builds a printable statement in the shape of a bank statement: one section
/// per account, each with an opening balance, dated In/Out rows and a running
/// balance, then a closing balance.
///
/// Debt payments and transfers between the owner's own accounts appear in the
/// In/Out columns and move the running balance — money really did leave the
/// account — but they are totalled on their own line rather than inside
/// "expenses". Paying down a debt settles a cost that was already recorded
/// when the debt was taken on; counting the payment as an expense too would
/// record the same purchase twice, and on a business profile that figure is
/// a tax number.
///
/// [allTransactions] is every transaction for the profile, unfiltered: the
/// opening balance is derived from everything *before* [from], so the
/// statement can't be built from a pre-windowed list.
Future<pw.Document> buildStatementPdf({
  required Profile profile,
  required List<Account> accounts,
  required DateTime from,

  /// Exclusive.
  required DateTime to,
  required List<Transaction> allTransactions,
  required Map<int, Category> categoriesById,
  required Map<int, Account> accountsById,
}) async {
  final sections = [
    for (final account in accounts)
      buildStatementSection(account, allTransactions, from, to),
  ];

  // Expenses by category across every account in scope — the figure that
  // gets transcribed at tax time. Transfers are excluded by construction.
  final byCategory = <String, int>{};
  final seen = <int>{};
  for (final section in sections) {
    for (final t in section.rows) {
      if (t.isTransfer || t.type != TransactionKind.expense) continue;
      // A transaction can appear in two sections only if it's a transfer,
      // which is already skipped; this guards against any future overlap.
      if (!seen.add(t.id)) continue;
      final name = categoriesById[t.categoryId]?.name ?? 'Uncategorized';
      byCategory[name] = (byCategory[name] ?? 0) + t.amountMinorUnits;
    }
  }
  final categoryRows = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            profile.displayName,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            accounts.length == 1 ? accounts.single.name : 'All accounts',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            '${_date(from)} to ${_date(to.subtract(const Duration(days: 1)))}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Divider(height: 20),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated from records entered in Fin Tracker. '
                'Not a bank-issued statement.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        for (final section in sections) ...[
          _sectionBlock(section, categoriesById, accountsById),
          pw.SizedBox(height: 18),
        ],
        if (sections.length > 1) _combinedSummary(sections),
        if (categoryRows.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _categoryBreakdown(categoryRows),
        ],
      ],
    ),
  );
  return doc;
}

StatementSection buildStatementSection(
  Account account,
  List<Transaction> allTransactions,
  DateTime from,
  DateTime to,
) {
  var opening = account.startingBalanceMinorUnits;
  final rows = <Transaction>[];
  var income = 0;
  var expense = 0;
  var transferIn = 0;
  var transferOut = 0;

  for (final t in allTransactions) {
    if (!transactionTouchesAccount(t, account.id)) continue;
    if (t.occurredAt.isBefore(from)) {
      opening += signedAmountForAccount(t, account.id);
      continue;
    }
    if (!t.occurredAt.isBefore(to)) continue;
    rows.add(t);
    if (t.isTransfer) {
      if (t.accountId == account.id) {
        transferOut += t.amountMinorUnits;
      } else {
        transferIn += t.amountMinorUnits;
      }
    } else if (t.type == TransactionKind.income) {
      income += t.amountMinorUnits;
    } else {
      expense += t.amountMinorUnits;
    }
  }

  rows.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  return StatementSection(
    account: account,
    openingMinorUnits: opening,
    rows: rows,
    incomeMinorUnits: income,
    expenseMinorUnits: expense,
    transferInMinorUnits: transferIn,
    transferOutMinorUnits: transferOut,
  );
}

/// "Payment to Klarna" rather than "Transfer to Klarna" when the other side
/// is a debt — which is what the movement actually is, and how it reads on a
/// real statement.
String _transferLabel(
  Transaction t,
  Account account,
  Map<int, Account> accountsById,
) {
  final isOutgoing = t.accountId == account.id;
  final otherId = isOutgoing ? t.transferAccountId : t.accountId;
  final other = accountsById[otherId];
  final otherName = other?.name ?? 'account';
  final settlesDebt = isOutgoing
      ? other?.type == AccountType.liability
      : account.type == AccountType.liability;
  if (settlesDebt) {
    return isOutgoing ? 'Payment to $otherName' : 'Payment from $otherName';
  }
  return isOutgoing ? 'Transfer to $otherName' : 'Transfer from $otherName';
}

pw.Widget _sectionBlock(
  StatementSection section,
  Map<int, Category> categoriesById,
  Map<int, Account> accountsById,
) {
  var running = section.openingMinorUnits;
  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('Date', bold: true),
        _cell('Description', bold: true),
        _cell('Category', bold: true),
        _cell('In', bold: true, alignRight: true),
        _cell('Out', bold: true, alignRight: true),
        _cell('Balance', bold: true, alignRight: true),
      ],
    ),
    pw.TableRow(
      children: [
        _cell(''),
        _cell('Opening balance', italic: true),
        _cell(''),
        _cell(''),
        _cell(''),
        _cell(_money(running), alignRight: true, bold: true),
      ],
    ),
  ];

  for (final t in section.rows) {
    final delta = signedAmountForAccount(t, section.account.id);
    running += delta;
    final isTransfer = t.isTransfer;
    final description = isTransfer
        ? _transferLabel(t, section.account, accountsById)
        : (t.note?.trim().isNotEmpty == true
              ? t.note!.trim()
              : (categoriesById[t.categoryId]?.name ?? 'Uncategorized'));
    final categoryLabel = isTransfer
        ? (description.startsWith('Payment') ? 'Debt payment' : 'Transfer')
        : (categoriesById[t.categoryId]?.name ?? 'Uncategorized');

    rows.add(
      pw.TableRow(
        children: [
          _cell(_date(t.occurredAt)),
          _cell(description),
          _cell(categoryLabel),
          _cell(delta > 0 ? _money(delta) : '', alignRight: true),
          _cell(delta < 0 ? _money(delta) : '', alignRight: true),
          _cell(
            '${running < 0 ? '-' : ''}${_money(running)}',
            alignRight: true,
          ),
        ],
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        section.account.name,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1.5),
          1: pw.FlexColumnWidth(3.0),
          2: pw.FlexColumnWidth(1.8),
          3: pw.FlexColumnWidth(1.2),
          4: pw.FlexColumnWidth(1.2),
          5: pw.FlexColumnWidth(1.4),
        },
        children: rows,
      ),
      pw.SizedBox(height: 8),
      _totalsBlock(section),
    ],
  );
}

pw.Widget _totalsBlock(StatementSection section) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 260,
      child: pw.Column(
        children: [
          _summaryRow('Money in (income)', _money(section.incomeMinorUnits)),
          _summaryRow(
            'Money out (expenses)',
            _money(section.expenseMinorUnits),
          ),
          if (section.transferInMinorUnits > 0)
            _summaryRow('Transfers in', _money(section.transferInMinorUnits)),
          if (section.transferOutMinorUnits > 0)
            _summaryRow(
              'Debt payments & transfers out',
              _money(section.transferOutMinorUnits),
            ),
          pw.Divider(height: 8),
          _summaryRow(
            'Closing balance',
            '${section.closingMinorUnits < 0 ? '-' : ''}'
                '${_money(section.closingMinorUnits)}',
            bold: true,
          ),
        ],
      ),
    ),
  );
}

pw.Widget _combinedSummary(List<StatementSection> sections) {
  var income = 0;
  var expense = 0;
  for (final s in sections) {
    income += s.incomeMinorUnits;
    expense += s.expenseMinorUnits;
  }
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'All accounts combined',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _summaryRow('Total income', _money(income)),
        _summaryRow('Total expenses', _money(expense)),
        pw.Divider(height: 8),
        _summaryRow(
          'Net',
          '${income - expense < 0 ? '-' : ''}${_money(income - expense)}',
          bold: true,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Transfers between your own accounts are excluded here — they move '
          'money without being income or expense.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    ),
  );
}

pw.Widget _categoryBreakdown(List<MapEntry<String, int>> rows) {
  final total = rows.fold<int>(0, (sum, e) => sum + e.value);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Expenses by category',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.SizedBox(
        width: 280,
        child: pw.Column(
          children: [
            for (final e in rows) _summaryRow(e.key, _money(e.value)),
            pw.Divider(height: 8),
            _summaryRow('Total', _money(total), bold: true),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  bool italic = false,
  bool alignRight = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      ),
    ),
  );
}

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 10,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
