import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/recurring_rule.dart';

void main() {
  group('RecurringFrequency.next', () {
    test('monthly clamps Jan 31 to Feb 28 instead of drifting into March', () {
      final next = RecurringFrequency.monthly.next(DateTime(2026, 1, 31));
      expect(next, DateTime(2026, 2, 28));
    });

    test('monthly clamps to Feb 29 in a leap year', () {
      final next = RecurringFrequency.monthly.next(DateTime(2028, 1, 31));
      expect(next, DateTime(2028, 2, 29));
    });

    test('monthly keeps mid-month days unchanged', () {
      final next = RecurringFrequency.monthly.next(DateTime(2026, 3, 15));
      expect(next, DateTime(2026, 4, 15));
    });

    test('monthly steps across a year boundary', () {
      final next = RecurringFrequency.monthly.next(DateTime(2026, 12, 31));
      expect(next, DateTime(2027, 1, 31));
    });

    test('yearly clamps Feb 29 to Feb 28 in a non-leap year', () {
      final next = RecurringFrequency.yearly.next(DateTime(2028, 2, 29));
      expect(next, DateTime(2029, 2, 28));
    });

    test('weekly lands exactly 7 calendar days later at midnight', () {
      final next = RecurringFrequency.weekly.next(DateTime(2026, 11, 1));
      expect(next, DateTime(2026, 11, 8));
      expect(next.hour, 0);
    });

    test('biweekly crosses a month boundary correctly', () {
      final next = RecurringFrequency.biweekly.next(DateTime(2026, 1, 25));
      expect(next, DateTime(2026, 2, 8));
    });
  });
}
