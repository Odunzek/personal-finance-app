import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/money.dart';
import '../../../core/models/transaction.dart' as model;
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
import '../data/transaction_repository.dart';

class TransactionDetailScreen extends StatefulWidget {
  final model.Transaction transaction;
  final Category? category;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.category,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Category? _category;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  Future<void> _recategorize() async {
    final categories = await widget.categoryRepository.listActiveCategories(
      widget.transaction.profileId,
    );
    if (!mounted) return;
    final picked = await showModalBottomSheet<Category>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: categories
              .map(
                (c) => ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c.colorArgb),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      iconForKey(c.iconKey),
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(c.name),
                  trailing: c.id == _category?.id
                      ? const Icon(LucideIcons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(c),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null || picked.id == _category?.id) return;
    await widget.transactionRepository.updateTransaction(
      widget.transaction.id,
      categoryId: picked.id,
    );
    setState(() {
      _category = picked;
      _changed = true;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.transactionRepository.deleteTransaction(widget.transaction.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.type == CategoryType.income;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop(_changed)),
          actions: [
            IconButton(
              onPressed: _delete,
              icon: const Icon(LucideIcons.trash2),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _category != null
                      ? Color(_category!.colorArgb)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconForKey(_category?.iconKey ?? 'other'),
                  color: Colors.white,
                  size: 26,
                ),
              ).animate().scale(
                begin: const Offset(0.7, 0.7),
                duration: 350.ms,
                curve: Curves.easeOutBack,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                t.note?.isNotEmpty == true
                    ? t.note!
                    : (_category?.name ?? 'Uncategorized'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Center(
              child: Text(
                formatMoney(isIncome ? t.amountMinorUnits : -t.amountMinorUnits),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isIncome
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _DetailRow('Category', _category?.name ?? 'Uncategorized'),
                  _DetailRow(
                    'Date',
                    DateFormat.yMMMd().add_jm().format(t.occurredAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recategorize,
              child: const Text('Recategorize'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
