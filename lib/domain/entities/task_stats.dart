import 'task.dart';
import 'team_member.dart';

class TaskStats {
  const TaskStats({this.open = 0, this.overdue = 0, this.closed = 0});

  factory TaskStats.countByStatus(Iterable<Task> tasks, DateTime now) {
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

  static const TaskStats empty = TaskStats();

  final int open;
  final int overdue;
  final int closed;

  int get total => open + overdue + closed;

  @override
  bool operator ==(Object other) =>
      other is TaskStats &&
      other.open == open &&
      other.overdue == overdue &&
      other.closed == closed;

  @override
  int get hashCode => Object.hash(open, overdue, closed);

  @override
  String toString() =>
      'TaskStats(open: $open, overdue: $overdue, closed: $closed)';
}

class MemberPerformance {
  const MemberPerformance({required this.member, required this.stats});

  final TeamMember member;
  final TaskStats stats;

  static List<MemberPerformance> forEachMember(
    List<TeamMember> members,
    Iterable<Task> tasks,
    DateTime now,
  ) {
    final tasksByAssignee = <String, List<Task>>{};
    for (final t in tasks) {
      tasksByAssignee.putIfAbsent(t.assigneeId, () => []).add(t);
    }
    return [
      for (final m in members)
        MemberPerformance(
          member: m,
          stats: TaskStats.countByStatus(
            tasksByAssignee[m.id] ?? const [],
            now,
          ),
        ),
    ];
  }
}
