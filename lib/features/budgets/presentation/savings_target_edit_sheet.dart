import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/money_text.dart';

Future<int?> showSavingsTargetEditSheet(
  BuildContext context, {
  required int initialTargetMinorUnits,
  required int savedSoFarMinorUnits,
  String sheetTitle = 'Savings target',
  String goalLabel = 'Monthly goal',
  String progressSuffix = ' of your goal so far this month',
  int stepMinorUnits = 2500,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SavingsTargetEditSheet(
      initialTargetMinorUnits: initialTargetMinorUnits,
      savedSoFarMinorUnits: savedSoFarMinorUnits,
      sheetTitle: sheetTitle,
      goalLabel: goalLabel,
      progressSuffix: progressSuffix,
      stepMinorUnits: stepMinorUnits,
    ),
  );
}

class _SavingsTargetEditSheet extends StatefulWidget {
  final int initialTargetMinorUnits;
  final int savedSoFarMinorUnits;
  final String sheetTitle;
  final String goalLabel;
  final String progressSuffix;
  final int stepMinorUnits;

  const _SavingsTargetEditSheet({
    required this.initialTargetMinorUnits,
    required this.savedSoFarMinorUnits,
    required this.sheetTitle,
    required this.goalLabel,
    required this.progressSuffix,
    required this.stepMinorUnits,
  });

  @override
  State<_SavingsTargetEditSheet> createState() =>
      _SavingsTargetEditSheetState();
}

class _SavingsTargetEditSheetState extends State<_SavingsTargetEditSheet> {
  late int _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTargetMinorUnits;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _target == 0
        ? 0.0
        : (widget.savedSoFarMinorUnits / _target).clamp(0, 1).toDouble();

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
                widget.sheetTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_target),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  widget.goalLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                MoneyText(_target, fontSize: 34),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(widget.savedSoFarMinorUnits, fontSize: 14),
                    Text(widget.progressSuffix),
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
                  () => _target = (_target - widget.stepMinorUnits).clamp(
                    0,
                    1 << 62,
                  ),
                ),
                icon: const Icon(LucideIcons.minus),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _target += widget.stepMinorUnits),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedProgressBar(value: ratio),
        ],
      ),
    );
  }
}
