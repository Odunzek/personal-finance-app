/// Parses user-typed dollars ("12", "12.5", "12.50") into integer minor
/// units, or null when the input isn't a plain positive amount with at most
/// two decimals — so "12.345" is rejected instead of silently rounded, and
/// every amount field across the app validates identically.
int? parseMoneyMinorUnits(String input) {
  final text = input.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final dollars = int.parse(parts[0]);
  final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  return dollars * 100 + cents;
}

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
