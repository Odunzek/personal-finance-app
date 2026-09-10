import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
import '../data/transaction_repository.dart';
import 'transaction_edit_sheet.dart';

/// The recategorize/edit/delete content for a single transaction, shared
/// between the full-screen phone route ([TransactionDetailScreen]) and the
/// tablet two-pane layout in [ActivityScreen], so the logic only lives once.
class TransactionDetailPane extends StatefulWidget {
  final model.Transaction transaction;
  final Category? category;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const TransactionDetailPane({
    super.key,
    required this.transaction,
    required this.category,
    required this.transactionRepository,
    required this.categoryRepository,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TransactionDetailPane> createState() => _TransactionDetailPaneState();
}

class _TransactionDetailPaneState extends State<TransactionDetailPane> {
  late Category? _category;
  late int _amountMinorUnits;
  late DateTime _occurredAt;
  late String? _note;

  @override
  void initState() {
    super.initState();
    _resetFromWidget();
  }

  @override
  void didUpdateWidget(TransactionDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaction.id != widget.transaction.id) _resetFromWidget();
  }

  void _resetFromWidget() {
    _category = widget.category;
    _amountMinorUnits = widget.transaction.amountMinorUnits;
    _occurredAt = widget.transaction.occurredAt;
    _note = widget.transaction.note;
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
                  leading: CategoryBadge(
                    icon: iconForKey(c.iconKey),
                    color: Color(c.colorArgb),
                    size: 32,
                    iconSize: 18,
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
    setState(() => _category = picked);
    widget.onChanged();
  }

  Future<void> _edit() async {
    final result = await showTransactionEditSheet(
      context,
      initialAmountMinorUnits: _amountMinorUnits,
      initialOccurredAt: _occurredAt,
      initialNote: _note ?? '',
    );
    if (result == null) return;
    await widget.transactionRepository.updateTransaction(
      widget.transaction.id,
      amountMinorUnits: result.amountMinorUnits.abs(),
      occurredAt: result.occurredAt,
      note: result.note,
    );
    setState(() {
      _amountMinorUnits = result.amountMinorUnits.abs();
      _occurredAt = result.occurredAt;
      _note = result.note;
    });
    widget.onChanged();
  }

  Future<void> _confirmDelete() async {
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

    final t = widget.transaction;
    await widget.transactionRepository.deleteTransaction(t.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    widget.onDelete();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            if (t.isTransfer) {
              await widget.transactionRepository.createTransfer(
                profileId: t.profileId,
                fromAccountId: t.accountId,
                toAccountId: t.transferAccountId!,
                amountMinorUnits: t.amountMinorUnits,
                occurredAt: t.occurredAt,
                note: t.note,
              );
            } else {
              await widget.transactionRepository.createTransaction(
                profileId: t.profileId,
                accountId: t.accountId,
                categoryId: t.categoryId!,
                amountMinorUnits: t.amountMinorUnits,
                type: t.type,
                occurredAt: t.occurredAt,
                note: t.note,
              );
            }
            widget.onChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.type == model.TransactionKind.income;
    final isTransfer = t.isTransfer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(onPressed: _edit, icon: const Icon(LucideIcons.pencil)),
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(LucideIcons.trash2),
            ),
          ],
        ),
        Center(
          child:
              CategoryBadge(
                icon: isTransfer
                    ? LucideIcons.arrowRightLeft
                    : iconForKey(_category?.iconKey ?? 'other'),
                color: isTransfer
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : (_category != null ? Color(_category!.colorArgb) : null),
                size: 56,
                iconSize: 26,
              ).animate().scale(
                begin: const Offset(0.7, 0.7),
                duration: 350.ms,
                curve: Curves.easeOutBack,
              ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _note?.isNotEmpty == true
                ? _note!
                : (isTransfer
                      ? 'Transfer'
                      : (_category?.name ?? 'Uncategorized')),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Center(
          child: MoneyText(
            isTransfer
                ? _amountMinorUnits
                : (isIncome ? _amountMinorUnits : -_amountMinorUnits),
            fontSize: 34,
            color: !isTransfer && isIncome
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              if (!isTransfer)
                _DetailRow('Category', _category?.name ?? 'Uncategorized'),
              _DetailRow(
                'Date',
                DateFormat.yMMMd().add_jm().format(_occurredAt),
              ),
            ],
          ),
        ),
        if (!isTransfer) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _recategorize,
            child: const Text('Recategorize'),
          ),
        ],
      ],
    );
  }
}

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
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: MuralBackground.ambient(
          child: TransactionDetailPane(
            transaction: widget.transaction,
            category: widget.category,
            transactionRepository: widget.transactionRepository,
            categoryRepository: widget.categoryRepository,
            onChanged: () => setState(() => _changed = true),
            onDelete: () => Navigator.of(context).pop(true),
          ),
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
