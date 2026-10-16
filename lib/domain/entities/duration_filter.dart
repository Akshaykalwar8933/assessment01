import '../../core/utils/calendar_date_helpers.dart';

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

  /// The concrete date range relative to [now]. Presets are the current
  /// calendar period (weeks start on Monday); "Till Date" is everything up to
  /// the end of today.
  DateRange resolveDateRange(DateTime now) {
    final today = now.startOfDay;
    switch (option) {
      case DurationOption.today:
        return DateRange(start: today, end: now.startOfNextDay);
      case DurationOption.week:
        final start = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        return DateRange(
          start: start,
          end: DateTime(start.year, start.month, start.day + 7),
        );
      case DurationOption.month:
        return DateRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1),
        );
      case DurationOption.quarter:
        final firstMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateRange(
          start: DateTime(now.year, firstMonth),
          end: DateTime(now.year, firstMonth + 3),
        );
      case DurationOption.annual:
        return DateRange(
          start: DateTime(now.year),
          end: DateTime(now.year + 1),
        );
      case DurationOption.tillDate:
        return DateRange(end: now.startOfNextDay);
      case DurationOption.dateRange:
        final start = customStart ?? today;
        final end = customEnd ?? today;
        return DateRange(start: start, end: end.startOfNextDay);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DurationFilter &&
      other.option == option &&
      other.customStart == customStart &&
      other.customEnd == customEnd;

  @override
  int get hashCode => Object.hash(option, customStart, customEnd);
}
