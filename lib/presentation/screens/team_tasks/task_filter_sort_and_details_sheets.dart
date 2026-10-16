import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/duration_filter.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_filter_and_sort.dart';
import '../../controllers/team_tasks_controller.dart';
import '../../widgets/duration_filter_dropdown.dart';
import '../../widgets/display_labels.dart';
import '../../widgets/team_member_avatar.dart';

Future<void> showTaskSortSheet(
  BuildContext context,
  TeamTasksController controller,
) async {
  final current = controller.sortOrder.value;
  final selected = await showModalBottomSheet<TaskSortOrder>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BottomSheetTitle('Sort by'),
          for (final sort in TaskSortOrder.values)
            ListTile(
              title: Text(sort.label, style: AppTextStyles.body),
              trailing: sort == current
                  ? Icon(
                      Icons.check_rounded,
                      size: 22.r,
                      color: AppColors.black,
                    )
                  : null,
              selected: sort == current,
              onTap: () => Navigator.pop(context, sort),
            ),
          SizedBox(height: 12.h),
        ],
      ),
    ),
  );
  if (selected != null) await controller.changeSortOrder(selected);
}

Future<void> showTaskFilterSheet(
  BuildContext context,
  TeamTasksController controller,
) async {
  final result = await showModalBottomSheet<(TaskFilter, DurationFilter)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TaskFilterBottomSheet(controller: controller),
  );
  if (result != null) {
    await controller.applyFilters(filter: result.$1, duration: result.$2);
  }
}

class _TaskFilterBottomSheet extends StatefulWidget {
  const _TaskFilterBottomSheet({required this.controller});

  final TeamTasksController controller;

  @override
  State<_TaskFilterBottomSheet> createState() => _TaskFilterBottomSheetState();
}

class _TaskFilterBottomSheetState extends State<_TaskFilterBottomSheet> {
  late Set<String> _assignees = {
    ...widget.controller.activeFilter.value.assigneeIds,
  };
  late DueDateFilter _due = widget.controller.activeFilter.value.dueDateFilter;
  late DurationFilter _duration = widget.controller.selectedDuration.value;

  @override
  Widget build(BuildContext context) {
    final showAssignees = widget.controller.memberId == null;
    final members = widget.controller.membersById.values.toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BottomSheetTitle('Filters', padding: EdgeInsets.zero),
              SizedBox(height: 16.h),
              _FilterSectionLabel('Duration'),
              DurationFilterDropdown(
                isFullWidth: true,
                value: _duration,
                onChanged: (d) => setState(() => _duration = d),
              ),
              if (showAssignees) ...[
                SizedBox(height: 20.h),
                _FilterSectionLabel('Assignee'),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final m in members)
                      FilterChip(
                        avatar: TeamMemberAvatar(member: m, size: 22.r),
                        label: Text(
                          m.name,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        selected: _assignees.contains(m.id),
                        showCheckmark: false,
                        selectedColor: AppColors.yellowTint,
                        side: BorderSide(
                          color: _assignees.contains(m.id)
                              ? AppColors.black
                              : AppColors.border,
                        ),
                        onSelected: (on) => setState(
                          () => on
                              ? _assignees.add(m.id)
                              : _assignees.remove(m.id),
                        ),
                      ),
                  ],
                ),
              ],
              SizedBox(height: 20.h),
              _FilterSectionLabel('Due date'),
              Wrap(
                spacing: 8.w,
                children: [
                  for (final p in DueDateFilter.values)
                    ChoiceChip(
                      label: Text(
                        p.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      selected: _due == p,
                      showCheckmark: false,
                      selectedColor: AppColors.yellowTint,
                      side: BorderSide(
                        color: _due == p ? AppColors.black : AppColors.border,
                      ),
                      onSelected: (_) => setState(() => _due = p),
                    ),
                ],
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _assignees = {};
                        _due = DueDateFilter.any;
                      }),
                      style: _buttonStyle(filled: false),
                      child: Text('Reset', style: AppTextStyles.button),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, (
                        TaskFilter(
                          assigneeIds: _assignees,
                          dueDateFilter: _due,
                        ),
                        _duration,
                      )),
                      style: _buttonStyle(filled: true),
                      child: Text(
                        'Apply',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.white,
                        ),
                      ),
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

  ButtonStyle _buttonStyle({required bool filled}) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 46.h)),
    backgroundColor: WidgetStatePropertyAll(
      filled ? AppColors.black : AppColors.white,
    ),
    side: const WidgetStatePropertyAll(
      BorderSide(color: AppColors.borderStrong),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
    ),
  );
}

Future<void> showTaskDetailsAndActionsSheet(
  BuildContext context,
  TeamTasksController controller,
  Task task,
) async {
  final now = controller.tasksLoadedAt.value;
  final status = buildTaskStatusLabel(task, now);
  final assignee = controller.findMemberById(task.assigneeId);
  final dateFmt = DateFormat('d MMM y, h:mma');
  final shouldCloseTask = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.title, style: AppTextStyles.memberName),
            SizedBox(height: 12.h),
            Text(
              status.text,
              style: AppTextStyles.bodySmall.copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            if (assignee != null) _TaskDetailRow('Assignee', assignee.name),
            _TaskDetailRow('Created', dateFmt.format(task.createdAt)),
            _TaskDetailRow(
              'Due',
              task.dueAt == null ? 'No due date' : dateFmt.format(task.dueAt!),
            ),
            if (task.completedAt != null)
              _TaskDetailRow('Completed', dateFmt.format(task.completedAt!)),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, !task.isClosed),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.black,
                  minimumSize: Size(0, 46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                icon: Icon(
                  task.isClosed ? Icons.replay_rounded : Icons.check_rounded,
                ),
                label: Text(
                  task.isClosed ? 'Reopen task' : 'Mark as closed',
                  style: AppTextStyles.button.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (shouldCloseTask != null) {
    await controller.updateTaskClosedStatus(task, closed: shouldCloseTask);
  }
}

class _BottomSheetTitle extends StatelessWidget {
  const _BottomSheetTitle(this.text, {this.padding});

  final String text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
    child: Text(text, style: AppTextStyles.sectionTitle),
  );
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96.w,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
