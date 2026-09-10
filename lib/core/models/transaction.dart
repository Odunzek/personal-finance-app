import 'category.dart';

class Transaction {
  final int id;
  final int profileId;
  final int categoryId;
  final int amountMinorUnits;
  final CategoryType type;
  final DateTime occurredAt;
  final String? note;

  const Transaction({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.amountMinorUnits,
    required this.type,
    required this.occurredAt,
    this.note,
  });

  factory Transaction.fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      categoryId: row['category_id'] as int,
      amountMinorUnits: row['amount_minor_units'] as int,
      type: CategoryType.fromDb(row['type'] as String),
      occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
      note: row['note'] as String?,
    );
  }
}
