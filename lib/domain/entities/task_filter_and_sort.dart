enum DueDateFilter { any, withDueDate, withoutDueDate }

enum TaskSortOrder { dueSoonest, dueLatest, newest, oldest, titleAz }

class TaskFilter {
  const TaskFilter({
    this.assigneeIds = const {},
    this.dueDateFilter = DueDateFilter.any,
  });

  static const TaskFilter noFilters = TaskFilter();

  final Set<String> assigneeIds;
  final DueDateFilter dueDateFilter;

  int get activeFilterCount =>
      (assigneeIds.isEmpty ? 0 : 1) +
      (dueDateFilter == DueDateFilter.any ? 0 : 1);

  TaskFilter copyWith({
    Set<String>? assigneeIds,
    DueDateFilter? dueDateFilter,
  }) => TaskFilter(
    assigneeIds: assigneeIds ?? this.assigneeIds,
    dueDateFilter: dueDateFilter ?? this.dueDateFilter,
  );
}
