class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'AppException: $message'
      : 'AppException: $message ($cause)';
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    super.message = 'You do not have permission to do this.',
  ]);
}
