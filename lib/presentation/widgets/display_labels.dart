import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/calendar_date_helpers.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter_and_sort.dart';

extension DurationOptionLabel on DurationOption {
  String get label => switch (this) {
    DurationOption.today => 'Today',
    DurationOption.week => 'Week',
    DurationOption.month => 'Month',
    DurationOption.quarter => 'Quarter',
    DurationOption.annual => 'Annual',
    DurationOption.tillDate => 'Till Date',
    DurationOption.dateRange => 'Date Range',
  };
}

extension DurationFilterLabel on DurationFilter {
  String get label {
    if (option != DurationOption.dateRange) return option.label;
    final fmt = DateFormat('d MMM');
    final start = customStart!, end = customEnd!;
    return start.isSameDay(end)
        ? fmt.format(start)
        : '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

extension TaskDisplayStatusLabel on TaskDisplayStatus {
  String get label => switch (this) {
    TaskDisplayStatus.open => 'Open',
    TaskDisplayStatus.overdue => 'Overdue',
    TaskDisplayStatus.closed => 'Closed',
  };
}

extension TaskSortOrderLabel on TaskSortOrder {
  String get label => switch (this) {
    TaskSortOrder.dueSoonest => 'Due date: soonest first',
    TaskSortOrder.dueLatest => 'Due date: latest first',
    TaskSortOrder.newest => 'Created: newest first',
    TaskSortOrder.oldest => 'Created: oldest first',
    TaskSortOrder.titleAz => 'Title: A to Z',
  };
}

extension DueDateFilterLabel on DueDateFilter {
  String get label => switch (this) {
    DueDateFilter.any => 'Any',
    DueDateFilter.withDueDate => 'Has due date',
    DueDateFilter.withoutDueDate => 'No due date',
  };
}

String formatDueDateRelativeToToday(DateTime due, DateTime now) {
  final time = DateFormat('h:mma').format(due);
  final days = now.calendarDaysUntil(due);
  if (days == 0) return 'Today $time';
  if (days == 1) return 'Tomorrow $time';
  if (days == -1) return 'Yesterday $time';
  if (due.year == now.year) return '${DateFormat('d MMM').format(due)} $time';
  return DateFormat('d MMM y').format(due);
}

String _pluralizeUnit(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

({String text, Color color}) buildTaskStatusLabel(Task task, DateTime now) {
  switch (task.displayStatusAt(now)) {
    case TaskDisplayStatus.closed:
      return (text: 'Closed', color: AppColors.green);
    case TaskDisplayStatus.overdue:
      final late = task.overdueDurationAt(now)!;
      final text = late.inDays >= 1
          ? _pluralizeUnit(late.inDays, 'day')
          : late.inHours >= 1
          ? _pluralizeUnit(late.inHours, 'hr')
          : _pluralizeUnit(late.inMinutes.clamp(1, 59), 'min');
      return (text: 'Overdue $text', color: AppColors.crimson);
    case TaskDisplayStatus.open:
      final due = task.dueAt;
      return due == null
          ? (text: 'No due date', color: AppColors.textMuted)
          : (
              text: formatDueDateRelativeToToday(due, now),
              color: AppColors.blue,
            );
  }
}
