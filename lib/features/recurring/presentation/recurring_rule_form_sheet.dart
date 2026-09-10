import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/category.dart';
import '../../../core/models/account.dart' as account_model;
import '../../../core/models/recurring_rule.dart';
import '../../../core/models/transaction.dart';

class RecurringRuleFormResult {
  final int accountId;
  final int categoryId;
  final TransactionKind type;
  final int amountMinorUnits;
  final RecurringFrequency frequency;
  final DateTime nextDueDate;
  final String? note;

  const RecurringRuleFormResult({
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amountMinorUnits,
    required this.frequency,
    required this.nextDueDate,
    required this.note,
  });
}

Future<RecurringRuleFormResult?> showRecurringRuleFormSheet(
  BuildContext context, {
  required List<Category> categories,
  required List<account_model.Account> accounts,
}) {
  return showModalBottomSheet<RecurringRuleFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _RecurringRuleFormSheet(categories: categories, accounts: accounts),
  );
}

class _RecurringRuleFormSheet extends StatefulWidget {
  final List<Category> categories;
  final List<account_model.Account> accounts;

  const _RecurringRuleFormSheet({
    required this.categories,
    required this.accounts,
  });

  @override
  State<_RecurringRuleFormSheet> createState() =>
      _RecurringRuleFormSheetState();
}

class _RecurringRuleFormSheetState extends State<_RecurringRuleFormSheet> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionKind _type = TransactionKind.expense;
  Category? _category;
  account_model.Account? _account;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _nextDueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _account = widget.accounts.firstOrNull;
    _syncCategoryForType();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _syncCategoryForType() {
    final wanted = _type == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;
    final matching = widget.categories.where((c) => c.type == wanted);
    _category = matching.isEmpty ? null : matching.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0 || _category == null || _account == null) return;
    Navigator.of(context).pop(
      RecurringRuleFormResult(
        accountId: _account!.id,
        categoryId: _category!.id,
        type: _type,
        amountMinorUnits: (amount * 100).round(),
        frequency: _frequency,
        nextDueDate: _nextDueDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = widget.categories.where(
      (c) =>
          c.type ==
          (_type == TransactionKind.income
              ? CategoryType.income
              : CategoryType.expense),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New recurring transaction',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
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
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _syncCategoryForType();
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categoryOptions)
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _category?.id == c.id,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Account', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in widget.accounts)
                  ChoiceChip(
                    label: Text(a.name),
                    selected: _account?.id == a.id,
                    onSelected: (_) => setState(() => _account = a),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Repeats', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in RecurringFrequency.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _frequency == f,
                    onSelected: (_) => setState(() => _frequency = f),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('First due'),
              subtitle: Text(DateFormat.yMMMd().format(_nextDueDate)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
