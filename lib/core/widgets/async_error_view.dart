import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What a FutureBuilder shows when its future fails — previously every
/// screen checked only `hasData`, so a network failure left an infinite
/// spinner with no message and no way to retry.
class AsyncErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const AsyncErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Couldn\'t load this right now.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.cloudOff,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a failure snackbar for a user-initiated action (save, delete,
/// export) that threw — call from a catch block, after a mounted check.
///
/// Deliberately doesn't blame the connection: a write can also be refused by
/// the database, and saying "check your connection" for that sends people
/// looking in the wrong place. It does say the thing did not save, which is
/// the part that matters.
void showActionError(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('$what didn\'t go through — nothing was saved.'),
    ),
  );
}

/// Confirms an action that succeeded, or explains why one isn't available —
/// the neutral counterpart to [showActionError].
void showActionHint(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      content: Text(message),
    ),
  );
}
