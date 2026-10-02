import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MileageTripFormResult {
  final DateTime occurredAt;
  final String destination;
  final String? purpose;
  final double kilometers;

  const MileageTripFormResult({
    required this.occurredAt,
    required this.destination,
    required this.purpose,
    required this.kilometers,
  });
}

/// Shows a bottom sheet to log a business trip — date, destination, purpose,
/// and distance, exactly what CRA expects a mileage log to contain.
Future<MileageTripFormResult?> showMileageTripFormSheet(BuildContext context) {
  return showModalBottomSheet<MileageTripFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _MileageTripFormSheet(),
  );
}

class _MileageTripFormSheet extends StatefulWidget {
  const _MileageTripFormSheet();

  @override
  State<_MileageTripFormSheet> createState() => _MileageTripFormSheetState();
}

class _MileageTripFormSheetState extends State<_MileageTripFormSheet> {
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _kmController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _destinationController.dispose();
    _purposeController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final destination = _destinationController.text.trim();
    final km = double.tryParse(_kmController.text.trim());
    if (destination.isEmpty || km == null || km <= 0) return;
    Navigator.of(context).pop(
      MileageTripFormResult(
        occurredAt: _date,
        destination: destination,
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        kilometers: km,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Log a trip',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Destination (e.g. Client site, downtown)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kmController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Distance',
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
