extension CalendarDateHelpers on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get startOfNextDay => DateTime(year, month, day + 1);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  int calendarDaysUntil(DateTime other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;
}
