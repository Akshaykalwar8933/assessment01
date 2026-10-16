import 'package:get/get.dart';

import '../../data/datasources/hive_local_data_source.dart';
import '../../data/repositories/repository_implementations.dart';
import '../../domain/repositories/repository_contracts.dart';
import '../../domain/services/clock.dart';
import '../../domain/usecases/task_usecases.dart';
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
    ..put<AuthRepository>(auth, permanent: true)
    ..put(GetTaskCountsByStatus(tasks, clock), permanent: true)
    ..put(GetTeamPerformance(tasks, team, clock), permanent: true)
    ..put(GetFilteredTasksGroupedByStatus(tasks, clock), permanent: true)
    ..put(UpdateTaskClosedStatus(tasks, clock), permanent: true)
    ..put(CreateTask(tasks, team, auth, clock), permanent: true)
    ..put(SessionController(auth: auth), permanent: true);
}
