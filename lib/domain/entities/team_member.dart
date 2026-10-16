class TeamMember {
  const TeamMember({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.id == id &&
      other.name == name &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl);
}
