import '../entities/app_user.dart';
import '../entities/portfolio_summary.dart';
import '../entities/team_member.dart';
import '../repositories/repository_contracts.dart';

class GetTeamMembers {
  const GetTeamMembers(this._repository);

  final TeamRepository _repository;

  Future<List<TeamMember>> call() => _repository.getMembers();
}

class GetSavedSelectedMemberId {
  const GetSavedSelectedMemberId(this._repository);

  final TeamRepository _repository;

  Future<String?> call() => _repository.getSelectedMemberId();
}

class SaveSelectedMemberId {
  const SaveSelectedMemberId(this._repository);

  final TeamRepository _repository;

  Future<void> call(String memberId) =>
      _repository.saveSelectedMemberId(memberId);
}

class GetPortfolioSummary {
  const GetPortfolioSummary(this._repository);

  final PortfolioRepository _repository;

  Future<PortfolioSummary> call() => _repository.getPortfolioSummary();
}

class GetCurrentUser {
  const GetCurrentUser(this._auth);

  final AuthRepository _auth;

  Future<AppUser> call() => _auth.getCurrentUser();
}

class GetAvailableUsers {
  const GetAvailableUsers(this._auth);

  final AuthRepository _auth;

  Future<List<AppUser>> call() => _auth.getAvailableUsers();
}

class SwitchCurrentUser {
  const SwitchCurrentUser(this._auth);

  final AuthRepository _auth;

  Future<AppUser> call(String userId) => _auth.switchCurrentUser(userId);
}
