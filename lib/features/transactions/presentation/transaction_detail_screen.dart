import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/notifications/budget_alert_service.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../accounts/data/account_repository.dart';
import '../../budgets/data/budget_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_picker_sheet.dart';
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
  final AccountRepository accountRepository;
  final BudgetRepository budgetRepository;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  TransactionDetailPane({
    super.key,
    required this.transaction,
    required this.category,
    required this.transactionRepository,
    required this.categoryRepository,
    required this.onChanged,
    required this.onDelete,
    AccountRepository? accountRepository,
    BudgetRepository? budgetRepository,
  }) : accountRepository = accountRepository ?? SupabaseAccountRepository(),
       budgetRepository = budgetRepository ?? SupabaseBudgetRepository();

  @override
  State<TransactionDetailPane> createState() => _TransactionDetailPaneState();
}

class _TransactionDetailPaneState extends State<TransactionDetailPane> {
  late Category? _category;

  /// A local copy, because an edit here can change the transaction's kind and
  /// accounts — not just its amount — and the widget's own copy is immutable.
  late model.Transaction _t;

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
    _t = widget.transaction;
  }

  Future<void> _recategorize() async {
    final categories = await widget.categoryRepository.listActiveCategories(
      _t.profileId,
    );
    if (!mounted) return;
    final picked = await showCategoryPickerSheet(
      context,
      categories: categories,
      selectedId: _category?.id,
    );
    if (picked == null || picked.id == _category?.id) return;
    // The type follows the category, so moving an expense into an income
    // category doesn't leave the row counted on the wrong side of every total.
    final type = picked.type == CategoryType.income
        ? model.TransactionKind.income
        : model.TransactionKind.expense;
    try {
      await widget.transactionRepository.updateTransaction(
        _t.id,
        categoryId: picked.id,
        type: type,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Moving the transaction');
      return;
    }
    setState(() {
      _category = picked;
      _t = _t.copyWith(
        categoryId: picked.id,
        transferAccountId: null,
        type: type,
      );
    });
    widget.onChanged();
    _checkBudget();
  }

  Future<void> _edit() async {
    final results = await Future.wait([
      widget.categoryRepository.listActiveCategories(_t.profileId),
      widget.accountRepository.listActiveAccounts(_t.profileId),
    ]);
    if (!mounted) return;
    final categories = results[0] as List<Category>;
    final accounts = results[1] as List<Account>;
    final result = await showTransactionEditSheet(
      context,
      transaction: _t,
      categories: categories,
      accounts: accounts,
    );
    if (result == null) return;
    try {
      await widget.transactionRepository.updateTransaction(
        _t.id,
        amountMinorUnits: result.amountMinorUnits,
        occurredAt: result.occurredAt,
        note: result.note,
        accountId: result.accountId,
        type: result.type,
        categoryId: result.categoryId,
        transferAccountId: result.transferAccountId,
      );
    } catch (_) {
      if (mounted) showActionError(context, 'Saving the changes');
      return;
    }
    setState(() {
      _t = _t.copyWith(
        amountMinorUnits: result.amountMinorUnits,
        occurredAt: result.occurredAt,
        note: result.note,
        accountId: result.accountId,
        type: result.type,
        categoryId: result.categoryId,
        transferAccountId: result.transferAccountId,
      );
      _category = result.categoryId == null
          ? null
          : categories.firstWhere(
              (c) => c.id == result.categoryId,
              orElse: () => categories.first,
            );
    });
    widget.onChanged();
    _checkBudget();
  }

  void _checkBudget() {
    if (_t.type != model.TransactionKind.expense || _category == null) return;
    unawaited(
      BudgetAlertService.checkThresholds(
        budgetRepository: widget.budgetRepository,
        transactionRepository: widget.transactionRepository,
        profileId: _t.profileId,
        categoryId: _category!.id,
        categoryName: _category!.name,
      ),
    );
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

    // _t, not the widget's copy: an edit in this session may have changed the
    // kind or accounts, and Undo has to restore what was actually deleted.
    final t = _t;
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
    final isIncome = _t.type == model.TransactionKind.income;
    final isTransfer = _t.isTransfer;

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
            _t.note?.isNotEmpty == true
                ? _t.note!
                : (isTransfer
                      ? 'Transfer'
                      : (_category?.name ?? 'Uncategorized')),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Center(
          child: MoneyText(
            isTransfer
                ? _t.amountMinorUnits
                : (isIncome ? _t.amountMinorUnits : -_t.amountMinorUnits),
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
                DateFormat.yMMMd().add_jm().format(_t.occurredAt),
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
  final AccountRepository accountRepository;

  TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.category,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository();

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
            accountRepository: widget.accountRepository,
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
