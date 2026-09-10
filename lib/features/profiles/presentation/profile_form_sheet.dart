import 'package:flutter/material.dart';

import '../../../core/models/profile.dart';

class ProfileFormResult {
  final String displayName;
  final String currencyCode;
  final ProfileType type;

  const ProfileFormResult({
    required this.displayName,
    required this.currencyCode,
    required this.type,
  });
}

const List<String> kSupportedCurrencies = ['CAD', 'USD', 'EUR', 'GBP'];

Future<ProfileFormResult?> showProfileFormSheet(
  BuildContext context, {
  String? initialName,
  String initialCurrency = 'CAD',
}) {
  return showModalBottomSheet<ProfileFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ProfileFormSheet(
      initialName: initialName,
      initialCurrency: initialCurrency,
    ),
  );
}

class _ProfileFormSheet extends StatefulWidget {
  final String? initialName;
  final String initialCurrency;

  const _ProfileFormSheet({this.initialName, required this.initialCurrency});

  @override
  State<_ProfileFormSheet> createState() => _ProfileFormSheetState();
}

class _ProfileFormSheetState extends State<_ProfileFormSheet> {
  late final TextEditingController _nameController;
  late String _currency;
  ProfileType _type = ProfileType.personal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _currency = widget.initialCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      ProfileFormResult(
        displayName: name,
        currencyCode: _currency,
        type: _type,
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
          Text(
            widget.initialName == null ? 'New profile' : 'Rename profile',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Profile name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: kSupportedCurrencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _currency = value!),
          ),
          if (widget.initialName == null) ...[
            const SizedBox(height: 16),
            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ProfileType>(
              segments: const [
                ButtonSegment(
                  value: ProfileType.personal,
                  label: Text('Personal'),
                ),
                ButtonSegment(
                  value: ProfileType.business,
                  label: Text('Business'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _type == ProfileType.business
                  ? 'Seeded with business categories like Revenue, Payroll, and Software.'
                  : 'Seeded with everyday categories like Groceries and Dining.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.initialName == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}
