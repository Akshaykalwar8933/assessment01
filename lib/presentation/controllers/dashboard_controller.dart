import 'dart:async';

import 'package:get/get.dart';

import '../../core/error/error_reporting.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_stats.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/repositories/repository_contracts.dart';
import 'session_controller.dart';
import 'screen_load_status.dart';

enum TaskScope { myTasks, teams }

class DashboardController extends GetxController {
  DashboardController({
    required TaskRepository taskRepository,
    required TeamRepository teamRepository,
    required PortfolioRepository portfolioRepository,
    required GetTaskCountsByStatus getTaskCountsByStatus,
    required this.session,
  }) : _taskRepository = taskRepository,
       _teamRepository = teamRepository,
       _portfolioRepository = portfolioRepository,
       _getTaskCountsByStatus = getTaskCountsByStatus;

  final TaskRepository _taskRepository;
  final TeamRepository _teamRepository;
  final PortfolioRepository _portfolioRepository;
  final GetTaskCountsByStatus _getTaskCountsByStatus;
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
    _taskChangesSubscription = _taskRepository.watchTaskChanges().listen(
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
      final loadedMembers = await _teamRepository.getMembers();
      final savedId = await _teamRepository.getSelectedMemberId();
      final summary = await _portfolioRepository.getPortfolioSummary();
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
    } catch (error, stackTrace) {
      _showLoadError(userFacingMessageFor(error, stackTrace));
    }
  }

  Future<void> refreshTaskCounts() async {
    try {
      taskCounts.value = await _fetchTaskCounts();
    } catch (error, stackTrace) {
      _showLoadError(userFacingMessageFor(error, stackTrace));
    }
  }

  Future<void> selectTeamMember(TeamMember member) async {
    if (!canSelectMember || member == selectedMember.value) return;
    selectedMember.value = member;
    try {
      await _teamRepository.saveSelectedMemberId(member.id);
    } catch (error, stackTrace) {
      showErrorSnackbar(
        userFacingMessageFor(error, stackTrace),
        title: 'Selection not saved',
      );
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
      arguments: selectedDuration.value,
    );
  }

  Future<TaskStats> _fetchTaskCounts() => _getTaskCountsByStatus(
    duration: selectedDuration.value,
    memberId: _memberIdForSelectedScope,
  );

  void _showLoadError(String message) {
    errorMessage.value = message;
    loadStatus.value = ScreenLoadStatus.error;
  }
}
