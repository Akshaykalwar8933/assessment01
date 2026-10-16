import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/team_member.dart';
import 'display_labels.dart';
import 'team_member_avatar.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.assignee,
    required this.now,
    this.onTap,
  });

  final Task task;
  final TeamMember? assignee;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = buildTaskStatusLabel(task, now);
    final member = assignee;
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Icon(
                      Icons.flag_rounded,
                      size: 20.r,
                      color: AppColors.yellow,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTextStyles.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              if (member != null)
                Row(
                  children: [
                    TeamMemberAvatar(member: member, size: 22.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        member.name,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    'To do',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      status.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 15.sp,
                        color: status.color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
