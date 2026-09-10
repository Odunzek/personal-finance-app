class Budget {
  final int id;
  final int profileId;
  final int categoryId;
  final int limitMinorUnits;
  final DateTime month;

  const Budget({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.limitMinorUnits,
    required this.month,
  });

  factory Budget.fromRow(Map<String, dynamic> row) {
    return Budget(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      categoryId: row['category_id'] as int,
      limitMinorUnits: row['limit_minor_units'] as int,
      month: DateTime.parse(row['month'] as String),
    );
  }
}

class SavingsTarget {
  final int id;
  final int profileId;
  final int targetMinorUnits;
  final DateTime month;

  const SavingsTarget({
    required this.id,
    required this.profileId,
    required this.targetMinorUnits,
    required this.month,
  });

  factory SavingsTarget.fromRow(Map<String, dynamic> row) {
    return SavingsTarget(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      targetMinorUnits: row['target_minor_units'] as int,
      month: DateTime.parse(row['month'] as String),
    );
  }
}

/// A savings goal for a whole calendar year — set and viewed independently
/// per year, unrelated to any other year's goal or to the monthly
/// [SavingsTarget].
class SavingsGoal {
  final int id;
  final int profileId;
  final int year;
  final int targetMinorUnits;

  const SavingsGoal({
    required this.id,
    required this.profileId,
    required this.year,
    required this.targetMinorUnits,
  });

  factory SavingsGoal.fromRow(Map<String, dynamic> row) {
    return SavingsGoal(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      year: row['year'] as int,
      targetMinorUnits: row['target_minor_units'] as int,
    );
  }
}
