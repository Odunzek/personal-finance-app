class MonthRange {
  final DateTime start;
  final DateTime endExclusive;

  const MonthRange(this.start, this.endExclusive);

  factory MonthRange.of(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return MonthRange(start, end);
  }

  factory MonthRange.current() => MonthRange.of(DateTime.now());

  MonthRange previous() =>
      MonthRange.of(DateTime(start.year, start.month - 1, 1));

  String get label => _monthLabels[start.month - 1];

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
