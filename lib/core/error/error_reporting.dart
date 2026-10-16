import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import 'app_exception.dart';

/// How errors reach the user: snackbars, a fallback for widgets that fail to
/// build (instead of Flutter's grey box in release mode), and app-wide
/// handlers for errors nothing else caught.

const String genericErrorMessage = 'Something went wrong. Please try again.';

/// Logs [error] and returns a message that is safe to show to users.
/// [AppException]s carry their own message; anything else is unexpected and
/// gets a generic one.
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

/// Red error snackbar. The same title and message within 3 seconds is shown
/// once, so a burst of identical failures does not stack snackbars.
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

/// Installs app-wide handlers. Call once in `main()` before `runApp`.
void installGlobalErrorHandlers() {
  // A widget that throws while building shows this instead of a grey box.
  ErrorWidget.builder = (details) => BuildErrorFallback(details: details);

  // Errors reported by the framework (build, layout, gestures).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logError(details.exception, details.stack);
  };

  // Uncaught errors from async code (futures, streams, timers).
  PlatformDispatcher.instance.onError = handleUncaughtError;
}

/// Returns true so the error counts as handled and the app keeps running.
bool handleUncaughtError(Object error, StackTrace stackTrace) {
  showErrorSnackbar(userFacingMessageFor(error, stackTrace));
  return true;
}

/// Shown in place of a widget that failed to build. Self-contained (no
/// ScreenUtil or theme lookups) because it may render anywhere in the tree.
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
                // Developers still see the cause in debug builds.
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
