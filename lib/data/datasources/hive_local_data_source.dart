import 'package:hive_ce/hive.dart';
import '../models/hive_models.dart';
import 'mock_data.dart';

class HiveLocalDataSource {
  HiveLocalDataSource._(this._tasks, this._members, this._settings);

  static const String tasksBox = 'tasks';
  static const String membersBox = 'team_members';
  static const String settingsBox = 'settings';

  static const String _seedVersionKey = 'seed_version';
  static const String _selectedMemberKey = 'selected_member_id';
  static const String _currentUserKey = 'current_user_id';

  static const int seedVersion = 1;

  final Box<TaskModel> _tasks;
  final Box<TeamMemberModel> _members;
  final Box<dynamic> _settings;

  static Future<HiveLocalDataSource> open() async {
    if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.teamMember)) {
      Hive.registerAdapter(TeamMemberModelAdapter());
    }
    final (tasks, members, settings) = await (
      Hive.openBox<TaskModel>(tasksBox),
      Hive.openBox<TeamMemberModel>(membersBox),
      Hive.openBox<dynamic>(settingsBox),
    ).wait;
    return HiveLocalDataSource._(tasks, members, settings);
  }

  Future<bool> seedIfNeeded(DateTime now) async {
    if (_settings.get(_seedVersionKey) == seedVersion) return false;
    await _members.clear();
    await _tasks.clear();
    await _members.putAll({
      for (final m in MockData.members) m.id: TeamMemberModel.fromEntity(m),
    });
    await _tasks.putAll({
      for (final t in MockData.tasks(now)) t.id: TaskModel.fromEntity(t),
    });
    await _settings.put(_seedVersionKey, seedVersion);
    return true;
  }

  List<TaskModel> getTasks() => _tasks.values.toList(growable: false);

  Future<void> putTask(TaskModel task) => _tasks.put(task.id, task);

  Stream<void> watchTaskBoxChanges() => _tasks.watch().map((_) {});

  List<TeamMemberModel> getMembers() => _members.values.toList(growable: false);

  String? getSelectedMemberId() => _settings.get(_selectedMemberKey) as String?;

  Future<void> putSelectedMemberId(String id) =>
      _settings.put(_selectedMemberKey, id);

  String? getCurrentUserId() => _settings.get(_currentUserKey) as String?;

  Future<void> putCurrentUserId(String id) =>
      _settings.put(_currentUserKey, id);
}
