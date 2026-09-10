import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/category.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/money_text.dart';

class BudgetEditResult {
  final int limitMinorUnits;
  final bool remove;

  const BudgetEditResult({required this.limitMinorUnits, this.remove = false});
}

Future<BudgetEditResult?> showBudgetEditSheet(
  BuildContext context, {
  required Category category,
  required int initialLimitMinorUnits,
  required int spentMinorUnits,
  required bool hasBudget,
}) {
  return showModalBottomSheet<BudgetEditResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BudgetEditSheet(
      category: category,
      initialLimitMinorUnits: initialLimitMinorUnits,
      spentMinorUnits: spentMinorUnits,
      hasBudget: hasBudget,
    ),
  );
}

const _stepMinorUnits = 2500;

class _BudgetEditSheet extends StatefulWidget {
  final Category category;
  final int initialLimitMinorUnits;
  final int spentMinorUnits;
  final bool hasBudget;

  const _BudgetEditSheet({
    required this.category,
    required this.initialLimitMinorUnits,
    required this.spentMinorUnits,
    required this.hasBudget,
  });

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late int _limit;

  @override
  void initState() {
    super.initState();
    _limit = widget.initialLimitMinorUnits;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _limit == 0 ? 0.0 : (widget.spentMinorUnits / _limit).clamp(0, 1.5);
    final color = ratio >= 1
        ? Theme.of(context).colorScheme.error
        : ratio >= 0.7
        ? const Color(0xFFC98A16)
        : Theme.of(context).colorScheme.primary;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              Text(
                widget.category.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(BudgetEditResult(limitMinorUnits: _limit)),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  'Monthly limit',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                MoneyText(_limit, fontSize: 34),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(widget.spentMinorUnits, fontSize: 14),
                    const Text(' spent so far this month'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => setState(
                  () => _limit = (_limit - _stepMinorUnits).clamp(0, 1 << 62),
                ),
                icon: const Icon(LucideIcons.minus),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => setState(() => _limit += _stepMinorUnits),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedProgressBar(value: ratio.toDouble(), color: color),
          if (widget.hasBudget) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(const BudgetEditResult(limitMinorUnits: 0, remove: true)),
              child: const Text('Remove budget'),
            ),
          ],
        ],
      ),
    );
  }
}
