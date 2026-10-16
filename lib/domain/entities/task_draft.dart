import '../../core/error/app_exception.dart';

class TaskTemplate {
  const TaskTemplate({required this.id, required this.title, this.description});

  final String id;
  final String title;
  final String? description;
}

enum TaskField { assignee, title, description, dueAt }

class TaskDraft {
  const TaskDraft({
    required this.assigneeId,
    required this.title,
    this.description = '',
    required this.dueAt,
  });

  final String? assigneeId;
  final String title;
  final String description;
  final DateTime? dueAt;

  static const int minTitleLength = 3;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 500;

  Map<TaskField, String> validate({
    required Set<String> memberIds,
    required DateTime now,
  }) {
    final errors = <TaskField, String>{};

    final assignee = assigneeId;
    if (assignee == null || assignee.isEmpty) {
      errors[TaskField.assignee] = 'Select a team member.';
    } else if (!memberIds.contains(assignee)) {
      errors[TaskField.assignee] = 'This team member no longer exists.';
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      errors[TaskField.title] = 'Enter a task title or pick a template.';
    } else if (trimmedTitle.length < minTitleLength) {
      errors[TaskField.title] =
          'Title must be at least $minTitleLength characters.';
    } else if (trimmedTitle.length > maxTitleLength) {
      errors[TaskField.title] =
          'Title must be $maxTitleLength characters or fewer.';
    }

    if (description.trim().length > maxDescriptionLength) {
      errors[TaskField.description] =
          'Description must be $maxDescriptionLength characters or fewer.';
    }

    final due = dueAt;
    if (due == null) {
      errors[TaskField.dueAt] = 'Select a due date and time.';
    } else if (!due.isAfter(now)) {
      errors[TaskField.dueAt] = 'Due date must be in the future.';
    }

    return errors;
  }
}

class TaskValidationException extends AppException {
  const TaskValidationException(this.errors)
    : super('Please fix the highlighted fields.');

  final Map<TaskField, String> errors;
}
