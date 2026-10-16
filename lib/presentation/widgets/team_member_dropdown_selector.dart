import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/team_member.dart';
import 'team_member_avatar.dart';

class TeamMemberDropdownSelector extends StatelessWidget {
  const TeamMemberDropdownSelector({
    super.key,
    required this.members,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final List<TeamMember> members;
  final TeamMember? selected;
  final ValueChanged<TeamMember> onSelected;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final current = selected;
    return PopupMenuButton<TeamMember>(
      tooltip: 'Select team member',
      position: PopupMenuPosition.under,
      offset: Offset(0, 8.h),
      elevation: 3,
      enabled: enabled && members.isNotEmpty,
      constraints: BoxConstraints(minWidth: 260.w, maxWidth: 370.w),
      menuPadding: EdgeInsets.symmetric(vertical: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.r),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final m in members)
          PopupMenuItem(
            value: m,
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                TeamMemberAvatar(member: m, size: 40.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    m.name,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (m.id == current?.id)
                  Icon(
                    Icons.check_rounded,
                    size: 22.r,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.fromLTRB(3.r, 3.r, 10.w, 3.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(40.r),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current != null)
              TeamMemberAvatar(member: current, size: 40.r)
            else
              SizedBox.square(dimension: 40.r),
            if (enabled) ...[
              SizedBox(width: 8.w),
              Icon(Icons.keyboard_arrow_down_rounded, size: 24.r),
            ],
          ],
        ),
      ),
    );
  }
}
