import 'team_member.dart';

class TaskStats {
  const TaskStats({this.open = 0, this.overdue = 0, this.closed = 0});

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
}
