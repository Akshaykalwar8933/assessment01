import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/usecases/team_usecases.dart';
import 'session_controller.dart';

class AddTaskController extends GetxController {
  AddTaskController({
    required CreateTask createTask,
    required GetTaskTemplates getTaskTemplates,
    required GetTeamMembers getTeamMembers,
    required SessionController session,
    String? initialAssigneeId,
  }) : _createTask = createTask,
       _getTaskTemplates = getTaskTemplates,
       _getTeamMembers = getTeamMembers,
       _session = session,
       assigneeId = RxnString(initialAssigneeId);

  final CreateTask _createTask;
  final GetTaskTemplates _getTaskTemplates;
  final GetTeamMembers _getTeamMembers;
  final SessionController _session;

  final isLoadingFormOptions = true.obs;
  final formOptionsLoadError = RxnString();
  final teamMembers = <TeamMember>[].obs;
  final taskTemplates = <TaskTemplate>[].obs;

  final RxnString assigneeId;
  final selectedTemplate = Rxn<TaskTemplate>();
  final title = ''.obs;
  final description = ''.obs;
  final dueAt = Rxn<DateTime>();

  final isSubmitting = false.obs;
  final fieldErrors = <TaskField, String>{}.obs;

  final submitError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadFormOptions();
  }

  Future<void> loadFormOptions() async {
    isLoadingFormOptions.value = true;
    formOptionsLoadError.value = null;
    try {
      teamMembers.assignAll(await _getTeamMembers());
      taskTemplates.assignAll(await _getTaskTemplates());
      if (!teamMembers.any((m) => m.id == assigneeId.value)) {
        assigneeId.value = null;
      }
    } on AppException catch (e) {
      formOptionsLoadError.value = e.message;
    } finally {
      isLoadingFormOptions.value = false;
    }
  }

  void selectAssignee(String? id) {
    assigneeId.value = id;
    fieldErrors.remove(TaskField.assignee);
  }

  void selectTemplate(TaskTemplate? value) {
    selectedTemplate.value = value;
    if (value != null) {
      title.value = value.title;
      description.value = value.description ?? '';
      fieldErrors
        ..remove(TaskField.title)
        ..remove(TaskField.description);
    }
  }

  void updateTitle(String value) {
    title.value = value;
    fieldErrors.remove(TaskField.title);
  }

  void updateDescription(String value) {
    description.value = value;
    fieldErrors.remove(TaskField.description);
  }

  void selectDueDateTime(DateTime value) {
    dueAt.value = value;
    fieldErrors.remove(TaskField.dueAt);
  }

  Future<Task?> submitNewTask() async {
    if (isSubmitting.value) return null; // Ignore double taps.
    submitError.value = null;
    try {
      _session.ensureCurrentUserIsAdmin();
      isSubmitting.value = true;
      final task = await _createTask(
        TaskDraft(
          assigneeId: assigneeId.value,
          title: title.value,
          description: description.value,
          dueAt: dueAt.value,
        ),
      );
      fieldErrors.clear();
      return task;
    } on TaskValidationException catch (e) {
      fieldErrors.assignAll(e.errors);
    } on AppException catch (e) {
      submitError.value = e.message;
    } finally {
      isSubmitting.value = false;
    }
    return null;
  }
}
