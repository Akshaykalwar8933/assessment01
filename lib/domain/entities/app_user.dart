enum UserRole { admin, teamMember }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.memberId,
  });

  final String id;
  final String name;
  final UserRole role;
  final String? memberId;

  bool get isAdmin => role == UserRole.admin;

  bool get canCreateTasks => isAdmin;
}
