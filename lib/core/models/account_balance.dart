import 'account.dart';
import 'transaction.dart';

/// The running balance for one account: starting balance, plus income,
/// minus expense, minus transfers out, plus transfers in. A liability
/// account's starting balance is stored as a negative number (existing
/// debt), so this same formula works for both account types — net worth is
/// just the sum of every account's balance.
int computeAccountBalance(Account account, List<Transaction> allTransactions) {
  var balance = account.startingBalanceMinorUnits;
  for (final t in allTransactions) {
    if (t.isTransfer) {
      if (t.accountId == account.id) balance -= t.amountMinorUnits;
      if (t.transferAccountId == account.id) balance += t.amountMinorUnits;
    } else if (t.accountId == account.id) {
      balance += t.type == TransactionKind.income
          ? t.amountMinorUnits
          : -t.amountMinorUnits;
    }
  }
  return balance;
}
