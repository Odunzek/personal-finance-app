import 'package:flutter/material.dart';

import '../../../core/models/category.dart';
import 'category_style_options.dart';

class CategoryFormResult {
  final String name;
  final CategoryType type;
  final int colorArgb;
  final String iconKey;

  const CategoryFormResult({
    required this.name,
    required this.type,
    required this.colorArgb,
    required this.iconKey,
  });
}

/// Shows a bottom sheet to create a category, or edit [existing] if provided.
/// Returns the submitted values, or null if cancelled.
Future<CategoryFormResult?> showCategoryFormSheet(
  BuildContext context, {
  Category? existing,
}) {
  return showModalBottomSheet<CategoryFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CategoryFormSheet(existing: existing),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  final Category? existing;

  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late CategoryType _type;
  late int _colorArgb;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? CategoryType.expense;
    _colorArgb = existing?.colorArgb ?? kCategoryColors.first.toARGB32();
    _iconKey = existing?.iconKey ?? kCategoryIcons.keys.first;
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
      CategoryFormResult(
        name: name,
        type: _type,
        colorArgb: _colorArgb,
        iconKey: _iconKey,
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
            widget.existing == null ? 'New category' : 'Edit category',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<CategoryType>(
            segments: const [
              ButtonSegment(
                value: CategoryType.expense,
                label: Text('Expense'),
              ),
              ButtonSegment(value: CategoryType.income, label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (selection) =>
                setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
          const Text('Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kCategoryColors.map((color) {
              final selected = color.toARGB32() == _colorArgb;
              return GestureDetector(
                onTap: () => setState(() => _colorArgb = color.toARGB32()),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Container(
                    width: selected ? 32 : 28,
                    height: selected ? 32 : 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kCategoryIcons.entries.map((entry) {
              final selected = entry.key == _iconKey;
              return GestureDetector(
                onTap: () => setState(() => _iconKey = entry.key),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.2,
                          )
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(entry.value),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}
