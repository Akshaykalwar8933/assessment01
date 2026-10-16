import '../entities/task.dart';
import '../entities/task_stats.dart';
import '../entities/team_member.dart';
import 'task_status_rules.dart';

class TaskStatsCalculator {
  const TaskStatsCalculator();

  TaskStats countTasksByStatus(Iterable<Task> tasks, DateTime now) {
    var open = 0, overdue = 0, closed = 0;
    for (final t in tasks) {
      switch (t.displayStatusAt(now)) {
        case TaskDisplayStatus.open:
          open++;
        case TaskDisplayStatus.overdue:
          overdue++;
        case TaskDisplayStatus.closed:
          closed++;
      }
    }
    return TaskStats(open: open, overdue: overdue, closed: closed);
  }

  /// One entry per member, in member order, including members with no tasks.
  List<MemberPerformance> calculatePerformancePerMember(
    List<TeamMember> members,
    Iterable<Task> tasks,
    DateTime now,
  ) {
    final byAssignee = <String, List<Task>>{};
    for (final t in tasks) {
      byAssignee.putIfAbsent(t.assigneeId, () => []).add(t);
    }
    return [
      for (final m in members)
        MemberPerformance(
          member: m,
          stats: countTasksByStatus(byAssignee[m.id] ?? const [], now),
        ),
    ];
  }
}
