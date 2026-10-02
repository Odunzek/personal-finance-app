/// Distinct from [CategoryType] (which only ever describes a category) —
/// a transaction can also be a transfer between two of the user's own
/// accounts, which has no category and never counts as income or expense.
enum TransactionKind {
  income,
  expense,
  transfer;

  String toDb() => name;

  static TransactionKind fromDb(String value) =>
      TransactionKind.values.firstWhere((t) => t.name == value);
}

class Transaction {
  final int id;
  final int profileId;
  final int accountId;
  final int? categoryId;
  final int? transferAccountId;
  final int amountMinorUnits;
  final TransactionKind type;
  final DateTime occurredAt;
  final String? note;
  final int? recurringRuleId;

  const Transaction({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.transferAccountId,
    required this.amountMinorUnits,
    required this.type,
    required this.occurredAt,
    this.note,
    this.recurringRuleId,
  });

  bool get isTransfer => type == TransactionKind.transfer;
  bool get isRecurring => recurringRuleId != null;

  /// [categoryId] and [transferAccountId] are passed explicitly rather than
  /// defaulted, because converting between a transfer and an income/expense
  /// has to be able to set either one back to null.
  Transaction copyWith({
    int? accountId,
    required int? categoryId,
    required int? transferAccountId,
    int? amountMinorUnits,
    TransactionKind? type,
    DateTime? occurredAt,
    String? note,
  }) {
    return Transaction(
      id: id,
      profileId: profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId,
      transferAccountId: transferAccountId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      recurringRuleId: recurringRuleId,
    );
  }

  factory Transaction.fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      accountId: row['account_id'] as int,
      categoryId: row['category_id'] as int?,
      transferAccountId: row['transfer_account_id'] as int?,
      amountMinorUnits: row['amount_minor_units'] as int,
      type: TransactionKind.fromDb(row['type'] as String),
      occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
      note: row['note'] as String?,
      recurringRuleId: row['recurring_rule_id'] as int?,
    );
  }
}
