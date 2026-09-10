import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' show TransactionKind;
import '../../../core/notifications/budget_alert_service.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/mural_background.dart';
import '../../accounts/data/account_repository.dart';
import '../../budgets/data/budget_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_style_options.dart';
import '../data/transaction_repository.dart';

class QuickAddScreen extends StatefulWidget {
  final Profile profile;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final BudgetRepository budgetRepository;

  QuickAddScreen({
    super.key,
    required this.profile,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
    BudgetRepository? budgetRepository,
  }) : transactionRepository =
           transactionRepository ?? SupabaseTransactionRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository(),
       accountRepository = accountRepository ?? SupabaseAccountRepository(),
       budgetRepository = budgetRepository ?? SupabaseBudgetRepository();

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _noteController = TextEditingController();
  String _amount = '0';
  TransactionKind _kind = TransactionKind.expense;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  bool _saving = false;

  late Future<List<Category>> _categoriesFuture;
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.categoryRepository.listActiveCategories(
      widget.profile.id,
    );
    _accountsFuture = widget.accountRepository.listActiveAccounts(
      widget.profile.id,
    );
    _accountsFuture.then((accounts) {
      if (!mounted || accounts.isEmpty) return;
      setState(() {
        _selectedAccount = accounts.first;
        if (accounts.length > 1) _selectedToAccount = accounts[1];
      });
    });
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

  bool get _canSave {
    if (_amountMinorUnits <= 0 || _saving) return false;
    if (_kind == TransactionKind.transfer) {
      return _selectedAccount != null &&
          _selectedToAccount != null &&
          _selectedAccount!.id != _selectedToAccount!.id;
    }
    return _selectedAccount != null && _selectedCategory != null;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      if (_kind == TransactionKind.transfer) {
        await widget.transactionRepository.createTransfer(
          profileId: widget.profile.id,
          fromAccountId: _selectedAccount!.id,
          toAccountId: _selectedToAccount!.id,
          amountMinorUnits: _amountMinorUnits,
          occurredAt: DateTime.now(),
          note: note,
        );
      } else {
        await widget.transactionRepository.createTransaction(
          profileId: widget.profile.id,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory!.id,
          amountMinorUnits: _amountMinorUnits,
          type: _kind,
          occurredAt: DateTime.now(),
          note: note,
        );
        if (_kind == TransactionKind.expense) {
          // Fire-and-forget: a missed or slow budget alert shouldn't hold up
          // the save, and any failure here is not worth surfacing to the
          // user mid-save.
          unawaited(
            BudgetAlertService.checkThresholds(
              budgetRepository: widget.budgetRepository,
              transactionRepository: widget.transactionRepository,
              profileId: widget.profile.id,
              categoryId: _selectedCategory!.id,
              categoryName: _selectedCategory!.name,
            ),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
        child: MuralBackground.ambient(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = _FormContent(
                amount: _amount,
                kind: _kind,
                noteController: _noteController,
                categoriesFuture: _categoriesFuture,
                accountsFuture: _accountsFuture,
                selectedCategory: _selectedCategory,
                selectedAccount: _selectedAccount,
                selectedToAccount: _selectedToAccount,
                onKindChanged: (k) => setState(() {
                  _kind = k;
                  _selectedCategory = null;
                }),
                onCategorySelected: (c) =>
                    setState(() => _selectedCategory = c),
                onAccountSelected: (a) => setState(() => _selectedAccount = a),
                onToAccountSelected: (a) =>
                    setState(() => _selectedToAccount = a),
                amountSize: constraints.maxWidth >= kTabletBreakpoint ? 64 : 44,
              );

              if (constraints.maxWidth >= kTabletBreakpoint) {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: content,
                      ),
                    ),
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
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
                      child: content,
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
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  final String amount;
  final TransactionKind kind;
  final TextEditingController noteController;
  final Future<List<Category>> categoriesFuture;
  final Future<List<Account>> accountsFuture;
  final Category? selectedCategory;
  final Account? selectedAccount;
  final Account? selectedToAccount;
  final ValueChanged<TransactionKind> onKindChanged;
  final ValueChanged<Category> onCategorySelected;
  final ValueChanged<Account> onAccountSelected;
  final ValueChanged<Account> onToAccountSelected;
  final double amountSize;

  const _FormContent({
    required this.amount,
    required this.kind,
    required this.noteController,
    required this.categoriesFuture,
    required this.accountsFuture,
    required this.selectedCategory,
    required this.selectedAccount,
    required this.selectedToAccount,
    required this.onKindChanged,
    required this.onCategorySelected,
    required this.onAccountSelected,
    required this.onToAccountSelected,
    required this.amountSize,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = kind == TransactionKind.transfer;
    final categoryType = kind == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;

    return Column(
      children: [
        const SizedBox(height: 16),
        Text('Amount', style: Theme.of(context).textTheme.labelLarge),
        Text(
          '\$$amount',
          style: MoneyText.style(context, fontSize: amountSize),
        ),
        const SizedBox(height: 16),
        SegmentedButton<TransactionKind>(
          segments: const [
            ButtonSegment(
              value: TransactionKind.expense,
              label: Text('Expense'),
            ),
            ButtonSegment(value: TransactionKind.income, label: Text('Income')),
            ButtonSegment(
              value: TransactionKind.transfer,
              label: Text('Transfer'),
            ),
          ],
          selected: {kind},
          onSelectionChanged: (s) => onKindChanged(s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: isTransfer ? 'Note (optional)' : 'What was it for?',
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Account>>(
          future: accountsFuture,
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? [];
            if (accounts.isEmpty) return const SizedBox.shrink();
            if (isTransfer) {
              return Column(
                children: [
                  _AccountPicker(
                    label: 'From',
                    accounts: accounts,
                    selected: selectedAccount,
                    onSelected: onAccountSelected,
                  ),
                  const SizedBox(height: 12),
                  _AccountPicker(
                    label: 'To',
                    accounts: accounts
                        .where((a) => a.id != selectedAccount?.id)
                        .toList(),
                    selected: selectedToAccount,
                    onSelected: onToAccountSelected,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }
            if (accounts.length < 2) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountPicker(
                label: 'Account',
                accounts: accounts,
                selected: selectedAccount,
                onSelected: onAccountSelected,
              ),
            );
          },
        ),
        if (!isTransfer)
          FutureBuilder<List<Category>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              final categories = (snapshot.data ?? [])
                  .where((c) => c.type == categoryType)
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                padding: EdgeInsets.all(selected ? 3 : 0),
                                child: CategoryBadge(
                                  icon: iconForKey(c.iconKey),
                                  color: Color(c.colorArgb),
                                  size: 56,
                                  iconSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 30).ms, duration: 200.ms)
                      .scale(begin: const Offset(0.9, 0.9));
                },
              );
            },
          ),
      ],
    );
  }
}

class _AccountPicker extends StatelessWidget {
  final String label;
  final List<Account> accounts;
  final Account? selected;
  final ValueChanged<Account> onSelected;

  const _AccountPicker({
    required this.label,
    required this.accounts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accounts.map((a) {
            return ChoiceChip(
              label: Text(a.name),
              selected: a.id == selected?.id,
              onSelected: (_) => onSelected(a),
            );
          }).toList(),
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
        for (final k in [
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
          '.',
          '0',
          '⌫',
        ])
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
