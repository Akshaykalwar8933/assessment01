import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/duration_filter.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/team_performance_controller.dart';
import '../controllers/team_tasks_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardController(
        taskRepository: Get.find(),
        teamRepository: Get.find(),
        portfolioRepository: Get.find(),
        getTaskCountsByStatus: Get.find(),
        session: Get.find(),
      ),
    );
  }
}

class TeamPerformanceBinding extends Bindings {
  @override
  void dependencies() {
    final initialDuration = Get.arguments;
    Get.lazyPut(
      () => TeamPerformanceController(
        getTeamPerformance: Get.find(),
        taskRepository: Get.find(),
        initialDuration: initialDuration is DurationFilter
            ? initialDuration
            : DurationFilter.today,
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
        updateTaskClosedStatus: Get.find(),
        taskRepository: Get.find(),
        teamRepository: Get.find(),
        clock: Get.find(),
        args: args is TeamTasksArgs ? args : const TeamTasksArgs(),
      ),
    );
  }
}
