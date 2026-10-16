import '../entities/duration_filter.dart';
import '../entities/task.dart';
import '../entities/task_filter_and_sort.dart';

class TaskListQueryService {
  const TaskListQueryService();

  List<Task> selectTasksForMemberAndDuration(
    Iterable<Task> tasks, {
    required DurationFilter duration,
    required DateTime now,
    String? memberId,
  }) {
    final range = duration.resolveDateRange(now);
    return tasks
        .where((t) => memberId == null || t.assigneeId == memberId)
        .where((t) => range.contains(t.dateUsedForDurationFilter))
        .toList();
  }

  List<Task> applyTaskFilter(Iterable<Task> tasks, TaskFilter filter) =>
      tasks.where((t) {
        if (filter.assigneeIds.isNotEmpty &&
            !filter.assigneeIds.contains(t.assigneeId)) {
          return false;
        }
        return switch (filter.dueDateFilter) {
          DueDateFilter.any => true,
          DueDateFilter.withDueDate => t.dueAt != null,
          DueDateFilter.withoutDueDate => t.dueAt == null,
        };
      }).toList();

  List<Task> sortTasks(Iterable<Task> tasks, TaskSortOrder sort) {
    int byDue(Task a, Task b, {required bool ascending}) {
      final da = a.dueAt, db = b.dueAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return ascending ? da.compareTo(db) : db.compareTo(da);
    }

    int compare(Task a, Task b) => switch (sort) {
      TaskSortOrder.dueSoonest => byDue(a, b, ascending: true),
      TaskSortOrder.dueLatest => byDue(a, b, ascending: false),
      TaskSortOrder.newest => b.createdAt.compareTo(a.createdAt),
      TaskSortOrder.oldest => a.createdAt.compareTo(b.createdAt),
      TaskSortOrder.titleAz => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
    };

    return tasks.toList()..sort((a, b) {
      final comparison = compare(a, b);
      return comparison != 0 ? comparison : a.id.compareTo(b.id);
    });
  }

  Map<TaskDisplayStatus, List<Task>> groupTasksByDisplayStatus(
    Iterable<Task> tasks,
    DateTime now,
  ) {
    final tasksByStatus = {
      for (final status in TaskDisplayStatus.values) status: <Task>[],
    };
    for (final t in tasks) {
      tasksByStatus[t.displayStatusAt(now)]!.add(t);
    }
    return tasksByStatus;
  }
}
