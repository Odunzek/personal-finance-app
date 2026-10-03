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
    balance += signedAmountForAccount(t, account.id);
  }
  return balance;
}

/// True when [t] moves money in or out of [accountId]. A transfer counts from
/// either side, which is why this can't just compare `accountId` — filtering
/// on that alone silently drops every transfer *into* the account.
bool transactionTouchesAccount(Transaction t, int accountId) =>
    t.accountId == accountId ||
    (t.isTransfer && t.transferAccountId == accountId);

/// What [t] does to [accountId]'s balance: negative for money leaving,
/// positive for money arriving, zero if it doesn't touch this account.
/// [computeAccountBalance] sums exactly this, so a per-account list built on
/// it can never disagree with the balance shown above it.
int signedAmountForAccount(Transaction t, int accountId) {
  if (t.isTransfer) {
    if (t.accountId == accountId) return -t.amountMinorUnits;
    if (t.transferAccountId == accountId) return t.amountMinorUnits;
    return 0;
  }
  if (t.accountId != accountId) return 0;
  return t.type == TransactionKind.income
      ? t.amountMinorUnits
      : -t.amountMinorUnits;
}
