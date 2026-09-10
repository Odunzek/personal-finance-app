import 'transaction.dart';

enum RecurringFrequency {
  weekly,
  biweekly,
  monthly,
  yearly;

  String toDb() => name;

  static RecurringFrequency fromDb(String value) =>
      RecurringFrequency.values.firstWhere((f) => f.name == value);

  String get label => switch (this) {
    RecurringFrequency.weekly => 'Weekly',
    RecurringFrequency.biweekly => 'Every 2 weeks',
    RecurringFrequency.monthly => 'Monthly',
    RecurringFrequency.yearly => 'Yearly',
  };

  DateTime next(DateTime from) => switch (this) {
    RecurringFrequency.weekly => from.add(const Duration(days: 7)),
    RecurringFrequency.biweekly => from.add(const Duration(days: 14)),
    RecurringFrequency.monthly => DateTime(from.year, from.month + 1, from.day),
    RecurringFrequency.yearly => DateTime(from.year + 1, from.month, from.day),
  };
}

class RecurringRule {
  final int id;
  final int profileId;
  final int accountId;
  final int categoryId;
  final TransactionKind type;
  final int amountMinorUnits;
  final RecurringFrequency frequency;
  final DateTime nextDueDate;
  final String? note;
  final bool isActive;

  const RecurringRule({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amountMinorUnits,
    required this.frequency,
    required this.nextDueDate,
    required this.note,
    required this.isActive,
  });

  factory RecurringRule.fromRow(Map<String, dynamic> row) {
    return RecurringRule(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      accountId: row['account_id'] as int,
      categoryId: row['category_id'] as int,
      type: TransactionKind.fromDb(row['type'] as String),
      amountMinorUnits: row['amount_minor_units'] as int,
      frequency: RecurringFrequency.fromDb(row['frequency'] as String),
      nextDueDate: DateTime.parse(row['next_due_date'] as String),
      note: row['note'] as String?,
      isActive: row['is_active'] as bool,
    );
  }
}
