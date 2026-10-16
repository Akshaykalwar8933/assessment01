import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/portfolio_summary.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/team_member.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/duration_filter_dropdown.dart';
import '../../widgets/team_member_avatar.dart';
import '../../widgets/loading_error_and_message_views.dart';
import '../add_task/add_task_sheet.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      floatingActionButton: Obx(
        () => controller.session.isAdmin
            ? FloatingActionButton.extended(
                tooltip: 'Add and assign a task',
                onPressed: () => showAddTaskSheet(
                  context,
                  initialAssigneeId:
                      controller.taskScope.value == TaskScope.myTasks
                      ? controller.selectedMember.value?.id
                      : null,
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add Task',
                  style: AppTextStyles.button.copyWith(color: AppColors.white),
                ),
              )
            : const SizedBox.shrink(),
      ),

      body: Column(
        children: [
          const _ResideLogoHeader(),
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
      padding: EdgeInsets.fromLTRB(
        gutter,
        24.h,
        gutter,
        96.h + MediaQuery.paddingOf(context).bottom,
      ),
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
              () => _TeamMemberDropdownSelector(
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
          () => _TwoOptionSegmentedToggle<TaskScope>(
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
                left: _CountSummaryCard(
                  value: stats.open,
                  label: 'Open',
                  icon: Icons.assignment_turned_in_outlined,
                  iconColor: AppColors.amber,
                  tint: AppColors.yellowTint,
                  onTap: () =>
                      controller.openTeamTasksForStatus(TaskDisplayStatus.open),
                ),
                right: _CountSummaryCard(
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
                child: _CountSummaryCard(
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
        _FullWidthOutlinedArrowButton(
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
    return _CountSummaryCard(
      value: group.count,
      label: label,
      icon: null,
      iconColor: AppColors.textMuted,
      tint: AppColors.background,
      trailing: _OverlappingAvatarStack(
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
          left: _CountSummaryCard(
            value: summary.allListings,
            label: 'All listings',
            icon: Icons.home_outlined,
            iconColor: AppColors.green,
            tint: AppColors.greenTint,
          ),
          right: _CountSummaryCard(
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

class _TwoOptionSegmentedToggle<T> extends StatelessWidget {
  const _TwoOptionSegmentedToggle({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: option, value: label) in options.entries)
            Expanded(
              child: Semantics(
                selected: option == value,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    color: option == value
                        ? AppColors.black
                        : Colors.transparent,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: option == value
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: option == value
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountSummaryCard extends StatelessWidget {
  const _CountSummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tint,
    this.trailing,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData? icon;
  final Color iconColor;
  final Color tint;

  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$value', style: AppTextStyles.statValue),
                      SizedBox(width: 14.w),
                      trailing ??
                          Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: BoxDecoration(
                              color: tint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 20.r, color: iconColor),
                          ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.statLabel,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullWidthOutlinedArrowButton extends StatelessWidget {
  const _FullWidthOutlinedArrowButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.white,
        minimumSize: Size(double.infinity, 46.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.r)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(letterSpacing: 0.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 24.r),
        ],
      ),
    );
  }
}

class _TeamMemberDropdownSelector extends StatelessWidget {
  const _TeamMemberDropdownSelector({
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

class _OverlappingAvatarStack extends StatelessWidget {
  const _OverlappingAvatarStack({
    required this.members,
    required this.extraCount,
  });

  final List<TeamMember> members;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final s = 34.r;
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

class _ResideLogoHeader extends StatelessWidget {
  const _ResideLogoHeader();

  static const String _logoAsset = 'assets/images/reside_logo.png';

  static const double _logoAspectRatio = 266 / 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 22.h),
              child: Row(
                children: [
                  Image.asset(
                    _logoAsset,
                    width: 104.w,
                    height: 104.w / _logoAspectRatio,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'Reside',
                    errorBuilder: (_, _, _) =>
                        Text('RESIDE', style: AppTextStyles.logo),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Menu, new notifications',
                    child: const _MenuIconWithNotificationDot(),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

class _MenuIconWithNotificationDot extends StatelessWidget {
  const _MenuIconWithNotificationDot();

  @override
  Widget build(BuildContext context) {
    final w = 40.r;
    final line = 1.6.r;
    return SizedBox(
      width: w,
      height: 24.r,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 14.r,
            child: Container(width: w, height: line, color: AppColors.black),
          ),
          Positioned(
            right: 0,
            top: 20.r,
            child: Container(
              width: w * 0.68,
              height: line,
              color: AppColors.black,
            ),
          ),
          Positioned(
            right: 2.r,
            top: 0,
            child: Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
