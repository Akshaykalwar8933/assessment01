import 'package:get/get.dart';
import '../../presentation/bindings/bindings.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/team_performance/team_performance_screen.dart';
import '../../presentation/screens/team_tasks/team_tasks_screen.dart';
import 'app_routes.dart';

 class AppPages {
  static const String initial = AppRoutes.dashboard;

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.teamPerformance,
      page: () => const TeamPerformanceScreen(),
      binding: TeamPerformanceBinding(),
    ),
    GetPage(
      name: AppRoutes.teamTasks,
      page: () => const TeamTasksScreen(),
      binding: TeamTasksBinding(),
    ),
  ];
}
