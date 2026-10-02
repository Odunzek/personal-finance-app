class MileageTrip {
  final int id;
  final int profileId;
  final DateTime occurredAt;
  final String destination;
  final String? purpose;
  final double kilometers;

  const MileageTrip({
    required this.id,
    required this.profileId,
    required this.occurredAt,
    required this.destination,
    required this.purpose,
    required this.kilometers,
  });

  factory MileageTrip.fromRow(Map<String, dynamic> row) {
    return MileageTrip(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      destination: row['destination'] as String,
      purpose: row['purpose'] as String?,
      kilometers: (row['kilometers'] as num).toDouble(),
    );
  }
}

/// CRA's per-km automobile allowance rate, tiered: a higher rate for the
/// first 5,000 km driven for business in the year, lower after. These are
/// the 2025 rates — CRA publishes updated rates annually, so check
/// https://www.canada.ca (search "automobile allowance rates") each year.
const kCraMileageRateFirst5000Cents = 70;
const kCraMileageRateAfter5000Cents = 64;
const kCraMileageTierKm = 5000.0;

/// The deduction for [kmThisTrip] given [kmAlreadyThisYear] already logged,
/// in cents — split across the 5,000 km tier boundary if this trip crosses
/// it, so a running log always reflects the correct blended rate.
int craMileageDeductionCents({
  required double kmAlreadyThisYear,
  required double kmThisTrip,
}) {
  final remainingAtHighRate = (kCraMileageTierKm - kmAlreadyThisYear).clamp(
    0.0,
    kmThisTrip,
  );
  final atLowRate = kmThisTrip - remainingAtHighRate;
  return (remainingAtHighRate * kCraMileageRateFirst5000Cents +
          atLowRate * kCraMileageRateAfter5000Cents)
      .round();
}
