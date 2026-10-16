import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class OverlappingAvatarStack extends StatelessWidget {
  const OverlappingAvatarStack({
    super.key,
    required this.members,
    required this.extraCount,
    this.size,
  });

  final List<TeamMember> members;
  final int extraCount;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 34.r;
    final step = s * 0.6;
    final count = members.length + (extraCount > 0 ? 1 : 0);
    if (count == 0) return const SizedBox.shrink();
    return SizedBox(
      width: s + step * (count - 1),
      height: s,
      child: Stack(
        children: [
          for (var i = 0; i < members.length; i++)
            Positioned(
              left: step * i,
              child: _wrapWithWhiteRing(
                TeamMemberAvatar(member: members[i], size: s - 2),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: step * members.length,
              child: _wrapWithWhiteRing(
                Container(
                  width: s - 2,
                  height: s - 2,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+$extraCount',
                    style: AppTextStyles.caption.copyWith(fontSize: s * 0.34),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrapWithWhiteRing(Widget child) => Container(
    padding: const EdgeInsets.all(1),
    decoration: const BoxDecoration(
      color: AppColors.white,
      shape: BoxShape.circle,
    ),
    child: child,
  );
}
