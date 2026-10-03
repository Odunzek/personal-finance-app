import 'package:flutter/material.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/wishlist_item.dart';

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

/// Shows a bottom sheet to add a wishlist item, or edit [existing] when one
/// is given. Just a name is required; the estimated price and category tag
/// are both optional.
Future<WishlistItemFormResult?> showWishlistItemFormSheet(
  BuildContext context, {
  required List<Category> categories,
  WishlistItem? existing,
}) {
  return showModalBottomSheet<WishlistItemFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _WishlistItemFormSheet(categories: categories, existing: existing),
  );
}

class WishlistPartFormResult {
  final String name;
  final int? estimatedPriceMinorUnits;

  const WishlistPartFormResult({
    required this.name,
    required this.estimatedPriceMinorUnits,
  });
}

/// Adds one piece to an existing wishlist item (a drive for the home server),
/// or edits [existing]. No category here — a part inherits whatever its
/// parent item is tagged as.
Future<WishlistPartFormResult?> showWishlistPartFormSheet(
  BuildContext context, {
  required String itemName,
  WishlistPart? existing,
}) {
  return showModalBottomSheet<WishlistPartFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _WishlistPartFormSheet(itemName: itemName, existing: existing),
  );
}

class _WishlistPartFormSheet extends StatefulWidget {
  final String itemName;
  final WishlistPart? existing;

  const _WishlistPartFormSheet({required this.itemName, this.existing});

  @override
  State<_WishlistPartFormSheet> createState() => _WishlistPartFormSheetState();
}

class _WishlistPartFormSheetState extends State<_WishlistPartFormSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.existing?.estimatedPriceMinorUnits == null
        ? ''
        : (widget.existing!.estimatedPriceMinorUnits! / 100).toStringAsFixed(2),
  );

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
      WishlistPartFormResult(
        name: name,
        estimatedPriceMinorUnits: parseMoneyMinorUnits(_priceController.text),
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
              widget.existing == null ? 'Add a part' : 'Edit part',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Part of "${widget.itemName}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What is it?'),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.existing == null ? 'Add part' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistItemFormSheet extends StatefulWidget {
  final List<Category> categories;
  final WishlistItem? existing;

  const _WishlistItemFormSheet({required this.categories, this.existing});

  @override
  State<_WishlistItemFormSheet> createState() => _WishlistItemFormSheetState();
}

class _WishlistItemFormSheetState extends State<_WishlistItemFormSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.existing?.estimatedPriceMinorUnits == null
        ? ''
        : (widget.existing!.estimatedPriceMinorUnits! / 100).toStringAsFixed(2),
  );
  late Category? _category = widget.existing?.categoryId == null
      ? null
      : widget.categories
            .where((c) => c.id == widget.existing!.categoryId)
            .firstOrNull;

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
              widget.existing == null ? 'Add to wishlist' : 'Edit item',
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
                labelText: 'Total budget (optional)',
                helperText: 'Parts you add later are measured against this',
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
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
