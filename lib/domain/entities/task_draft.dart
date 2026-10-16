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
}

class TaskValidationException extends AppException {
  const TaskValidationException(this.errors)
    : super('Please fix the highlighted fields.');

  final Map<TaskField, String> errors;
}
