import 'package:flutter/material.dart';

import '../../../core/models/account.dart';

class AccountFormResult {
  final String name;
  final AccountType type;
  final DebtKind? debtKind;
  final int startingBalanceMinorUnits;

  const AccountFormResult({
    required this.name,
    required this.type,
    required this.debtKind,
    required this.startingBalanceMinorUnits,
  });
}

/// Shows a bottom sheet to create an account. A debt account's starting
/// balance should be entered as the amount currently owed — it's stored
/// as a negative number under the hood, so its balance reads as debt.
Future<AccountFormResult?> showAccountFormSheet(BuildContext context) {
  return showModalBottomSheet<AccountFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _AccountFormSheet(),
  );
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet();

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  AccountType _type = AccountType.asset;
  DebtKind _debtKind = DebtKind.creditCard;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final dollars = double.tryParse(_balanceController.text.trim()) ?? 0;
    final magnitude = (dollars.abs() * 100).round();
    final isLiability = _type == AccountType.liability;
    Navigator.of(context).pop(
      AccountFormResult(
        name: name,
        type: _type,
        debtKind: isLiability ? _debtKind : null,
        startingBalanceMinorUnits: isLiability ? -magnitude : magnitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiability = _type == AccountType.liability;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New account',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Checking, Visa, Klarna)',
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<AccountType>(
            segments: const [
              ButtonSegment(
                value: AccountType.asset,
                label: Text('Checking / Cash'),
              ),
              ButtonSegment(value: AccountType.liability, label: Text('Debt')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          if (isLiability) ...[
            const SizedBox(height: 16),
            Text('Kind of debt', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in DebtKind.values)
                  ChoiceChip(
                    label: Text(kind.label),
                    selected: _debtKind == kind,
                    onSelected: (_) => setState(() => _debtKind = kind),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isLiability
                  ? 'Amount currently owed'
                  : 'Current balance',
              prefixText: '\$',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}
