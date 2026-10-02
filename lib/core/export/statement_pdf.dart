import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/account.dart';
import '../models/category.dart';
import '../models/profile.dart';
import '../models/transaction.dart';

String _dollars(int minorUnits) {
  final sign = minorUnits < 0 ? '-' : '';
  final abs = minorUnits.abs();
  return '$sign\$${(abs / 100).toStringAsFixed(2)}';
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Builds a printable statement for [transactions] already filtered to the
/// wanted date range and account — a running list with a totals footer, the
/// shape an accountant or bookkeeper expects at a glance rather than a raw
/// CSV dump.
Future<pw.Document> buildStatementPdf({
  required Profile profile,
  required Account? account,
  required DateTime from,
  required DateTime to,
  required List<Transaction> transactions,
  required Map<int, Category> categoriesById,
  required Map<int, Account> accountsById,
}) async {
  final sorted = [...transactions]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  var income = 0;
  var expense = 0;
  for (final t in sorted) {
    if (t.isTransfer) continue;
    if (t.type == TransactionKind.income) {
      income += t.amountMinorUnits;
    } else {
      expense += t.amountMinorUnits;
    }
  }

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
            account == null ? 'All accounts' : account.name,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            '${_date(from)} to ${_date(to)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Divider(height: 20),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1.6),
            1: pw.FlexColumnWidth(2.6),
            2: pw.FlexColumnWidth(2.4),
            3: pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Date', bold: true),
                _cell('Category', bold: true),
                _cell('Note', bold: true),
                _cell('Amount', bold: true, alignRight: true),
              ],
            ),
            for (final t in sorted)
              pw.TableRow(
                children: [
                  _cell(_date(t.occurredAt)),
                  _cell(
                    t.isTransfer
                        ? (account != null && t.transferAccountId == account.id
                              ? 'Transfer from ${accountsById[t.accountId]?.name ?? ''}'
                              : 'Transfer → ${accountsById[t.transferAccountId]?.name ?? ''}')
                        : (categoriesById[t.categoryId]?.name ??
                              'Uncategorized'),
                  ),
                  _cell(t.note ?? ''),
                  _cell(
                    t.isTransfer
                        ? _dollars(
                            // For a single-account statement, sign the
                            // transfer relative to that account: money in is
                            // positive, money out is negative. With no
                            // account focus ("all accounts"), there's no
                            // single side to sign from, so show it plain.
                            account == null
                                ? t.amountMinorUnits
                                : (t.transferAccountId == account.id
                                      ? t.amountMinorUnits
                                      : -t.amountMinorUnits),
                          )
                        : _dollars(
                            t.type == TransactionKind.income
                                ? t.amountMinorUnits
                                : -t.amountMinorUnits,
                          ),
                    alignRight: true,
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        _summaryRow('Total income', _dollars(income)),
        _summaryRow('Total expense', _dollars(-expense)),
        pw.Divider(),
        _summaryRow('Net', _dollars(income - expense), bold: true),
      ],
    ),
  );
  return doc;
}

pw.Widget _cell(String text, {bool bold = false, bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 11,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
