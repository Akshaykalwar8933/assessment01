import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/task_stats.dart';
import '../../controllers/team_performance_controller.dart';
import '../../widgets/screen_headers.dart';
import '../../widgets/duration_filter_dropdown.dart';
import '../../widgets/team_member_avatar.dart';
import '../../widgets/task_status_donut_chart.dart';
import '../../widgets/loading_error_and_message_views.dart';

class TeamPerformanceScreen extends GetView<TeamPerformanceController> {
  const TeamPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = 16.w;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BackButtonTitleHeader(title: 'Team Performance'),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 30.h, gutter, 12.h),
            child: Obx(
              () => DurationFilterDropdown(
                isFullWidth: true,
                value: controller.selectedDuration.value,
                onChanged: controller.changeDuration,
              ),
            ),
          ),
          Expanded(
            child: LoadingErrorContentSwitcher(
              status: controller.loadStatus,
              errorMessage: controller.errorMessage,
              onRetry: controller.loadTeamPerformance,
              builder: (_) => Obx(() {
                final items = controller.memberPerformances.toList();
                if (items.isEmpty) {
                  return const CenteredMessageView(
                    icon: Icons.groups_outlined,
                    title: 'No team members yet',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.black,
                  onRefresh: () =>
                      controller.loadTeamPerformance(showLoader: false),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(gutter, 12.h, gutter, 32.h),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: 28.h),
                    itemBuilder: (_, i) => _MemberPerformanceCard(
                      performance: items[i],
                      onTap: () => controller.openMemberTasks(items[i].member),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPerformanceCard extends StatelessWidget {
  const _MemberPerformanceCard({
    required this.performance,
    required this.onTap,
  });

  final MemberPerformance performance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stats = performance.stats;
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamMemberAvatar(member: performance.member, size: 24.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      performance.member.name,
                      style: AppTextStyles.memberName.copyWith(fontSize: 17.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final donut = math.min(constraints.maxWidth * 0.5, 170.r);
                  return Row(
                    children: [
                      SizedBox(width: 8.w),
                      TaskStatusDonutChart(stats: stats, size: donut),
                      SizedBox(width: 16.w),
                      Expanded(child: _TaskStatusLegend(stats: stats)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusLegend extends StatelessWidget {
  const _TaskStatusLegend({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartLegendItem(
            color: AppColors.yellow,
            label: 'Open',
            value: stats.open,
          ),
          SizedBox(height: 28.h),
          ChartLegendItem(
            color: AppColors.red,
            label: 'Overdue',
            value: stats.overdue,
          ),
          SizedBox(height: 28.h),
          ChartLegendItem(
            color: AppColors.green,
            label: 'Closed',
            value: stats.closed,
          ),
        ],
      ),
    );
  }
}
