import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/portfolio_summary.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/team_member.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/screen_headers.dart';
import '../../widgets/buttons_cards_and_toggles.dart';
import '../../widgets/duration_filter_dropdown.dart';
import '../../widgets/team_member_avatar.dart';
import '../../widgets/team_member_dropdown_selector.dart';
import '../../widgets/loading_error_and_message_views.dart';
import '../add_task/add_task_sheet.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AdminOnlyAddTaskButton(
        resolveInitialAssigneeId: () =>
            controller.taskScope.value == TaskScope.myTasks
            ? controller.selectedMember.value?.id
            : null,
      ),
      body: Column(
        children: [
          ResideLogoHeader(
            // onMenuPressed: () => showSwitchAccountSheet(context)
          ),
          Expanded(
            child: LoadingErrorContentSwitcher(
              status: controller.loadStatus,
              errorMessage: controller.errorMessage,
              onRetry: controller.loadDashboard,
              builder: (_) => RefreshIndicator(
                color: AppColors.black,
                onRefresh: controller.loadDashboard,
                child: _DashboardScrollableContent(controller: controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardScrollableContent extends StatelessWidget {
  const _DashboardScrollableContent({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final gutter = 16.w;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 24.h, gutter, 96.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 26.sp),
              ),
            ),
            Obx(
              () => TeamMemberDropdownSelector(
                members: controller.teamMembers.toList(),
                selected: controller.selectedMember.value,
                onSelected: controller.selectTeamMember,
                enabled: controller.session.isAdmin,
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        const Divider(),
        SizedBox(height: 24.h),
        Obx(
          () => TwoOptionSegmentedToggle<TaskScope>(
            options: const {
              TaskScope.myTasks: 'My Tasks',
              TaskScope.teams: 'Teams',
            },
            value: controller.taskScope.value,
            onChanged: controller.changeTaskScope,
          ),
        ),
        SizedBox(height: 40.h),
        Row(
          children: [
            Expanded(child: Text('Tasks', style: AppTextStyles.sectionTitle)),
            Obx(
              () => DurationFilterDropdown(
                value: controller.selectedDuration.value,
                onChanged: controller.changeDuration,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Obx(() {
          final stats = controller.taskCounts.value;
          return Column(
            children: [
              _TwoCardsSideBySide(
                spacing: 24.w,
                left: CountSummaryCard(
                  value: stats.open,
                  label: 'Open',
                  icon: Icons.assignment_turned_in_outlined,
                  iconColor: AppColors.amber,
                  tint: AppColors.yellowTint,
                  onTap: () =>
                      controller.openTeamTasksForStatus(TaskDisplayStatus.open),
                ),
                right: CountSummaryCard(
                  value: stats.overdue,
                  label: 'Overdue',
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.red,
                  tint: AppColors.redTint,
                  onTap: () => controller.openTeamTasksForStatus(
                    TaskDisplayStatus.overdue,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: CountSummaryCard(
                  value: stats.closed,
                  label: 'Closed',
                  icon: Icons.check_rounded,
                  iconColor: AppColors.lightGreen,
                  tint: AppColors.greenTint,
                  onTap: () => controller.openTeamTasksForStatus(
                    TaskDisplayStatus.closed,
                  ),
                ),
              ),
            ],
          );
        }),
        SizedBox(height: 20.h),
        FullWidthOutlinedArrowButton(
          label: 'VIEW TEAM PERFORMANCE',
          onPressed: controller.openTeamPerformance,
        ),
        Obx(() {
          final summary = controller.portfolioSummary.value;
          if (summary == null) return const SizedBox.shrink();
          return _PropertiesAndOpportunitiesSection(
            summary: summary,
            members: controller.teamMembers.toList(),
          );
        }),
      ],
    );
  }
}

class _PropertiesAndOpportunitiesSection extends StatelessWidget {
  const _PropertiesAndOpportunitiesSection({
    required this.summary,
    required this.members,
  });

  final PortfolioSummary summary;
  final List<TeamMember> members;

  Widget _buildOpportunityCard(OpportunityGroup group, String label) {
    final byId = {for (final m in members) m.id: m};
    final shown = group.memberIds
        .map((id) => byId[id])
        .nonNulls
        .take(2)
        .toList();
    return CountSummaryCard(
      value: group.count,
      label: label,
      icon: null,
      iconColor: AppColors.textMuted,
      tint: AppColors.background,
      trailing: OverlappingAvatarStack(
        members: shown,
        extraCount: (group.count - shown.length).clamp(0, 999),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 44.h),
        Text('Properties', style: AppTextStyles.sectionTitle),
        SizedBox(height: 20.h),
        _TwoCardsSideBySide(
          spacing: 12.w,
          left: CountSummaryCard(
            value: summary.allListings,
            label: 'All listings',
            icon: Icons.home_outlined,
            iconColor: AppColors.green,
            tint: AppColors.greenTint,
          ),
          right: CountSummaryCard(
            value: summary.underOnboarding,
            label: 'Under Onboarding',
            icon: Icons.add_home_outlined,
            iconColor: AppColors.textPrimary,
            tint: AppColors.blueTint,
          ),
        ),
        SizedBox(height: 44.h),
        Text('Opportunities', style: AppTextStyles.sectionTitle),
        SizedBox(height: 20.h),
        _TwoCardsSideBySide(
          spacing: 24.w,
          left: _buildOpportunityCard(summary.toRentIn, 'To rent-in'),
          right: _buildOpportunityCard(summary.toLeaseOut, 'To lease-out'),
        ),
      ],
    );
  }
}

class _TwoCardsSideBySide extends StatelessWidget {
  const _TwoCardsSideBySide({
    required this.left,
    required this.right,
    required this.spacing,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          SizedBox(width: spacing),
          Expanded(child: right),
        ],
      ),
    );
  }
}
