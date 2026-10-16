import 'dart:async';

import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_stats.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/usecases/team_usecases.dart';
import 'session_controller.dart';
import 'screen_load_status.dart';

enum TaskScope { myTasks, teams }

class DashboardController extends GetxController {
  DashboardController({
    required GetTeamMembers getTeamMembers,
    required GetSavedSelectedMemberId getSavedSelectedMemberId,
    required SaveSelectedMemberId saveSelectedMemberId,
    required GetPortfolioSummary getPortfolioSummary,
    required GetTaskCountsByStatus getTaskCountsByStatus,
    required WatchTaskChanges watchTaskChanges,
    required this.session,
  }) : _getTeamMembers = getTeamMembers,
       _watchTaskChanges = watchTaskChanges,
       _getSavedSelectedMemberId = getSavedSelectedMemberId,
       _saveSelectedMemberId = saveSelectedMemberId,
       _getPortfolioSummary = getPortfolioSummary,
       _getTaskCountsByStatus = getTaskCountsByStatus;

  final GetTeamMembers _getTeamMembers;
  final GetSavedSelectedMemberId _getSavedSelectedMemberId;
  final SaveSelectedMemberId _saveSelectedMemberId;
  final GetPortfolioSummary _getPortfolioSummary;
  final GetTaskCountsByStatus _getTaskCountsByStatus;
  final WatchTaskChanges _watchTaskChanges;
  final SessionController session;

  StreamSubscription<void>? _taskChangesSubscription;
  Worker? _currentUserChangeWorker;

  final loadStatus = ScreenLoadStatus.loading.obs;
  final errorMessage = ''.obs;
  final teamMembers = <TeamMember>[].obs;
  final selectedMember = Rxn<TeamMember>();
  final taskScope = TaskScope.teams.obs;
  final selectedDuration = DurationFilter.today.obs;
  final taskCounts = TaskStats.empty.obs;
  final portfolioSummary = Rxn<PortfolioSummary>();

  String? get _memberIdForSelectedScope =>
      taskScope.value == TaskScope.myTasks ? selectedMember.value?.id : null;

  bool get canSelectMember => session.isAdmin;

  @override
  void onInit() {
    super.onInit();
    // Any task change (created, closed, reopened) refreshes the counts.
    _taskChangesSubscription = _watchTaskChanges().listen(
      (_) => refreshTaskCounts(),
    );
    _currentUserChangeWorker = ever(
      session.currentUser,
      (_) => loadDashboard(),
    );
    loadDashboard();
  }

  @override
  void onClose() {
    _taskChangesSubscription?.cancel();
    _currentUserChangeWorker?.dispose();
    super.onClose();
  }

  Future<void> loadDashboard() async {
    loadStatus.value = ScreenLoadStatus.loading;
    try {
      final loadedMembers = await _getTeamMembers();
      final savedId = await _getSavedSelectedMemberId();
      final summary = await _getPortfolioSummary();
      teamMembers.assignAll(loadedMembers);
      final user = session.currentUser.value;
      if (user != null && !user.isAdmin) {
        // A team member is pinned to their own tasks.
        selectedMember.value = loadedMembers.firstWhereOrNull(
          (m) => m.id == user.memberId,
        );
        taskScope.value = TaskScope.myTasks;
      } else {
        selectedMember.value =
            loadedMembers.firstWhereOrNull((m) => m.id == savedId) ??
            loadedMembers.firstOrNull;
      }
      portfolioSummary.value = summary;
      taskCounts.value = await _fetchTaskCounts();
      loadStatus.value = ScreenLoadStatus.success;
    } on AppException catch (e) {
      _showLoadError(e);
    }
  }

  Future<void> refreshTaskCounts() async {
    try {
      taskCounts.value = await _fetchTaskCounts();
    } on AppException catch (e) {
      _showLoadError(e);
    }
  }

  Future<void> selectTeamMember(TeamMember member) async {
    if (!canSelectMember || member == selectedMember.value) return;
    selectedMember.value = member;
    try {
      await _saveSelectedMemberId(member.id);
    } on AppException catch (e) {
      Get.snackbar('Selection not saved', e.message);
    }
    if (taskScope.value == TaskScope.myTasks) await refreshTaskCounts();
  }

  Future<void> changeTaskScope(TaskScope value) async {
    if (value == taskScope.value) return;
    taskScope.value = value;
    await refreshTaskCounts();
  }

  Future<void> changeDuration(DurationFilter value) async {
    if (value == selectedDuration.value) return;
    selectedDuration.value = value;
    await refreshTaskCounts();
  }

  Future<void> openTeamTasksForStatus(TaskDisplayStatus status) async {
    await Get.toNamed<void>(
      AppRoutes.teamTasks,
      arguments: TeamTasksArgs(
        initialStatusTab: status,
        duration: selectedDuration.value,
        memberId: _memberIdForSelectedScope,
      ),
    );
  }

  Future<void> openTeamPerformance() async {
    await Get.toNamed<void>(
      AppRoutes.teamPerformance,
      arguments: TeamPerformanceArgs(duration: selectedDuration.value),
    );
  }

  Future<TaskStats> _fetchTaskCounts() => _getTaskCountsByStatus(
    duration: selectedDuration.value,
    memberId: _memberIdForSelectedScope,
  );

  void _showLoadError(AppException error) {
    errorMessage.value = error.message;
    loadStatus.value = ScreenLoadStatus.error;
  }
}
