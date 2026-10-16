import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/team_member.dart';

class TeamMemberAvatar extends StatelessWidget {
  const TeamMemberAvatar({super.key, required this.member, required this.size});

  final TeamMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    final color =
        palette[member.id.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    final initials = Center(
      child: Text(
        member.initials,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.38,
        ),
      ),
    );
    final url = member.avatarUrl;
    return Semantics(
      label: member.name,
      image: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: url == null
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}
