class Profile {
  final int id;
  final String displayName;
  final String currencyCode;
  final int sortOrder;

  const Profile({
    required this.id,
    required this.displayName,
    required this.currencyCode,
    required this.sortOrder,
  });

  factory Profile.fromRow(Map<String, dynamic> row) {
    return Profile(
      id: row['id'] as int,
      displayName: row['display_name'] as String,
      currencyCode: row['currency_code'] as String,
      sortOrder: row['sort_order'] as int,
    );
  }
}
