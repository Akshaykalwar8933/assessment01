import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:popaya_assessment/data/datasources/hive_local_data_source.dart';
import 'package:popaya_assessment/data/datasources/mock_data.dart';
import 'package:popaya_assessment/data/repositories/repository_implementations.dart';
import 'package:popaya_assessment/domain/entities/app_user.dart';
import 'package:popaya_assessment/domain/entities/task.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('seeds once and persists task changes across restarts', () async {
    final now = DateTime(2026, 10, 16, 12);

    var source = await HiveLocalDataSource.open();
    expect(await source.seedIfNeeded(now), isTrue);

    var tasks = HiveTaskRepository(source);
    final team = HiveTeamRepository(source);
    final all = await tasks.getTasks();
    expect(all, hasLength(MockData.tasks(now).length));
    expect(await team.getMembers(), MockData.members);

    final target = all.firstWhere((t) => !t.isClosed);
    await tasks.saveTask(target.close(now));
    await team.saveSelectedMemberId('m03');

    // Simulate an app restart.
    await Hive.close();
    Hive.init(dir.path);
    source = await HiveLocalDataSource.open();
    expect(await source.seedIfNeeded(now), isFalse, reason: 'must not reseed');

    tasks = HiveTaskRepository(source);
    final reloaded = (await tasks.getTasks()).firstWhere(
      (t) => t.id == target.id,
    );
    expect(reloaded.status, TaskStatus.closed);
    expect(reloaded.completedAt, now);
    expect(reloaded.title, target.title);
    expect(reloaded.dueAt, target.dueAt);
    expect(await HiveTeamRepository(source).getSelectedMemberId(), 'm03');
  });

  test('new tasks keep their description, notify watchers, and the chosen '
      'account survives restarts', () async {
    final now = DateTime(2026, 10, 16, 12);
    var source = await HiveLocalDataSource.open();
    await source.seedIfNeeded(now);

    final repo = HiveTaskRepository(source);
    final events = <void>[];
    final sub = repo.watchTaskChanges().listen(events.add);
    final task = Task(
      id: 'task_new',
      title: 'Verify ownership documents',
      assigneeId: 'm02',
      createdAt: now,
      description: 'Collect the sale deed',
      dueAt: now.add(const Duration(days: 2)),
    );
    await repo.saveTask(task);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    await sub.cancel();

    final auth = MockAuthRepository(source);
    expect((await auth.getCurrentUser()).role, UserRole.admin);
    await auth.switchCurrentUser('u_m03');

    await Hive.close();
    Hive.init(dir.path);
    source = await HiveLocalDataSource.open();
    final reloaded = (await HiveTaskRepository(
      source,
    ).getTasks()).firstWhere((t) => t.id == 'task_new');
    expect(reloaded, task);
    final user = await MockAuthRepository(source).getCurrentUser();
    expect(user.id, 'u_m03');
    expect(user.role, UserRole.teamMember);
  });

  test('mock data is valid and covers every task status', () {
    final now = DateTime(2026, 10, 16, 12);
    final tasks = MockData.tasks(now);
    expect(tasks.map((t) => t.id).toSet(), hasLength(tasks.length));
    final memberIds = MockData.members.map((m) => m.id).toSet();
    for (final t in tasks) {
      expect(memberIds, contains(t.assigneeId));
      expect(t.createdAt.isAfter(now), isFalse);
      if (t.completedAt != null) {
        expect(t.completedAt!.isAfter(now), isFalse);
        expect(t.completedAt!.isBefore(t.createdAt), isFalse);
      }
    }
    expect(tasks.any((t) => t.isClosed), isTrue);
    expect(tasks.any((t) => !t.isClosed && t.dueAt == null), isTrue);
    expect(
      tasks.any((t) => !t.isClosed && (t.dueAt?.isBefore(now) ?? false)),
      isTrue,
    );
  });
}
