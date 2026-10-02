enum AccountType {
  asset,
  liability;

  String toDb() => name;

  static AccountType fromDb(String value) =>
      AccountType.values.firstWhere((t) => t.name == value);
}

/// A liability account's kind, purely for labeling/grouping — every kind is
/// summed identically into net worth and the debt-owed trend.
enum DebtKind {
  creditCard,
  loan,
  bnpl,
  shareholderLoan,
  other;

  String toDb() => switch (this) {
    DebtKind.creditCard => 'credit_card',
    DebtKind.loan => 'loan',
    DebtKind.bnpl => 'bnpl',
    DebtKind.shareholderLoan => 'shareholder_loan',
    DebtKind.other => 'other',
  };

  static DebtKind fromDb(String value) => switch (value) {
    'credit_card' => DebtKind.creditCard,
    'loan' => DebtKind.loan,
    'bnpl' => DebtKind.bnpl,
    'shareholder_loan' => DebtKind.shareholderLoan,
    _ => DebtKind.other,
  };

  String get label => switch (this) {
    DebtKind.creditCard => 'Credit card',
    DebtKind.loan => 'Loan',
    DebtKind.bnpl => 'Buy now, pay later',
    DebtKind.shareholderLoan => 'Shareholder loan',
    DebtKind.other => 'Other debt',
  };
}

class Account {
  final int id;
  final int profileId;
  final String name;
  final AccountType type;
  final DebtKind? debtKind;
  final int startingBalanceMinorUnits;
  final bool isActive;
  final int sortOrder;

  const Account({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.debtKind,
    required this.startingBalanceMinorUnits,
    required this.isActive,
    required this.sortOrder,
  });

  factory Account.fromRow(Map<String, dynamic> row) {
    return Account(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      name: row['name'] as String,
      type: AccountType.fromDb(row['type'] as String),
      debtKind: row['debt_kind'] == null
          ? null
          : DebtKind.fromDb(row['debt_kind'] as String),
      startingBalanceMinorUnits: row['starting_balance_minor_units'] as int,
      isActive: row['is_active'] as bool,
      sortOrder: row['sort_order'] as int,
    );
  }
}
