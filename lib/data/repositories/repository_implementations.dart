import '../../core/error/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/repository_contracts.dart';
import '../datasources/hive_local_data_source.dart';
import '../datasources/mock_data.dart';
import '../models/hive_models.dart';

Future<T> _guard<T>(String message, Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException(message, e);
  }
}

class HiveTaskRepository implements TaskRepository {
  const HiveTaskRepository(this._source);

  final HiveLocalDataSource _source;

  @override
  Future<List<Task>> getTasks() => _guard(
    'Could not load tasks.',
    () async => _source.getTasks().map((m) => m.toEntity()).toList(),
  );

  @override
  Future<void> saveTask(Task task) => _guard(
    'Could not save the task.',
    () => _source.putTask(TaskModel.fromEntity(task)),
  );

  @override
  Future<List<TaskTemplate>> getTaskTemplates() async => MockData.templates;

  @override
  Stream<void> watchTaskChanges() => _source.watchTaskBoxChanges();
}

class HiveTeamRepository implements TeamRepository {
  const HiveTeamRepository(this._source);

  final HiveLocalDataSource _source;

  @override
  Future<List<TeamMember>> getMembers() => _guard(
    'Could not load team members.',
    () async => _source.getMembers().map((m) => m.toEntity()).toList(),
  );

  @override
  Future<String?> getSelectedMemberId() => _guard(
    'Could not load your selection.',
    () async => _source.getSelectedMemberId(),
  );

  @override
  Future<void> saveSelectedMemberId(String memberId) => _guard(
    'Could not save your selection.',
    () => _source.putSelectedMemberId(memberId),
  );
}

class MockPortfolioRepository implements PortfolioRepository {
  const MockPortfolioRepository();

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => MockData.portfolio;
}

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._source);

  final HiveLocalDataSource _source;

  @override
  Future<AppUser> getCurrentUser() =>
      _guard('Could not load your account.', () async {
        final id = _source.getCurrentUserId();
        return MockData.users.firstWhere(
          (u) => u.id == id,
          orElse: () => MockData.admin,
        );
      });

  @override
  Future<AppUser> switchCurrentUser(String userId) =>
      _guard('Could not switch account.', () async {
        final user = MockData.users.where((u) => u.id == userId).firstOrNull;
        if (user == null) throw const AppException('Unknown account.');
        await _source.putCurrentUserId(user.id);
        return user;
      });
}
