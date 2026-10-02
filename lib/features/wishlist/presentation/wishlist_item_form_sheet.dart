import 'package:flutter/material.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';

class WishlistItemFormResult {
  final String name;
  final int? estimatedPriceMinorUnits;
  final int? categoryId;

  const WishlistItemFormResult({
    required this.name,
    required this.estimatedPriceMinorUnits,
    required this.categoryId,
  });
}

/// Shows a bottom sheet to add a wishlist item — just a name is required;
/// the estimated price and category tag are both optional.
Future<WishlistItemFormResult?> showWishlistItemFormSheet(
  BuildContext context, {
  required List<Category> categories,
}) {
  return showModalBottomSheet<WishlistItemFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _WishlistItemFormSheet(categories: categories),
  );
}

class _WishlistItemFormSheet extends StatefulWidget {
  final List<Category> categories;

  const _WishlistItemFormSheet({required this.categories});

  @override
  State<_WishlistItemFormSheet> createState() => _WishlistItemFormSheetState();
}

class _WishlistItemFormSheetState extends State<_WishlistItemFormSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  Category? _category;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      WishlistItemFormResult(
        name: name,
        estimatedPriceMinorUnits: parseMoneyMinorUnits(_priceController.text),
        categoryId: _category?.id,
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
              'Add to wishlist',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What do you want to buy?',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Estimated price (optional)',
                prefixText: '\$',
              ),
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Category (optional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('None'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final c in widget.categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _category?.id == c.id,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}
