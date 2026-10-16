import 'dart:math';

import '../../core/error/app_exception.dart';
import '../entities/duration_filter.dart';
import '../entities/task.dart';
import '../entities/task_draft.dart';
import '../entities/task_filter_and_sort.dart';
import '../entities/task_stats.dart';
import '../repositories/repository_contracts.dart';
import '../services/clock.dart';
import '../services/task_list_query_service.dart';

const _taskQuery = TaskListQueryService();

class GetTaskCountsByStatus {
  const GetTaskCountsByStatus(this._tasks, this._clock);

  final TaskRepository _tasks;
  final Clock _clock;

  Future<TaskStats> call({
    required DurationFilter duration,
    String? memberId,
  }) async {
    final now = _clock.now();
    final selected = _taskQuery.selectTasksForMemberAndDuration(
      await _tasks.getTasks(),
      duration: duration,
      now: now,
      memberId: memberId,
    );
    return TaskStats.countByStatus(selected, now);
  }
}

class GetTeamPerformance {
  const GetTeamPerformance(this._tasks, this._team, this._clock);

  final TaskRepository _tasks;
  final TeamRepository _team;
  final Clock _clock;

  Future<List<MemberPerformance>> call(DurationFilter duration) async {
    final now = _clock.now();
    final members = await _team.getMembers();
    final selected = _taskQuery.selectTasksForMemberAndDuration(
      await _tasks.getTasks(),
      duration: duration,
      now: now,
    );
    return MemberPerformance.forEachMember(members, selected, now);
  }
}

class GetFilteredTasksGroupedByStatus {
  const GetFilteredTasksGroupedByStatus(this._tasks, this._clock);

  final TaskRepository _tasks;
  final Clock _clock;

  Future<Map<TaskDisplayStatus, List<Task>>> call({
    required DurationFilter duration,
    required TaskFilter filter,
    required TaskSortOrder sort,
    String? memberId,
    DateTime? now,
  }) async {
    now ??= _clock.now();
    final selected = _taskQuery.selectTasksForMemberAndDuration(
      await _tasks.getTasks(),
      duration: duration,
      now: now,
      memberId: memberId,
    );
    final sorted = _taskQuery.sortTasks(
      _taskQuery.applyTaskFilter(selected, filter),
      sort,
    );
    return _taskQuery.groupTasksByDisplayStatus(sorted, now);
  }
}

class UpdateTaskClosedStatus {
  const UpdateTaskClosedStatus(this._tasks, this._clock);

  final TaskRepository _tasks;
  final Clock _clock;

  Future<Task> call(Task task, {required bool closed}) async {
    if (task.isClosed == closed) return task;
    final updated = closed ? task.close(_clock.now()) : task.reopen();
    await _tasks.saveTask(updated);
    return updated;
  }
}

class CreateTask {
  CreateTask(this._tasks, this._team, this._auth, this._clock, {Random? random})
    : _random = random ?? Random();

  final TaskRepository _tasks;
  final TeamRepository _team;
  final AuthRepository _auth;
  final Clock _clock;
  final Random _random;

  Future<Task> call(TaskDraft draft) async {
    final user = await _auth.getCurrentUser();
    if (!user.canCreateTasks) {
      throw const PermissionDeniedException(
        'Only admins can create and assign tasks.',
      );
    }

    final now = _clock.now();
    final members = await _team.getMembers();
    final errors = draft.validate(
      memberIds: {for (final m in members) m.id},
      now: now,
    );
    if (errors.isNotEmpty) throw TaskValidationException(errors);

    final existingIds = {for (final t in await _tasks.getTasks()) t.id};
    String id;
    do {
      id =
          'task_${now.microsecondsSinceEpoch.toRadixString(36)}'
          '_${_random.nextInt(1 << 32).toRadixString(36)}';
    } while (existingIds.contains(id));

    final description = draft.description.trim();
    final task = Task(
      id: id,
      title: draft.title.trim(),
      assigneeId: draft.assigneeId!,
      createdAt: now,
      description: description.isEmpty ? null : description,
      dueAt: draft.dueAt,
    );
    await _tasks.saveTask(task);
    return task;
  }
}
