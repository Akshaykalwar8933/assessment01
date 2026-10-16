import 'package:flutter_test/flutter_test.dart';
import 'package:popaya_assessment/domain/entities/duration_filter.dart';
import 'package:popaya_assessment/domain/entities/task.dart';
import 'package:popaya_assessment/domain/entities/task_filter_and_sort.dart';
import 'package:popaya_assessment/domain/entities/team_member.dart';
import 'package:popaya_assessment/domain/services/duration_date_range_resolver.dart';
import 'package:popaya_assessment/domain/services/task_stats_calculator.dart';
import 'package:popaya_assessment/domain/services/task_list_query_service.dart';
import 'package:popaya_assessment/domain/services/task_status_rules.dart';

// Thursday 16 Oct 2026, 12:00.
final now = DateTime(2026, 10, 16, 12);

Task task(
  String id, {
  String assignee = 'm1',
  DateTime? due,
  DateTime? created,
  DateTime? completed,
  String? title,
}) => Task(
  id: id,
  title: title ?? 'Task $id',
  assigneeId: assignee,
  createdAt: created ?? DateTime(2026, 10, 1),
  dueAt: due,
  status: completed == null ? TaskStatus.open : TaskStatus.closed,
  completedAt: completed,
);

void main() {
  group('TaskRules', () {
    test('open task past its due date is overdue', () {
      final t = task('1', due: now.subtract(const Duration(minutes: 1)));
      expect(t.displayStatusAt(now), TaskDisplayStatus.overdue);
      expect(t.overdueDurationAt(now), const Duration(minutes: 1));
    });

    test('open task due later, or without due date, is open', () {
      expect(
        task('1', due: now.add(const Duration(hours: 1))).displayStatusAt(now),
        TaskDisplayStatus.open,
      );
      expect(task('2').displayStatusAt(now), TaskDisplayStatus.open);
      expect(task('2').overdueDurationAt(now), isNull);
    });

    test('closed task is closed even if its due date passed', () {
      final t = task('1', due: DateTime(2026, 9, 1), completed: now);
      expect(t.displayStatusAt(now), TaskDisplayStatus.closed);
    });

    test('reference date: completion > due > creation', () {
      final created = DateTime(2026, 1, 1);
      final due = DateTime(2026, 2, 1);
      final done = DateTime(2026, 3, 1);
      expect(task('a', created: created).dateUsedForDurationFilter, created);
      expect(
        task('b', created: created, due: due).dateUsedForDurationFilter,
        due,
      );
      expect(
        task(
          'c',
          created: created,
          due: due,
          completed: done,
        ).dateUsedForDurationFilter,
        done,
      );
    });

    test('close and reopen keep identity and toggle completion', () {
      final closed = task('1').close(now);
      expect(closed.isClosed, isTrue);
      expect(closed.completedAt, now);
      final reopened = closed.reopen();
      expect(reopened.isClosed, isFalse);
      expect(reopened.completedAt, isNull);
      expect(reopened.id, '1');
    });
  });

  group('DurationResolver', () {
    const resolver = DurationDateRangeResolver();
    DateRange r(DurationOption o) =>
        resolver.resolveDateRange(DurationFilter.preset(o), now);

    test('today', () {
      expect(r(DurationOption.today).start, DateTime(2026, 10, 16));
      expect(r(DurationOption.today).end, DateTime(2026, 10, 17));
    });

    test('week starts Monday', () {
      expect(r(DurationOption.week).start, DateTime(2026, 10, 12));
      expect(r(DurationOption.week).end, DateTime(2026, 10, 19));
    });

    test('month, quarter, annual', () {
      expect(r(DurationOption.month).start, DateTime(2026, 10));
      expect(r(DurationOption.month).end, DateTime(2026, 11));
      expect(r(DurationOption.quarter).start, DateTime(2026, 10));
      expect(r(DurationOption.quarter).end, DateTime(2027, 1));
      expect(r(DurationOption.annual).start, DateTime(2026));
      expect(r(DurationOption.annual).end, DateTime(2027));
    });

    test('till date is unbounded up to end of today', () {
      final range = r(DurationOption.tillDate);
      expect(range.start, isNull);
      expect(range.contains(DateTime(2000)), isTrue);
      expect(range.contains(DateTime(2026, 10, 17)), isFalse);
    });

    test('custom range is inclusive of both days and order-insensitive', () {
      final f = DurationFilter.custom(
        DateTime(2026, 10, 10, 18),
        DateTime(2026, 10, 5, 9),
      );
      final range = resolver.resolveDateRange(f, now);
      expect(range.start, DateTime(2026, 10, 5));
      expect(range.end, DateTime(2026, 10, 11));
      expect(range.contains(DateTime(2026, 10, 10, 23, 59)), isTrue);
    });
  });

  group('TaskQueryService', () {
    const service = TaskListQueryService();

    test('select by member and duration', () {
      final tasks = [
        task('1', due: DateTime(2026, 10, 16, 18)),
        task('2', due: DateTime(2026, 10, 16, 9), assignee: 'm2'),
        task('3', due: DateTime(2026, 10, 20)),
      ];
      final today = service.selectTasksForMemberAndDuration(
        tasks,
        duration: DurationFilter.today,
        now: now,
      );
      expect(today.map((t) => t.id), ['1', '2']);
      final mine = service.selectTasksForMemberAndDuration(
        tasks,
        duration: DurationFilter.today,
        now: now,
        memberId: 'm1',
      );
      expect(mine.map((t) => t.id), ['1']);
    });

    test('filter by assignee and due presence', () {
      final tasks = [
        task('1', due: now),
        task('2', assignee: 'm2'),
        task('3', assignee: 'm3', due: now),
      ];
      expect(
        service
            .applyTaskFilter(tasks, const TaskFilter(assigneeIds: {'m1', 'm2'}))
            .map((t) => t.id),
        ['1', '2'],
      );
      expect(
        service
            .applyTaskFilter(
              tasks,
              const TaskFilter(dueDateFilter: DueDateFilter.withoutDueDate),
            )
            .map((t) => t.id),
        ['2'],
      );
    });

    test('sort by due puts missing due dates last, ties by id', () {
      final tasks = [
        task('c'),
        task('b', due: DateTime(2026, 10, 20)),
        task('a', due: DateTime(2026, 10, 18)),
        task('d', due: DateTime(2026, 10, 18)),
      ];
      expect(
        service.sortTasks(tasks, TaskSortOrder.dueSoonest).map((t) => t.id),
        ['a', 'd', 'b', 'c'],
      );
      expect(
        service.sortTasks(tasks, TaskSortOrder.dueLatest).map((t) => t.id),
        ['b', 'a', 'd', 'c'],
      );
    });

    test('sort by title and creation date', () {
      final tasks = [
        task('1', title: 'beta', created: DateTime(2026, 1, 2)),
        task('2', title: 'Alpha', created: DateTime(2026, 1, 3)),
        task('3', title: 'gamma', created: DateTime(2026, 1, 1)),
      ];
      expect(service.sortTasks(tasks, TaskSortOrder.titleAz).map((t) => t.id), [
        '2',
        '1',
        '3',
      ]);
      expect(service.sortTasks(tasks, TaskSortOrder.newest).map((t) => t.id), [
        '2',
        '1',
        '3',
      ]);
      expect(service.sortTasks(tasks, TaskSortOrder.oldest).map((t) => t.id), [
        '3',
        '1',
        '2',
      ]);
    });
  });

  group('StatsCalculator', () {
    const calc = TaskStatsCalculator();
    final tasks = [
      task('1', due: now.add(const Duration(hours: 2))),
      task('2', due: now.subtract(const Duration(days: 2))),
      task('3', completed: now, assignee: 'm2'),
      task('4', assignee: 'm2'),
    ];

    test('team stats count each task status once', () {
      final stats = calc.countTasksByStatus(tasks, now);
      expect(stats.open, 2);
      expect(stats.overdue, 1);
      expect(stats.closed, 1);
      expect(stats.total, 4);
    });

    test('member performance sums to team stats and includes idle members', () {
      const members = [
        TeamMember(id: 'm1', name: 'A'),
        TeamMember(id: 'm2', name: 'B'),
        TeamMember(id: 'm3', name: 'C'),
      ];
      final perf = calc.calculatePerformancePerMember(members, tasks, now);
      expect(perf.map((p) => p.stats.total), [2, 2, 0]);
      expect(
        perf.fold<int>(0, (sum, p) => sum + p.stats.total),
        calc.countTasksByStatus(tasks, now).total,
      );
    });
  });

  test('TeamMember initials', () {
    expect(const TeamMember(id: '1', name: 'Akhil Bisht').initials, 'AB');
    expect(const TeamMember(id: '2', name: '  hemant ').initials, 'H');
  });
}
