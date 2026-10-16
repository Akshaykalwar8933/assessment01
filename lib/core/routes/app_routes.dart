import '../../domain/entities/duration_filter.dart';
import '../../domain/entities/task.dart';

abstract final class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String teamPerformance = '/team-performance';
  static const String teamTasks = '/team-tasks';
}

class TeamPerformanceArgs {
  const TeamPerformanceArgs({this.duration = DurationFilter.today});

  final DurationFilter duration;
}

class TeamTasksArgs {
  const TeamTasksArgs({
    this.initialStatusTab = TaskDisplayStatus.open,
    this.duration = DurationFilter.today,
    this.memberId,
  });

  final TaskDisplayStatus initialStatusTab;
  final DurationFilter duration;

  /// Restricts the list to one member; null shows the whole team.
  final String? memberId;
}
