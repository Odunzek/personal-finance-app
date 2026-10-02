import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/mileage_trip.dart';

void main() {
  group('craMileageDeductionCents', () {
    test('entirely under the 5,000 km tier uses the high rate', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 0, kmThisTrip: 100),
        100 * kCraMileageRateFirst5000Cents,
      );
    });

    test('entirely over the tier uses the low rate', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 6000, kmThisTrip: 100),
        100 * kCraMileageRateAfter5000Cents,
      );
    });

    test('a trip crossing the boundary is split across both rates', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 4950, kmThisTrip: 100),
        50 * kCraMileageRateFirst5000Cents + 50 * kCraMileageRateAfter5000Cents,
      );
    });

    test('exactly reaching 5,000 km stays entirely at the high rate', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 4900, kmThisTrip: 100),
        100 * kCraMileageRateFirst5000Cents,
      );
    });

    test('starting exactly at 5,000 km is entirely at the low rate', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 5000, kmThisTrip: 100),
        100 * kCraMileageRateAfter5000Cents,
      );
    });

    test('fractional kilometers round to the nearest cent', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 0, kmThisTrip: 12.3),
        (12.3 * kCraMileageRateFirst5000Cents).round(),
      );
    });

    test('zero-length trip deducts nothing', () {
      expect(
        craMileageDeductionCents(kmAlreadyThisYear: 1234, kmThisTrip: 0),
        0,
      );
    });

    test('sum of split trips equals one combined trip across the tier', () {
      final combined = craMileageDeductionCents(
        kmAlreadyThisYear: 4000,
        kmThisTrip: 2000,
      );
      final first = craMileageDeductionCents(
        kmAlreadyThisYear: 4000,
        kmThisTrip: 1000,
      );
      final second = craMileageDeductionCents(
        kmAlreadyThisYear: 5000,
        kmThisTrip: 1000,
      );
      expect(first + second, combined);
    });
  });
}
