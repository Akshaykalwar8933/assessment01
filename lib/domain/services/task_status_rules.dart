import '../entities/task.dart';

extension TaskStatusRules on Task {
  /// Overdue is derived: an open task whose due date has passed.
  TaskDisplayStatus displayStatusAt(DateTime now) {
    if (isClosed) return TaskDisplayStatus.closed;
    final due = dueAt;
    if (due != null && due.isBefore(now)) return TaskDisplayStatus.overdue;
    return TaskDisplayStatus.open;
  }

  /// The date used to place a task inside a duration window: completion date
  /// for closed tasks, due date for open ones, creation date as fallback.
  DateTime get dateUsedForDurationFilter =>
      (isClosed ? completedAt : dueAt) ?? createdAt;

  /// How long past due an open task is, or null if it is not overdue.
  Duration? overdueDurationAt(DateTime now) =>
      displayStatusAt(now) == TaskDisplayStatus.overdue
      ? now.difference(dueAt!)
      : null;
}
