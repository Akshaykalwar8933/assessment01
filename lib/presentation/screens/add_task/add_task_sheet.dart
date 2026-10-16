import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_draft.dart';
import '../../../domain/services/clock.dart';
import '../../controllers/add_task_controller.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/team_member_avatar.dart';
import '../../widgets/loading_error_and_message_views.dart';

Future<void> showAddTaskSheet(
  BuildContext context, {
  String? initialAssigneeId,
}) async {
  final session = Get.find<SessionController>();
  if (!session.isAdmin) {
    Get.snackbar('Not allowed', 'Only admins can create and assign tasks.');
    return;
  }
  final created = await showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddTaskBottomSheet(initialAssigneeId: initialAssigneeId),
  );
  if (created != null) {
    Get.snackbar(
      'Task added',
      '“${created.title}” has been assigned.',
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.r),
      backgroundColor: AppColors.black,
      colorText: AppColors.white,
    );
  }
}

class _AddTaskBottomSheet extends StatefulWidget {
  const _AddTaskBottomSheet({this.initialAssigneeId});

  final String? initialAssigneeId;

  @override
  State<_AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<_AddTaskBottomSheet> {
  final String _tag = UniqueKey().toString();
  late final AddTaskController _controller;
  final _titleField = TextEditingController();
  final _descriptionField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      AddTaskController(
        createTask: Get.find(),
        taskRepository: Get.find(),
        teamRepository: Get.find(),
        session: Get.find(),
        initialAssigneeId: widget.initialAssigneeId,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    _titleField.dispose();
    _descriptionField.dispose();
    Get.delete<AddTaskController>(tag: _tag);
    super.dispose();
  }

  void _applySelectedTemplate(TaskTemplate? template) {
    _controller.selectTemplate(template);
    if (template != null) {
      _titleField.text = _controller.title.value;
      _descriptionField.text = _controller.description.value;
    }
  }

  Future<void> _pickDueDateAndTime() async {
    final now = Get.find<Clock>().now();
    final current = _controller.dueAt.value;
    final date = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select due date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: 'Select due time',
    );
    if (time == null) return;
    _controller.selectDueDateTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _submitAndCloseOnSuccess() async {
    FocusScope.of(context).unfocus();
    final task = await _controller.submitNewTask();
    if (task != null && mounted) Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Obx(() {
        if (_controller.isLoadingFormOptions.value) {
          return SizedBox(
            height: 240.h,
            child: const CenteredLoadingIndicator(),
          );
        }
        final loadError = _controller.formOptionsLoadError.value;
        if (loadError != null) {
          return SizedBox(
            height: 320.h,
            child: ErrorMessageWithRetryButton(
              message: loadError,
              onRetry: _controller.loadFormOptions,
            ),
          );
        }
        return _buildAddTaskForm(context);
      }),
    );
  }

  Widget _buildAddTaskForm(BuildContext context) {
    final addTaskController = _controller;
    final errors = addTaskController.fieldErrors;
    final submitting = addTaskController.isSubmitting.value;
    final due = addTaskController.dueAt.value;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Task', style: AppTextStyles.sectionTitle),
          SizedBox(height: 4.h),
          Text(
            'Create a task and assign it to a team member.',
            style: AppTextStyles.bodySmall,
          ),
          SizedBox(height: 20.h),
          const _FormFieldLabel('Assign to', required: true),
          DropdownButtonFormField<String>(
            initialValue: addTaskController.assigneeId.value,
            isExpanded: true,
            hint: const Text('Select team member'),
            decoration: InputDecoration(errorText: errors[TaskField.assignee]),
            items: [
              for (final m in addTaskController.teamMembers)
                DropdownMenuItem(
                  value: m.id,
                  child: Row(
                    children: [
                      TeamMemberAvatar(member: m, size: 24.r),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: Text(
                          m.name,
                          style: AppTextStyles.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: submitting ? null : addTaskController.selectAssignee,
          ),
          if (addTaskController.taskTemplates.isNotEmpty) ...[
            SizedBox(height: 16.h),
            const _FormFieldLabel('Template'),
            DropdownButtonFormField<TaskTemplate?>(
              initialValue: addTaskController.selectedTemplate.value,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Custom task', style: AppTextStyles.body),
                ),
                for (final t in addTaskController.taskTemplates)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.title,
                      style: AppTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: submitting ? null : _applySelectedTemplate,
            ),
          ],
          SizedBox(height: 16.h),
          const _FormFieldLabel('Task title', required: true),
          TextField(
            controller: _titleField,
            enabled: !submitting,
            textCapitalization: TextCapitalization.sentences,
            maxLength: TaskDraft.maxTitleLength,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'e.g. Schedule a site visit',
              errorText: errors[TaskField.title],
              counterText: '',
            ),
            onChanged: addTaskController.updateTitle,
          ),
          SizedBox(height: 16.h),
          const _FormFieldLabel('Description'),
          TextField(
            controller: _descriptionField,
            enabled: !submitting,
            minLines: 2,
            maxLines: 4,
            maxLength: TaskDraft.maxDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Add details (optional)',
              errorText: errors[TaskField.description],
            ),
            onChanged: addTaskController.updateDescription,
          ),
          SizedBox(height: 8.h),
          const _FormFieldLabel('Due date & time', required: true),
          InkWell(
            onTap: submitting ? null : _pickDueDateAndTime,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              isEmpty: due == null,
              decoration: InputDecoration(
                hintText: 'Select date & time',
                errorText: errors[TaskField.dueAt],
                suffixIcon: const Icon(Icons.event_outlined),
              ),
              child: due == null
                  ? null
                  : Text(
                      DateFormat('EEE, d MMM y · h:mm a').format(due),
                      style: AppTextStyles.body,
                    ),
            ),
          ),
          if (addTaskController.submitError.value != null) ...[
            SizedBox(height: 16.h),
            Text(
              addTaskController.submitError.value!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.crimson),
            ),
          ],
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    minimumSize: Size(0, 46.h),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  child: Text('Cancel', style: AppTextStyles.button),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  onPressed: submitting ? null : _submitAndCloseOnSuccess,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.black,
                    disabledBackgroundColor: AppColors.textSecondary,
                    minimumSize: Size(0, 46.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  child: submitting
                      ? SizedBox.square(
                          dimension: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Add Task',
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
    );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.crimson),
              ),
          ],
        ),
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
