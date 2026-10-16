import 'dart:async';

import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter_and_sort.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/services/clock.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/usecases/team_usecases.dart';
import 'screen_load_status.dart';

class TeamTasksController extends GetxController {
  TeamTasksController({
    required GetFilteredTasksGroupedByStatus getFilteredTasksGroupedByStatus,
    required GetTeamMembers getTeamMembers,
    required UpdateTaskClosedStatus updateTaskClosedStatus,
    required Clock clock,
    required WatchTaskChanges watchTaskChanges,
    TeamTasksArgs args = const TeamTasksArgs(),
  }) : _getFilteredTasksGroupedByStatus = getFilteredTasksGroupedByStatus,
       _watchTaskChanges = watchTaskChanges,
       _clock = clock,
       _getTeamMembers = getTeamMembers,
       _updateTaskClosedStatus = updateTaskClosedStatus,
       initialStatusTab = args.initialStatusTab,
       memberId = args.memberId,
       selectedDuration = args.duration.obs;

  final GetFilteredTasksGroupedByStatus _getFilteredTasksGroupedByStatus;
  final GetTeamMembers _getTeamMembers;
  final UpdateTaskClosedStatus _updateTaskClosedStatus;
  final Clock _clock;
  final WatchTaskChanges _watchTaskChanges;
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
    _taskChangesSubscription = _watchTaskChanges().listen(
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
          for (final m in await _getTeamMembers()) m.id: m,
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
    } on AppException catch (e) {
      errorMessage.value = e.message;
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
    } on AppException catch (e) {
      Get.snackbar('Update failed', e.message);
    }
  }
}
