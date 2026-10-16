import '../entities/app_user.dart';
import '../entities/portfolio_summary.dart';
import '../entities/task.dart';
import '../entities/task_draft.dart';
import '../entities/team_member.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getTasks();

  Future<void> saveTask(Task task);

  Future<List<TaskTemplate>> getTaskTemplates();

  Stream<void> watchTaskChanges();
}

abstract interface class TeamRepository {
  Future<List<TeamMember>> getMembers();

  Future<String?> getSelectedMemberId();

  Future<void> saveSelectedMemberId(String memberId);
}

abstract interface class PortfolioRepository {
  Future<PortfolioSummary> getPortfolioSummary();
}

abstract interface class AuthRepository {
  Future<AppUser> getCurrentUser();

  Future<List<AppUser>> getAvailableUsers();

  Future<AppUser> switchCurrentUser(String userId);
}
