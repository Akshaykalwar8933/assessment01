enum DurationOption { today, week, month, quarter, annual, tillDate, dateRange }

class DateRange {
  const DateRange({this.start, required this.end});

  final DateTime? start;
  final DateTime end;

  bool contains(DateTime t) =>
      (start == null || !t.isBefore(start!)) && t.isBefore(end);
}

class DurationFilter {
  const DurationFilter._(this.option, this.customStart, this.customEnd);

  const DurationFilter.preset(this.option)
    : assert(option != DurationOption.dateRange, 'Use DurationFilter.custom'),
      customStart = null,
      customEnd = null;

  factory DurationFilter.custom(DateTime start, DateTime end) {
    final (from, to) = start.isAfter(end) ? (end, start) : (start, end);
    return DurationFilter._(
      DurationOption.dateRange,
      DateTime(from.year, from.month, from.day),
      DateTime(to.year, to.month, to.day),
    );
  }

  static const DurationFilter today = DurationFilter.preset(
    DurationOption.today,
  );

  final DurationOption option;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) =>
      other is DurationFilter &&
      other.option == option &&
      other.customStart == customStart &&
      other.customEnd == customEnd;

  @override
  int get hashCode => Object.hash(option, customStart, customEnd);
}
