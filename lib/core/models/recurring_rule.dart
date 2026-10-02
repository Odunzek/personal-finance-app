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

  // Calendar stepping has two traps this avoids: DateTime normalizes
  // overflowed days (Jan 31 + 1 month = "Feb 31" = Mar 3, silently skipping
  // February and drifting the anchor forever), so month/year steps clamp the
  // day to the target month's length; and Duration-based day math shifts by
  // an hour across DST, which _dateOnly persistence would then round to the
  // wrong day, so weekly steps use calendar days instead of Durations.
  DateTime next(DateTime from) => switch (this) {
    RecurringFrequency.weekly => DateTime(from.year, from.month, from.day + 7),
    RecurringFrequency.biweekly => DateTime(
      from.year,
      from.month,
      from.day + 14,
    ),
    RecurringFrequency.monthly => _addMonthsClamped(from, 1),
    RecurringFrequency.yearly => _addMonthsClamped(from, 12),
  };

  static DateTime _addMonthsClamped(DateTime from, int months) {
    final targetMonth = DateTime(from.year, from.month + months, 1);
    final daysInTarget = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      from.day > daysInTarget ? daysInTarget : from.day,
    );
  }
}

class RecurringRule {
  final int id;
  final int profileId;
  final int accountId;
  final int? categoryId;
  final int? toAccountId;
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
    required this.toAccountId,
    required this.type,
    required this.amountMinorUnits,
    required this.frequency,
    required this.nextDueDate,
    required this.note,
    required this.isActive,
  });

  bool get isTransfer => type == TransactionKind.transfer;

  factory RecurringRule.fromRow(Map<String, dynamic> row) {
    return RecurringRule(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      accountId: row['account_id'] as int,
      categoryId: row['category_id'] as int?,
      toAccountId: row['to_account_id'] as int?,
      type: TransactionKind.fromDb(row['type'] as String),
      amountMinorUnits: row['amount_minor_units'] as int,
      frequency: RecurringFrequency.fromDb(row['frequency'] as String),
      nextDueDate: DateTime.parse(row['next_due_date'] as String),
      note: row['note'] as String?,
      isActive: row['is_active'] as bool,
    );
  }
}
