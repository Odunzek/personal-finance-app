import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../categories/presentation/category_style_options.dart';

class TransactionEditResult {
  final int amountMinorUnits;
  final DateTime occurredAt;
  final String note;
  final TransactionKind type;
  final int accountId;

  /// Set for income/expense, null for a transfer.
  final int? categoryId;

  /// Set for a transfer (the destination), null otherwise.
  final int? transferAccountId;

  const TransactionEditResult({
    required this.amountMinorUnits,
    required this.occurredAt,
    required this.note,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.transferAccountId,
  });
}

/// Full editor for an existing transaction: its kind (expense/income/
/// transfer), account, category, amount, date, and note. Changing the kind is
/// supported here rather than forcing a delete-and-re-enter.
Future<TransactionEditResult?> showTransactionEditSheet(
  BuildContext context, {
  required Transaction transaction,
  required List<Category> categories,
  required List<Account> accounts,
}) {
  return showModalBottomSheet<TransactionEditResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TransactionEditSheet(
      transaction: transaction,
      categories: categories,
      accounts: accounts,
    ),
  );
}

class _TransactionEditSheet extends StatefulWidget {
  final Transaction transaction;
  final List<Category> categories;
  final List<Account> accounts;

  const _TransactionEditSheet({
    required this.transaction,
    required this.categories,
    required this.accounts,
  });

  @override
  State<_TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<_TransactionEditSheet> {
  late final _amountController = TextEditingController(
    text: (widget.transaction.amountMinorUnits.abs() / 100).toStringAsFixed(2),
  );
  late final _noteController = TextEditingController(
    text: widget.transaction.note ?? '',
  );
  late DateTime _occurredAt = widget.transaction.occurredAt;
  late TransactionKind _type = widget.transaction.type;
  late int _accountId = widget.transaction.accountId;
  late int? _categoryId = widget.transaction.categoryId;
  late int? _transferAccountId = widget.transaction.transferAccountId;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == TransactionKind.transfer;

  List<Category> get _categoriesForType => widget.categories
      .where(
        (c) =>
            c.type ==
            (_type == TransactionKind.income
                ? CategoryType.income
                : CategoryType.expense),
      )
      .toList();

  void _changeType(TransactionKind next) {
    setState(() {
      _type = next;
      _error = null;
      if (next == TransactionKind.transfer) {
        _categoryId = null;
        // Default the destination to any account that isn't the source, so
        // the sheet never opens in the invalid "transfer to itself" state.
        _transferAccountId ??= widget.accounts
            .firstWhere(
              (a) => a.id != _accountId,
              orElse: () => widget.accounts.first,
            )
            .id;
      } else {
        _transferAccountId = null;
        // The old category may belong to the other side now (an expense
        // category on an income transaction would contradict the row), so
        // drop it unless it still matches.
        final valid = _categoriesForType.any((c) => c.id == _categoryId);
        if (!valid) {
          _categoryId = _categoriesForType.isEmpty
              ? null
              : _categoriesForType.first.id;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _occurredAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _occurredAt.hour,
        _occurredAt.minute,
      );
    });
  }

  void _save() {
    final minorUnits = parseMoneyMinorUnits(_amountController.text);
    if (minorUnits == null || minorUnits <= 0) {
      setState(() => _error = 'Enter an amount like 12.50.');
      return;
    }
    if (_isTransfer) {
      if (_transferAccountId == null) {
        setState(() => _error = 'Choose where the money is going.');
        return;
      }
      if (_transferAccountId == _accountId) {
        setState(() => _error = 'A transfer needs two different accounts.');
        return;
      }
    } else if (_categoryId == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    Navigator.of(context).pop(
      TransactionEditResult(
        amountMinorUnits: minorUnits,
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
        type: _type,
        accountId: _accountId,
        categoryId: _isTransfer ? null : _categoryId,
        transferAccountId: _isTransfer ? _transferAccountId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Edit transaction',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionKind>(
              segments: const [
                ButtonSegment(
                  value: TransactionKind.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionKind.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionKind.transfer,
                  label: Text('Transfer'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => _changeType(s.first),
            ),
            const SizedBox(height: 16),
            Text('Amount', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: MoneyText.style(context, fontSize: 28),
              decoration: const InputDecoration(prefixText: '\$'),
            ),
            const SizedBox(height: 16),
            Text(
              _isTransfer ? 'From account' : 'Account',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            _AccountChips(
              accounts: widget.accounts,
              selectedId: _accountId,
              onSelected: (id) => setState(() {
                _accountId = id;
                _error = null;
                if (_transferAccountId == id) _transferAccountId = null;
              }),
            ),
            if (_isTransfer) ...[
              const SizedBox(height: 16),
              Text('To account', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              _AccountChips(
                accounts: widget.accounts
                    .where((a) => a.id != _accountId)
                    .toList(),
                selectedId: _transferAccountId,
                onSelected: (id) => setState(() {
                  _transferAccountId = id;
                  _error = null;
                }),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoriesForType.map((c) {
                  final selected = c.id == _categoryId;
                  return ChoiceChip(
                    avatar: CategoryBadge(
                      icon: iconForKey(c.iconKey),
                      color: Color(c.colorArgb),
                      size: 24,
                      iconSize: 13,
                    ),
                    label: Text(c.name),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _categoryId = c.id;
                      _error = null;
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Date', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: _pickDate,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(DateFormat.yMMMd().format(_occurredAt)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Note', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'What was it for?'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountChips extends StatelessWidget {
  final List<Account> accounts;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _AccountChips({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts
          .map(
            (a) => ChoiceChip(
              label: Text(a.name),
              selected: a.id == selectedId,
              onSelected: (_) => onSelected(a.id),
            ),
          )
          .toList(),
    );
  }
}
