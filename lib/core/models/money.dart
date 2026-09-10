String formatMoney(int minorUnits, {bool showSign = false}) {
  final isNegative = minorUnits < 0;
  final absValue = minorUnits.abs();
  final dollars = absValue ~/ 100;
  final cents = (absValue % 100).toString().padLeft(2, '0');
  final withCommas = dollars.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  final sign = isNegative
      ? '-'
      : (showSign && minorUnits > 0)
      ? '+'
      : '';
  return '$sign\$$withCommas.$cents';
}
