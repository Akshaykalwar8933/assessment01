import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/task_stats.dart';
import '../../controllers/team_performance_controller.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/duration_filter_dropdown.dart';
import '../../widgets/team_member_avatar.dart';
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
          const CommonAppBar(title: 'Team Performance'),
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
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      12.h,
                      gutter,
                      32.h + MediaQuery.paddingOf(context).bottom,
                    ),
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
                  SizedBox(width: 8.w),
                  // Shows the card is tappable and leads to this member's tasks.
                  Semantics(
                    button: true,
                    label: 'View ${performance.member.name}’s tasks',
                    child: ExcludeSemantics(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10.w, 4.h, 4.w, 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View tasks',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18.r,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
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
                      _TaskStatusDonutChart(stats: stats, size: donut),
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
          _ChartLegendItem(
            color: AppColors.yellow,
            label: 'Open',
            value: stats.open,
          ),
          SizedBox(height: 28.h),
          _ChartLegendItem(
            color: AppColors.red,
            label: 'Overdue',
            value: stats.overdue,
          ),
          SizedBox(height: 28.h),
          _ChartLegendItem(
            color: AppColors.green,
            label: 'Closed',
            value: stats.closed,
          ),
        ],
      ),
    );
  }
}

class _TaskStatusDonutChart extends StatelessWidget {
  const _TaskStatusDonutChart({required this.stats, required this.size});

  final TaskStats stats;
  final double size;

  /// Gap between coloured segments, in degrees.
  static const double _gapDegrees = 8;

  // Gaps are transparent spacer sections rather than fl_chart's
  // `sectionsSpace`, which cuts them with `Path.combine`; Impeller (the
  // device renderer) draws any segment larger than half the ring as a
  // filled wedge after that cut.
  List<PieChartSectionData> _buildChartSections(double thickness) {
    PieChartSectionData ringSection(
      double value,
      Color color, {
      bool roundedEnds = false,
    }) => PieChartSectionData(
      value: value,
      color: color,
      radius: thickness,
      showTitle: false,
      cornerRadius: roundedEnds ? thickness / 2 : 0,
    );

    final segments = [
      (stats.overdue, AppColors.red),
      (stats.closed, AppColors.green),
      (stats.open, AppColors.yellow),
    ].where((s) => s.$1 > 0).toList();

    if (segments.isEmpty) return [ringSection(1, AppColors.border)];
    if (segments.length == 1) {
      return [ringSection(segments.single.$1.toDouble(), segments.single.$2)];
    }

    final total = segments.fold<int>(0, (sum, s) => sum + s.$1);
    final gapValue =
        total * _gapDegrees / (360 - segments.length * _gapDegrees);
    return [
      for (final (value, color) in segments) ...[
        ringSection(value.toDouble(), color, roundedEnds: true),
        ringSection(gapValue, Colors.transparent),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final thickness = size * 0.05;
    return Semantics(
      label:
          '${stats.total} tasks: ${stats.open} open, ${stats.overdue} overdue, '
          '${stats.closed} closed',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: _buildChartSections(thickness),
                // Centre the first gap at the top of the ring.
                startDegreeOffset: 270 + _gapDegrees / 2,
                centerSpaceRadius: size / 2 - thickness,
                sectionsSpace: 0,
                pieTouchData: PieTouchData(enabled: false),
              ),
              duration: const Duration(milliseconds: 300),
            ),
            ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${stats.total}',
                      style: AppTextStyles.chartTotal.copyWith(
                        fontSize: size * 0.24,
                      ),
                    ),
                  ),
                  Text(
                    'Tasks',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.r,
          height: 14.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppTextStyles.caption.copyWith(fontSize: 13.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
