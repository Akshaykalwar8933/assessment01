import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/team_performance_controller.dart';
import '../controllers/team_tasks_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardController(
        getTeamMembers: Get.find(),
        getSavedSelectedMemberId: Get.find(),
        saveSelectedMemberId: Get.find(),
        getPortfolioSummary: Get.find(),
        getTaskCountsByStatus: Get.find(),
        watchTaskChanges: Get.find(),
        session: Get.find(),
      ),
    );
  }
}

class TeamPerformanceBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    Get.lazyPut(
      () => TeamPerformanceController(
        getTeamPerformance: Get.find(),
        watchTaskChanges: Get.find(),
        args: args is TeamPerformanceArgs ? args : const TeamPerformanceArgs(),
      ),
    );
  }
}

class TeamTasksBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    Get.lazyPut(
      () => TeamTasksController(
        getFilteredTasksGroupedByStatus: Get.find(),
        getTeamMembers: Get.find(),
        updateTaskClosedStatus: Get.find(),
        clock: Get.find(),
        watchTaskChanges: Get.find(),
        args: args is TeamTasksArgs ? args : const TeamTasksArgs(),
      ),
    );
  }
}
