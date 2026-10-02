import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/models/money.dart';

void main() {
  group('parseMoneyMinorUnits', () {
    test('parses whole dollars', () {
      expect(parseMoneyMinorUnits('12'), 1200);
      expect(parseMoneyMinorUnits('0'), 0);
    });

    test('parses one and two decimal places', () {
      expect(parseMoneyMinorUnits('12.5'), 1250);
      expect(parseMoneyMinorUnits('12.50'), 1250);
      expect(parseMoneyMinorUnits('0.07'), 7);
    });

    test('trims surrounding whitespace', () {
      expect(parseMoneyMinorUnits(' 12.50 '), 1250);
    });

    test('rejects more than two decimals instead of rounding', () {
      expect(parseMoneyMinorUnits('12.345'), isNull);
    });

    test('rejects non-numeric, negative, and malformed input', () {
      expect(parseMoneyMinorUnits(''), isNull);
      expect(parseMoneyMinorUnits('abc'), isNull);
      expect(parseMoneyMinorUnits('-5'), isNull);
      expect(parseMoneyMinorUnits('12.'), isNull);
      expect(parseMoneyMinorUnits('.50'), isNull);
      expect(parseMoneyMinorUnits('1,000'), isNull);
      expect(parseMoneyMinorUnits('12.5.0'), isNull);
    });
  });

  group('formatMoney', () {
    test('formats with thousands separators and two decimals', () {
      expect(formatMoney(123456789), '\$1,234,567.89');
      expect(formatMoney(0), '\$0.00');
      expect(formatMoney(5), '\$0.05');
    });

    test('negative amounts always carry a minus', () {
      expect(formatMoney(-1250), '-\$12.50');
      expect(formatMoney(-1250, showSign: true), '-\$12.50');
    });

    test('showSign adds a plus only for positive amounts', () {
      expect(formatMoney(1250, showSign: true), '+\$12.50');
      expect(formatMoney(0, showSign: true), '\$0.00');
    });

    test('round-trips with parseMoneyMinorUnits', () {
      const cents = 987654;
      expect(parseMoneyMinorUnits('9876.54'), cents);
      expect(formatMoney(cents), '\$9,876.54');
    });
  });
}
