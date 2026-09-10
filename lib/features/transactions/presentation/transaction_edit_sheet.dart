import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/money_text.dart';

class TransactionEditResult {
  final int amountMinorUnits;
  final DateTime occurredAt;
  final String note;

  const TransactionEditResult({
    required this.amountMinorUnits,
    required this.occurredAt,
    required this.note,
  });
}

Future<TransactionEditResult?> showTransactionEditSheet(
  BuildContext context, {
  required int initialAmountMinorUnits,
  required DateTime initialOccurredAt,
  required String initialNote,
}) {
  return showModalBottomSheet<TransactionEditResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TransactionEditSheet(
      initialAmountMinorUnits: initialAmountMinorUnits,
      initialOccurredAt: initialOccurredAt,
      initialNote: initialNote,
    ),
  );
}

class _TransactionEditSheet extends StatefulWidget {
  final int initialAmountMinorUnits;
  final DateTime initialOccurredAt;
  final String initialNote;

  const _TransactionEditSheet({
    required this.initialAmountMinorUnits,
    required this.initialOccurredAt,
    required this.initialNote,
  });

  @override
  State<_TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<_TransactionEditSheet> {
  late final _amountController = TextEditingController(
    text: (widget.initialAmountMinorUnits.abs() / 100).toStringAsFixed(2),
  );
  late final _noteController = TextEditingController(text: widget.initialNote);
  late DateTime _occurredAt = widget.initialOccurredAt;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
    final dollars = double.tryParse(_amountController.text.trim());
    if (dollars == null || dollars <= 0) return;
    final sign = widget.initialAmountMinorUnits < 0 ? -1 : 1;
    Navigator.of(context).pop(
      TransactionEditResult(
        amountMinorUnits: sign * (dollars * 100).round(),
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
      ),
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Text('Edit transaction', style: TextStyle(fontWeight: FontWeight.w600)),
              TextButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Amount', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: MoneyText.style(context, fontSize: 28),
            decoration: const InputDecoration(prefixText: '\$'),
          ),
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
        ],
      ),
    );
  }
}
