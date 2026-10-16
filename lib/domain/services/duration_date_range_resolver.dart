import '../../core/utils/calendar_date_helpers.dart';
import '../entities/duration_filter.dart';

class DurationDateRangeResolver {
  const DurationDateRangeResolver();

  DateRange resolveDateRange(DurationFilter filter, DateTime now) {
    final today = now.startOfDay;
    switch (filter.option) {
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
        final start = filter.customStart ?? today;
        final end = filter.customEnd ?? today;
        return DateRange(start: start, end: end.startOfNextDay);
    }
  }
}
