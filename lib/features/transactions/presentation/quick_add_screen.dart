import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
import '../data/transaction_repository.dart';

const _tabletBreakpoint = 700.0;

class QuickAddScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  QuickAddScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _noteController = TextEditingController();
  String _amount = '0';
  CategoryType _type = CategoryType.expense;
  Category? _selectedCategory;
  bool _saving = false;

  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.categoryRepository.listActiveCategories(
      widget.profile.id,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _pressKey(String key) {
    setState(() {
      if (key == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
        _amount = _amount == '0' ? key : _amount + key;
      }
    });
  }

  int get _amountMinorUnits => ((double.tryParse(_amount) ?? 0) * 100).round();

  Future<void> _save() async {
    if (_amountMinorUnits <= 0 || _selectedCategory == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.transactionRepository.createTransaction(
        profileId: widget.profile.id,
        categoryId: _selectedCategory!.id,
        amountMinorUnits: _amountMinorUnits,
        type: _type,
        occurredAt: DateTime.now(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canSave =>
      _amountMinorUnits > 0 && _selectedCategory != null && !_saving;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 88,
        leading: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', softWrap: false),
          ),
        ),
        title: const Text('New transaction'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _canSave
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _tabletBreakpoint) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _FormContent(
                        amount: _amount,
                        type: _type,
                        noteController: _noteController,
                        categoriesFuture: _categoriesFuture,
                        selectedCategory: _selectedCategory,
                        onTypeChanged: (t) => setState(() {
                          _type = t;
                          _selectedCategory = null;
                        }),
                        onCategorySelected: (c) =>
                            setState(() => _selectedCategory = c),
                        amountSize: 64,
                      ),
                    ),
                  ),
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Center(child: _Keypad(onPressed: _pressKey)),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FormContent(
                      amount: _amount,
                      type: _type,
                      noteController: _noteController,
                      categoriesFuture: _categoriesFuture,
                      selectedCategory: _selectedCategory,
                      onTypeChanged: (t) => setState(() {
                        _type = t;
                        _selectedCategory = null;
                      }),
                      onCategorySelected: (c) =>
                          setState(() => _selectedCategory = c),
                      amountSize: 44,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _Keypad(onPressed: _pressKey),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  final String amount;
  final CategoryType type;
  final TextEditingController noteController;
  final Future<List<Category>> categoriesFuture;
  final Category? selectedCategory;
  final ValueChanged<CategoryType> onTypeChanged;
  final ValueChanged<Category> onCategorySelected;
  final double amountSize;

  const _FormContent({
    required this.amount,
    required this.type,
    required this.noteController,
    required this.categoriesFuture,
    required this.selectedCategory,
    required this.onTypeChanged,
    required this.onCategorySelected,
    required this.amountSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text('Amount', style: Theme.of(context).textTheme.labelLarge),
        Text(
          '\$$amount',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontSize: amountSize),
        ),
        const SizedBox(height: 16),
        SegmentedButton<CategoryType>(
          segments: const [
            ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
            ButtonSegment(value: CategoryType.income, label: Text('Income')),
          ],
          selected: {type},
          onSelectionChanged: (s) => onTypeChanged(s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'What was it for?',
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Category>>(
          future: categoriesFuture,
          builder: (context, snapshot) {
            final categories = (snapshot.data ?? [])
                .where((c) => c.type == type)
                .toList();
            if (categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No categories yet — add one in Settings.'),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 88,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final c = categories[index];
                final selected = c.id == selectedCategory?.id;
                return GestureDetector(
                  onTap: () => onCategorySelected(c),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.08 : 1.0,
                        duration: 180.ms,
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: 180.ms,
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(c.colorArgb),
                            borderRadius: BorderRadius.circular(16),
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Icon(
                            iconForKey(c.iconKey),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  delay: (index * 30).ms,
                  duration: 200.ms,
                ).scale(begin: const Offset(0.9, 0.9));
              },
            );
          },
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onPressed;

  const _Keypad({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'])
          _KeypadButton(label: k, onTap: () => onPressed(k)),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: label == '⌫'
              ? const Icon(LucideIcons.delete)
              : Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
