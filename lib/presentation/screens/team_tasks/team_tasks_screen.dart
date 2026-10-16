import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/duration_filter.dart';
import '../../../domain/entities/task.dart';
import '../../controllers/team_tasks_controller.dart';
import '../../widgets/screen_headers.dart';
import '../../widgets/buttons_cards_and_toggles.dart';
import '../../widgets/display_labels.dart';
import '../../widgets/loading_error_and_message_views.dart';
import '../../widgets/task_card.dart';
import '../add_task/add_task_sheet.dart';
import 'task_filter_sort_and_details_sheets.dart';

class TeamTasksScreen extends GetView<TeamTasksController> {
  const TeamTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TaskDisplayStatus.values.length,
      initialIndex: controller.initialStatusTab.index,
      child: Scaffold(
        floatingActionButton: AdminOnlyAddTaskButton(
          resolveInitialAssigneeId: () => controller.memberId,
        ),
        body: Column(
          children: [
            const BackButtonTitleHeader(title: 'Team’s Task'),
            Material(
              color: AppColors.background,
              child: TabBar(
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.tab.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTextStyles.tab,
                indicatorColor: AppColors.black,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.border,
                tabs: [
                  for (final status in TaskDisplayStatus.values)
                    Tab(height: 44.h, text: status.label.toUpperCase()),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => RoundedPillButton(
                        icon: Icons.filter_alt_outlined,
                        label: 'Filters',
                        badge: controller.activeFilter.value.activeFilterCount,
                        onPressed: () =>
                            showTaskFilterSheet(context, controller),
                      ),
                    ),
                  ),
                  SizedBox(width: 30.w),
                  Expanded(
                    child: RoundedPillButton(
                      icon: Icons.unfold_more_rounded,
                      label: 'Sort',
                      onPressed: () => showTaskSortSheet(context, controller),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final caption = _buildScopeCaptionText();
              if (caption == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    caption,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
            Expanded(
              child: LoadingErrorContentSwitcher(
                status: controller.loadStatus,
                errorMessage: controller.errorMessage,
                onRetry: controller.loadTasks,
                builder: (_) => TabBarView(
                  children: [
                    for (final status in TaskDisplayStatus.values)
                      _TaskListForStatusTab(statusTab: status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _buildScopeCaptionText() {
    final memberId = controller.memberId;
    final duration = controller.selectedDuration.value;
    if (memberId == null && duration == DurationFilter.today) return null;
    final member = memberId == null
        ? 'All members'
        : controller.findMemberById(memberId)?.name ?? 'Member';
    return '$member · ${duration.label}';
  }
}

class _TaskListForStatusTab extends GetView<TeamTasksController> {
  const _TaskListForStatusTab({required this.statusTab});

  final TaskDisplayStatus statusTab;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = controller.tasksForStatus(statusTab);
      final now = controller.tasksLoadedAt.value;
      final filtered = controller.activeFilter.value.activeFilterCount > 0;
      return RefreshIndicator(
        color: AppColors.black,
        onRefresh: () => controller.loadTasks(showLoader: false),
        child: tasks.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: CenteredMessageView(
                      icon: Icons.inbox_outlined,
                      title: 'No ${statusTab.label.toLowerCase()} tasks',
                      message: filtered
                          ? 'Try clearing filters or choosing another duration.'
                          : 'Try choosing another duration.',
                      actionLabel: filtered ? 'Clear filters' : null,
                      onAction: filtered ? controller.clearFilters : null,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => SizedBox(height: 24.h),
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  return TaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    now: now,
                    assignee: controller.findMemberById(task.assigneeId),
                    onTap: () => showTaskDetailsAndActionsSheet(
                      context,
                      controller,
                      task,
                    ),
                  );
                },
              ),
      );
    });
  }
}
