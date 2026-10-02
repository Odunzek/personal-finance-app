import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/account.dart';

class StatementOptions {
  final Account? account;
  final DateTime from;
  final DateTime to;

  const StatementOptions({
    required this.account,
    required this.from,
    required this.to,
  });
}

/// Shows a bottom sheet to pick the account (or all) and date range for a
/// printable statement. Defaults to the current calendar month.
Future<StatementOptions?> showStatementOptionsSheet(
  BuildContext context, {
  required List<Account> accounts,
}) {
  return showModalBottomSheet<StatementOptions>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StatementOptionsSheet(accounts: accounts),
  );
}

class _StatementOptionsSheet extends StatefulWidget {
  final List<Account> accounts;

  const _StatementOptionsSheet({required this.accounts});

  @override
  State<_StatementOptionsSheet> createState() => _StatementOptionsSheetState();
}

class _StatementOptionsSheetState extends State<_StatementOptionsSheet> {
  Account? _account;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2000),
      lastDate: _to,
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _to = picked);
  }

  void _applyPreset(DateTime from, DateTime to) {
    setState(() {
      _from = from;
      _to = to;
    });
  }

  void _submit() {
    Navigator.of(context)
        .pop(StatementOptions(account: _account, from: _from, to: _to));
  }

  @override
  Widget build(BuildContext context) {
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
              'Statement',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text('Account', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All accounts'),
                  selected: _account == null,
                  onSelected: (_) => setState(() => _account = null),
                ),
                for (final a in widget.accounts)
                  ChoiceChip(
                    label: Text(a.name),
                    selected: _account?.id == a.id,
                    onSelected: (_) => setState(() => _account = a),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Period', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('This month'),
                  onPressed: () {
                    final now = DateTime.now();
                    _applyPreset(
                      DateTime(now.year, now.month, 1),
                      DateTime(now.year, now.month + 1, 0),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('Last month'),
                  onPressed: () {
                    final now = DateTime.now();
                    _applyPreset(
                      DateTime(now.year, now.month - 1, 1),
                      DateTime(now.year, now.month, 0),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('This year'),
                  onPressed: () {
                    final now = DateTime.now();
                    _applyPreset(
                      DateTime(now.year, 1, 1),
                      DateTime(now.year, 12, 31),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('From'),
                    subtitle: Text(DateFormat.yMMMd().format(_from)),
                    onTap: _pickFrom,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('To'),
                    subtitle: Text(DateFormat.yMMMd().format(_to)),
                    onTap: _pickTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Generate statement'),
            ),
          ],
        ),
      ),
    );
  }
}
