import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/team_member.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/team_member_avatar.dart';

Future<void> showSwitchAccountSheet(BuildContext context) async {
  final session = Get.find<SessionController>();
  final picked = await showModalBottomSheet<AppUser>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 12.h),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text('Switch account', style: AppTextStyles.sectionTitle),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Text(
                'Demo only: choose who is using the app.',
                style: AppTextStyles.bodySmall,
              ),
            ),
            for (final user in session.availableUsers)
              ListTile(
                leading: TeamMemberAvatar(
                  member: TeamMember(id: user.id, name: user.name),
                  size: 36.r,
                ),
                title: Text(user.name, style: AppTextStyles.body),
                subtitle: Text(
                  user.isAdmin ? 'Admin' : 'Team member',
                  style: AppTextStyles.caption,
                ),
                trailing: user.id == session.currentUser.value?.id
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.black,
                        size: 22.r,
                      )
                    : null,
                onTap: () => Navigator.pop(context, user),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != null) await session.switchToUser(picked);
}
