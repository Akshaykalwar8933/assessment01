import 'dart:async';

import 'package:get/get.dart';

import '../../core/error/error_reporting.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter_and_sort.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/repository_contracts.dart';
import '../../domain/services/clock.dart';
import '../../domain/usecases/task_usecases.dart';
import 'screen_load_status.dart';

class TeamTasksController extends GetxController {
  TeamTasksController({
    required GetFilteredTasksGroupedByStatus getFilteredTasksGroupedByStatus,
    required UpdateTaskClosedStatus updateTaskClosedStatus,
    required TaskRepository taskRepository,
    required TeamRepository teamRepository,
    required Clock clock,
    TeamTasksArgs args = const TeamTasksArgs(),
  }) : _getFilteredTasksGroupedByStatus = getFilteredTasksGroupedByStatus,
       _taskRepository = taskRepository,
       _teamRepository = teamRepository,
       _clock = clock,
       _updateTaskClosedStatus = updateTaskClosedStatus,
       initialStatusTab = args.initialStatusTab,
       memberId = args.memberId,
       selectedDuration = args.duration.obs;

  final GetFilteredTasksGroupedByStatus _getFilteredTasksGroupedByStatus;
  final UpdateTaskClosedStatus _updateTaskClosedStatus;
  final TaskRepository _taskRepository;
  final TeamRepository _teamRepository;
  final Clock _clock;
  StreamSubscription<void>? _taskChangesSubscription;

  final TaskDisplayStatus initialStatusTab;

  final String? memberId;

  final Rx<DurationFilter> selectedDuration;
  final loadStatus = ScreenLoadStatus.loading.obs;
  final errorMessage = ''.obs;
  final activeFilter = TaskFilter.noFilters.obs;
  final sortOrder = TaskSortOrder.dueSoonest.obs;
  final membersById = <String, TeamMember>{}.obs;
  final tasksByStatus = <TaskDisplayStatus, List<Task>>{}.obs;

  final tasksLoadedAt = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _taskChangesSubscription = _taskRepository.watchTaskChanges().listen(
      (_) => loadTasks(showLoader: false),
    );
    loadTasks();
  }

  @override
  void onClose() {
    _taskChangesSubscription?.cancel();
    super.onClose();
  }

  List<Task> tasksForStatus(TaskDisplayStatus status) =>
      tasksByStatus[status] ?? const [];

  TeamMember? findMemberById(String id) => membersById[id];

  Future<void> loadTasks({bool showLoader = true}) async {
    if (showLoader) loadStatus.value = ScreenLoadStatus.loading;
    try {
      if (membersById.isEmpty) {
        membersById.assignAll({
          for (final m in await _teamRepository.getMembers()) m.id: m,
        });
      }
      final now = _clock.now();
      tasksByStatus.assignAll(
        await _getFilteredTasksGroupedByStatus(
          now: now,
          duration: selectedDuration.value,
          filter: activeFilter.value,
          sort: sortOrder.value,
          memberId: memberId,
        ),
      );
      tasksLoadedAt.value = now;
      loadStatus.value = ScreenLoadStatus.success;
    } catch (error, stackTrace) {
      errorMessage.value = userFacingMessageFor(error, stackTrace);
      loadStatus.value = ScreenLoadStatus.error;
    }
  }

  Future<void> applyFilters({
    required TaskFilter filter,
    required DurationFilter duration,
  }) async {
    activeFilter.value = filter;
    selectedDuration.value = duration;
    await loadTasks();
  }

  Future<void> clearFilters() async {
    activeFilter.value = TaskFilter.noFilters;
    await loadTasks();
  }

  Future<void> changeSortOrder(TaskSortOrder value) async {
    if (value == sortOrder.value) return;
    sortOrder.value = value;
    await loadTasks(showLoader: false);
  }

  Future<void> updateTaskClosedStatus(Task task, {required bool closed}) async {
    try {
      // The task-change stream refreshes the lists.
      await _updateTaskClosedStatus(task, closed: closed);
    } catch (error, stackTrace) {
      showErrorSnackbar(
        userFacingMessageFor(error, stackTrace),
        title: 'Update failed',
      );
    }
  }
}
