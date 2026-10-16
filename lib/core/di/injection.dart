import 'package:get/get.dart';

import '../../data/datasources/hive_local_data_source.dart';
import '../../data/repositories/repository_implementations.dart';
import '../../domain/repositories/repository_contracts.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/task_stats_calculator.dart';
import '../../domain/services/task_list_query_service.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/usecases/team_usecases.dart';
import '../../presentation/controllers/session_controller.dart';

Future<void> initAppDependencies() async {
  final source = await HiveLocalDataSource.open();
  const clock = SystemClock();
  await source.seedIfNeeded(clock.now());
  registerDependencies(
    tasks: HiveTaskRepository(source),
    team: HiveTeamRepository(source),
    portfolio: const MockPortfolioRepository(),
    auth: MockAuthRepository(source),
    clock: clock,
  );
}

void registerDependencies({
  required TaskRepository tasks,
  required TeamRepository team,
  required PortfolioRepository portfolio,
  required AuthRepository auth,
  Clock clock = const SystemClock(),
}) {
  Get
    ..put<Clock>(clock, permanent: true)
    ..put<TaskRepository>(tasks, permanent: true)
    ..put<TeamRepository>(team, permanent: true)
    ..put<PortfolioRepository>(portfolio, permanent: true)
    ..put<AuthRepository>(auth, permanent: true);

  const query = TaskListQueryService();
  const stats = TaskStatsCalculator();

  Get
    ..put(GetTeamMembers(team), permanent: true)
    ..put(GetSavedSelectedMemberId(team), permanent: true)
    ..put(SaveSelectedMemberId(team), permanent: true)
    ..put(GetPortfolioSummary(portfolio), permanent: true)
    ..put(GetTaskCountsByStatus(tasks, query, stats, clock), permanent: true)
    ..put(GetTeamPerformance(tasks, team, query, stats, clock), permanent: true)
    ..put(GetFilteredTasksGroupedByStatus(tasks, query, clock), permanent: true)
    ..put(UpdateTaskClosedStatus(tasks, clock), permanent: true)
    ..put(GetTaskTemplates(tasks), permanent: true)
    ..put(WatchTaskChanges(tasks), permanent: true)
    ..put(CreateTask(tasks, team, auth, clock), permanent: true)
    ..put(
      SessionController(
        getCurrentUser: GetCurrentUser(auth),
        getAvailableUsers: GetAvailableUsers(auth),
        switchCurrentUser: SwitchCurrentUser(auth),
      ),
      permanent: true,
    );
}
