import '../entities/task_draft.dart';

class TaskDraftValidator {
  const TaskDraftValidator();

  static const int minTitleLength = 3;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 500;

  Map<TaskField, String> validateDraft(
    TaskDraft draft, {
    required Set<String> memberIds,
    required DateTime now,
  }) {
    final errors = <TaskField, String>{};

    final assignee = draft.assigneeId;
    if (assignee == null || assignee.isEmpty) {
      errors[TaskField.assignee] = 'Select a team member.';
    } else if (!memberIds.contains(assignee)) {
      errors[TaskField.assignee] = 'This team member no longer exists.';
    }

    final title = draft.title.trim();
    if (title.isEmpty) {
      errors[TaskField.title] = 'Enter a task title or pick a template.';
    } else if (title.length < minTitleLength) {
      errors[TaskField.title] =
          'Title must be at least $minTitleLength characters.';
    } else if (title.length > maxTitleLength) {
      errors[TaskField.title] =
          'Title must be $maxTitleLength characters or fewer.';
    }

    if (draft.description.trim().length > maxDescriptionLength) {
      errors[TaskField.description] =
          'Description must be $maxDescriptionLength characters or fewer.';
    }

    final due = draft.dueAt;
    if (due == null) {
      errors[TaskField.dueAt] = 'Select a due date and time.';
    } else if (!due.isAfter(now)) {
      errors[TaskField.dueAt] = 'Due date must be in the future.';
    }

    return errors;
  }
}
