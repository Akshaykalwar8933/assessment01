enum TaskStatus { open, closed }

enum TaskDisplayStatus { open, overdue, closed }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.createdAt,
    this.description,
    this.dueAt,
    this.status = TaskStatus.open,
    this.completedAt,
  }) : assert(
         (status == TaskStatus.closed) == (completedAt != null),
         'A closed task must have a completion date and an open one must not.',
       );

  final String id;
  final String title;
  final String assigneeId;
  final DateTime createdAt;
  final String? description;
  final DateTime? dueAt;
  final TaskStatus status;
  final DateTime? completedAt;

  bool get isClosed => status == TaskStatus.closed;

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

  Task close(DateTime at) => Task(
    id: id,
    title: title,
    assigneeId: assigneeId,
    createdAt: createdAt,
    description: description,
    dueAt: dueAt,
    status: TaskStatus.closed,
    completedAt: at,
  );

  Task reopen() => Task(
    id: id,
    title: title,
    assigneeId: assigneeId,
    createdAt: createdAt,
    description: description,
    dueAt: dueAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.assigneeId == assigneeId &&
      other.createdAt == createdAt &&
      other.description == description &&
      other.dueAt == dueAt &&
      other.status == status &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    assigneeId,
    createdAt,
    description,
    dueAt,
    status,
    completedAt,
  );
}
