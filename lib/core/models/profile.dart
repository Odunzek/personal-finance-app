/// Decides which default categories get seeded when the profile is
/// created, and how it's labeled elsewhere — otherwise not load-bearing.
enum ProfileType {
  personal,
  business;

  String toDb() => name;

  static ProfileType fromDb(String value) =>
      ProfileType.values.firstWhere((t) => t.name == value);
}

class Profile {
  final int id;
  final String displayName;
  final String currencyCode;
  final int sortOrder;
  final ProfileType type;

  const Profile({
    required this.id,
    required this.displayName,
    required this.currencyCode,
    required this.sortOrder,
    this.type = ProfileType.personal,
  });

  factory Profile.fromRow(Map<String, dynamic> row) {
    return Profile(
      id: row['id'] as int,
      displayName: row['display_name'] as String,
      currencyCode: row['currency_code'] as String,
      sortOrder: row['sort_order'] as int,
      type: ProfileType.fromDb(row['profile_type'] as String? ?? 'personal'),
    );
  }
}
