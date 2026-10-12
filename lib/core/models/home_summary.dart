import 'account.dart';
import 'account_balance.dart';
import 'transaction.dart';

/// The figures behind the Home headline.
///
/// The headline is what's spendable today rather than net worth: net worth is
/// the honest long-run number, but with debt outstanding it is permanently
/// negative and reads as a verdict rather than something to act on. It stays
/// available in Trends and Accounts.
class HomeSummary {
  /// Asset accounts only — cash and chequing. Never offset by debt.
  final int availableMinorUnits;

  /// What's owed across liability accounts, as a positive number.
  final int owedMinorUnits;

  /// How much the debt shrank this month. Negative when it grew.
  final int debtPaidThisMonthMinorUnits;

  const HomeSummary({
    required this.availableMinorUnits,
    required this.owedMinorUnits,
    required this.debtPaidThisMonthMinorUnits,
  });

  bool get hasDebt => owedMinorUnits > 0;
  bool get debtGrewThisMonth => debtPaidThisMonthMinorUnits < 0;

  /// Net worth — assets minus debt. Not the headline, but still the truth.
  int get netWorthMinorUnits => availableMinorUnits - owedMinorUnits;

  static HomeSummary of(
    List<Account> accounts,
    List<Transaction> allTransactions,
    DateTime monthStart,
  ) {
    var available = 0;
    var owed = 0;
    var owedAtMonthStart = 0;

    final beforeThisMonth = allTransactions
        .where((t) => t.occurredAt.isBefore(monthStart))
        .toList();

    for (final account in accounts) {
      if (account.type == AccountType.asset) {
        available += computeAccountBalance(account, allTransactions);
        continue;
      }
      // A liability's balance is negative, so owing more makes it smaller.
      owed -= computeAccountBalance(account, allTransactions);
      owedAtMonthStart -= computeAccountBalance(account, beforeThisMonth);
    }

    return HomeSummary(
      availableMinorUnits: available,
      owedMinorUnits: owed,
      // The change in what's owed, not the payments made: new charges count
      // against it too, so a month that borrowed more than it repaid says so
      // instead of claiming progress.
      debtPaidThisMonthMinorUnits: owedAtMonthStart - owed,
    );
  }
}
