import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:popaya_assessment/core/error/app_exception.dart';
import 'package:popaya_assessment/data/datasources/mock_data.dart';
import 'package:popaya_assessment/domain/entities/app_user.dart';
import 'package:popaya_assessment/domain/entities/task.dart';
import 'package:popaya_assessment/domain/entities/task_draft.dart';
import 'package:popaya_assessment/domain/entities/team_member.dart';
import 'package:popaya_assessment/domain/repositories/repository_contracts.dart';
import 'package:popaya_assessment/domain/services/clock.dart';

/// Shared in-memory test doubles for the repository contracts.
final fixedNow = DateTime(2026, 10, 16, 12);

class FixedClock implements Clock {
  @override
  DateTime now() => fixedNow;
}

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository(List<Task> seed)
    : _tasks = {for (final t in seed) t.id: t};

  final Map<String, Task> _tasks;
  final _changes = StreamController<void>.broadcast();
  bool fail = false;
  bool failSave = false;

  List<Task> get all => _tasks.values.toList();

  @override
  Future<List<Task>> getTasks() async {
    if (fail) throw const AppException('Could not load tasks.');
    return _tasks.values.toList();
  }

  @override
  Future<void> saveTask(Task task) async {
    if (failSave) throw const AppException('Could not save the task.');
    _tasks[task.id] = task;
    _changes.add(null);
  }

  @override
  Future<List<TaskTemplate>> getTaskTemplates() async => MockData.templates;

  @override
  Stream<void> watchTaskChanges() => _changes.stream;
}

class InMemoryTeamRepository implements TeamRepository {
  String? selected;

  @override
  Future<List<TeamMember>> getMembers() async => MockData.members;

  @override
  Future<String?> getSelectedMemberId() async => selected;

  @override
  Future<void> saveSelectedMemberId(String memberId) async =>
      selected = memberId;
}

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository([AppUser? user]) : current = user ?? MockData.admin;

  AppUser current;

  @override
  Future<AppUser> getCurrentUser() async => current;

  @override
  Future<AppUser> switchCurrentUser(String userId) async =>
      current = MockData.users.firstWhere((u) => u.id == userId);
}

Future<void> loadMontserrat() async {
  final loader = FontLoader('Montserrat');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Montserrat-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
