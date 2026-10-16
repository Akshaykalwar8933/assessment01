import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import 'app_exception.dart';


const String genericErrorMessage = 'Something went wrong. Please try again.';

String userFacingMessageFor(Object error, [StackTrace? stackTrace]) {
  if (error is AppException) return error.message;
  logError(error, stackTrace);
  return genericErrorMessage;
}

void logError(Object error, [StackTrace? stackTrace]) {
  developer.log(
    'Unexpected error',
    name: 'reside',
    error: error,
    stackTrace: stackTrace,
  );
}

String? _lastSnackbarKey;
DateTime _lastSnackbarAt = DateTime.fromMillisecondsSinceEpoch(0);

void showErrorSnackbar(String message, {String title = 'Error'}) {
  final now = DateTime.now();
  final key = '$title|$message';
  if (key == _lastSnackbarKey &&
      now.difference(_lastSnackbarAt) < const Duration(seconds: 3)) {
    return;
  }
  _lastSnackbarKey = key;
  _lastSnackbarAt = now;
  _showSnackbar(
    title: title,
    message: message,
    backgroundColor: AppColors.crimson,
    icon: Icons.error_outline_rounded,
  );
}

void showSuccessSnackbar(String message, {String title = 'Done'}) {
  _showSnackbar(
    title: title,
    message: message,
    backgroundColor: AppColors.black,
    icon: Icons.check_circle_outline_rounded,
  );
}

void _showSnackbar({
  required String title,
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  void show() {
    // No navigator yet (e.g. during startup): nothing to show it on.
    if (Get.key.currentContext == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      backgroundColor: backgroundColor,
      colorText: AppColors.white,
      icon: Icon(icon, color: AppColors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
    );
  }

  // Showing an overlay while a frame is being built throws, so defer it.
  if (SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => show());
  } else {
    show();
  }
}

void installGlobalErrorHandlers() {
  ErrorWidget.builder = (details) => BuildErrorFallback(details: details);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = handleUncaughtError;
}

bool handleUncaughtError(Object error, StackTrace stackTrace) {
  showErrorSnackbar(userFacingMessageFor(error, stackTrace));
  return true;
}

class BuildErrorFallback extends StatelessWidget {
  const BuildErrorFallback({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.background,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This section could not be displayed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.crimson,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
