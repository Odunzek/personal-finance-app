import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/budget.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/transaction.dart' as model;
import '../../../core/widgets/budget_ring.dart';
import '../../../core/widgets/money_text.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/budget_repository.dart';
import 'savings_target_edit_sheet.dart';

/// A yearly savings goal, browsed and set one year at a time — switching
/// years here never touches the month the rest of the Budgets screen is
/// looking at, and each year's goal and progress are computed fresh from
/// that year's own transactions.
class YearlySavingsGoalCard extends StatefulWidget {
  final Profile profile;
  final BudgetRepository budgetRepository;
  final TransactionRepository transactionRepository;

  const YearlySavingsGoalCard({
    super.key,
    required this.profile,
    required this.budgetRepository,
    required this.transactionRepository,
  });

  @override
  State<YearlySavingsGoalCard> createState() => _YearlySavingsGoalCardState();
}

class _YearData {
  final SavingsGoal? goal;
  final int savedSoFar;

  const _YearData({required this.goal, required this.savedSoFar});
}

class _YearlySavingsGoalCardState extends State<YearlySavingsGoalCard> {
  late int _year;
  late Future<_YearData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _load();
  }

  void _load() {
    _dataFuture = _fetch();
  }

  Future<_YearData> _fetch() async {
    final results = await Future.wait([
      widget.budgetRepository.getSavingsGoal(widget.profile.id, _year),
      widget.transactionRepository.listTransactions(
        widget.profile.id,
        from: DateTime(_year),
        to: DateTime(_year + 1),
      ),
    ]);
    final goal = results[0] as SavingsGoal?;
    final transactions = results[1] as List<model.Transaction>;

    var saved = 0;
    for (final t in transactions) {
      if (t.isTransfer) continue;
      saved += t.type == model.TransactionKind.income
          ? t.amountMinorUnits
          : -t.amountMinorUnits;
    }

    return _YearData(goal: goal, savedSoFar: saved);
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _load();
    });
  }

  Future<void> _editGoal(_YearData data) async {
    final result = await showSavingsTargetEditSheet(
      context,
      initialTargetMinorUnits: data.goal?.targetMinorUnits ?? 0,
      savedSoFarMinorUnits: data.savedSoFar,
      sheetTitle: 'Savings goal — $_year',
      goalLabel: 'Yearly goal',
      progressSuffix: ' saved so far in $_year',
      stepMinorUnits: 25000,
    );
    if (result == null) return;
    await widget.budgetRepository.upsertSavingsGoal(
      profileId: widget.profile.id,
      year: _year,
      targetMinorUnits: result,
    );
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_YearData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final ratio =
            data == null ||
                data.goal == null ||
                data.goal!.targetMinorUnits == 0
            ? 0.0
            : (data.savedSoFar / data.goal!.targetMinorUnits)
                  .clamp(0, 1)
                  .toDouble();

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: data == null ? null : () => _editGoal(data),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  BudgetRing(
                    ratio: ratio,
                    color: Theme.of(context).colorScheme.primary,
                    size: 64,
                    strokeWidth: 7,
                    center: Text(
                      '${(ratio * 100).round()}%',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.target,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Savings goal',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (data == null)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (data.goal == null)
                          Text('Tap to set a $_year savings goal')
                        else
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              MoneyText(data.savedSoFar, fontSize: 15),
                              const Text(' of your '),
                              MoneyText(
                                data.goal!.targetMinorUnits,
                                fontSize: 15,
                              ),
                              const Text(' goal'),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _year >= DateTime.now().year
                            ? null
                            : () => _changeYear(1),
                        icon: const Icon(LucideIcons.chevronUp),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$_year',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      IconButton(
                        onPressed: () => _changeYear(-1),
                        icon: const Icon(LucideIcons.chevronDown),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}
