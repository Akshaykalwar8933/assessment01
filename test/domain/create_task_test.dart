import 'package:flutter_test/flutter_test.dart';
import 'package:popaya_assessment/core/error/app_exception.dart';
import 'package:popaya_assessment/data/datasources/mock_data.dart';
import 'package:popaya_assessment/domain/entities/task.dart';
import 'package:popaya_assessment/domain/entities/task_draft.dart';
import 'package:popaya_assessment/domain/usecases/task_usecases.dart';

import '../fakes.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryAuthRepository auth;
  late CreateTask createTask;

  final tomorrow = fixedNow.add(const Duration(days: 1));
  TaskDraft draft({
    String? assigneeId = 'm02',
    String title = '  Schedule a site visit  ',
    String description = '',
    DateTime? dueAt,
    bool noDue = false,
  }) => TaskDraft(
    assigneeId: assigneeId,
    title: title,
    description: description,
    dueAt: noDue ? null : (dueAt ?? tomorrow),
  );

  setUp(() {
    tasks = InMemoryTaskRepository(const []);
    auth = InMemoryAuthRepository();
    createTask = CreateTask(
      tasks,
      InMemoryTeamRepository(),
      auth,
      FixedClock(),
    );
  });

  test(
    'admin creates an open task assigned to the member and saves it',
    () async {
      final changes = <void>[];
      final sub = tasks.watchTaskChanges().listen(changes.add);

      final task = await createTask(draft(description: '  Bring keys '));

      expect(task.status, TaskStatus.open);
      expect(task.completedAt, isNull);
      expect(task.assigneeId, 'm02');
      expect(task.title, 'Schedule a site visit');
      expect(task.description, 'Bring keys');
      expect(task.createdAt, fixedNow);
      expect(task.dueAt, tomorrow);
      expect(tasks.all, [task]);
      await Future<void>.delayed(Duration.zero);
      expect(changes, hasLength(1), reason: 'listeners are notified');
      await sub.cancel();
    },
  );

  test('ids are unique even when created at the same instant', () async {
    final a = await createTask(draft());
    final b = await createTask(draft());
    expect(a.id, isNot(b.id));
    expect(tasks.all, hasLength(2));
  });

  test('blank description is stored as null', () async {
    final task = await createTask(draft(description: '   '));
    expect(task.description, isNull);
  });

  test('team members are denied and nothing is saved', () async {
    auth.current = MockData.users.firstWhere((u) => !u.isAdmin);
    await expectLater(
      createTask(draft()),
      throwsA(isA<PermissionDeniedException>()),
    );
    expect(tasks.all, isEmpty);
  });

  group('validation', () {
    Future<Map<TaskField, String>> errorsFor(TaskDraft d) async {
      try {
        await createTask(d);
      } on TaskValidationException catch (e) {
        expect(tasks.all, isEmpty, reason: 'invalid drafts are not saved');
        return e.errors;
      }
      fail('Expected TaskValidationException');
    }

    test('missing assignee, title and due date', () async {
      final errors = await errorsFor(
        draft(assigneeId: null, title: '   ', noDue: true),
      );
      expect(errors.keys, {
        TaskField.assignee,
        TaskField.title,
        TaskField.dueAt,
      });
    });

    test('unknown assignee', () async {
      final errors = await errorsFor(draft(assigneeId: 'ghost'));
      expect(errors[TaskField.assignee], contains('no longer exists'));
    });

    test('title too short or too long', () async {
      expect((await errorsFor(draft(title: 'ab'))).keys, [TaskField.title]);
      expect((await errorsFor(draft(title: 'x' * 121))).keys, [
        TaskField.title,
      ]);
    });

    test('description too long', () async {
      final errors = await errorsFor(draft(description: 'x' * 501));
      expect(errors.keys, [TaskField.description]);
    });

    test('due date must be in the future', () async {
      expect((await errorsFor(draft(dueAt: fixedNow))).keys, [TaskField.dueAt]);
      expect(
        (await errorsFor(
          draft(dueAt: fixedNow.subtract(const Duration(days: 1))),
        ))[TaskField.dueAt],
        'Due date must be in the future.',
      );
    });
  });
}
