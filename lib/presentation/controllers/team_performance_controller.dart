import 'dart:async';

import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/task_stats.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/usecases/task_usecases.dart';
import 'screen_load_status.dart';

class TeamPerformanceController extends GetxController {
  TeamPerformanceController({
    required GetTeamPerformance getTeamPerformance,
    required WatchTaskChanges watchTaskChanges,
    TeamPerformanceArgs args = const TeamPerformanceArgs(),
  }) : _getTeamPerformance = getTeamPerformance,
       _watchTaskChanges = watchTaskChanges,
       selectedDuration = args.duration.obs;

  final GetTeamPerformance _getTeamPerformance;
  final WatchTaskChanges _watchTaskChanges;
  StreamSubscription<void>? _taskChangesSubscription;

  final Rx<DurationFilter> selectedDuration;
  final loadStatus = ScreenLoadStatus.loading.obs;
  final errorMessage = ''.obs;
  final memberPerformances = <MemberPerformance>[].obs;

  @override
  void onInit() {
    super.onInit();
    _taskChangesSubscription = _watchTaskChanges().listen(
      (_) => loadTeamPerformance(showLoader: false),
    );
    loadTeamPerformance();
  }

  @override
  void onClose() {
    _taskChangesSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadTeamPerformance({bool showLoader = true}) async {
    if (showLoader) loadStatus.value = ScreenLoadStatus.loading;
    try {
      memberPerformances.assignAll(
        await _getTeamPerformance(selectedDuration.value),
      );
      loadStatus.value = ScreenLoadStatus.success;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      loadStatus.value = ScreenLoadStatus.error;
    }
  }

  Future<void> changeDuration(DurationFilter value) async {
    if (value == selectedDuration.value) return;
    selectedDuration.value = value;
    await loadTeamPerformance();
  }

  Future<void> openMemberTasks(TeamMember member) async {
    await Get.toNamed<void>(
      AppRoutes.teamTasks,
      arguments: TeamTasksArgs(
        duration: selectedDuration.value,
        memberId: member.id,
      ),
    );
  }
}
