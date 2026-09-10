enum AccountType {
  asset,
  liability;

  String toDb() => name;

  static AccountType fromDb(String value) =>
      AccountType.values.firstWhere((t) => t.name == value);
}

class Account {
  final int id;
  final int profileId;
  final String name;
  final AccountType type;
  final int startingBalanceMinorUnits;
  final bool isActive;
  final int sortOrder;

  const Account({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
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
      startingBalanceMinorUnits: row['starting_balance_minor_units'] as int,
      isActive: row['is_active'] as bool,
      sortOrder: row['sort_order'] as int,
    );
  }
}
