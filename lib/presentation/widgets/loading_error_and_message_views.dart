import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/screen_load_status.dart';

class CenteredLoadingIndicator extends StatelessWidget {
  const CenteredLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2.5),
  );
}

class CenteredMessageView extends StatelessWidget {
  const CenteredMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.r, color: AppColors.textMuted),
            SizedBox(height: 16.h),
            Text(
              title,
              style: AppTextStyles.memberName,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 8.h),
              Text(
                message!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 20.h),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.borderStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                child: Text(actionLabel!, style: AppTextStyles.button),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorMessageWithRetryButton extends StatelessWidget {
  const ErrorMessageWithRetryButton({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CenteredMessageView(
    icon: Icons.error_outline_rounded,
    title: 'Something went wrong',
    message: message,
    actionLabel: 'Retry',
    onAction: onRetry,
  );
}

class LoadingErrorContentSwitcher extends StatelessWidget {
  const LoadingErrorContentSwitcher({
    super.key,
    required this.status,
    required this.errorMessage,
    required this.onRetry,
    required this.builder,
  });

  final Rx<ScreenLoadStatus> status;
  final RxString errorMessage;
  final VoidCallback onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => switch (status.value) {
        ScreenLoadStatus.loading => const CenteredLoadingIndicator(),
        ScreenLoadStatus.error => ErrorMessageWithRetryButton(
          message: errorMessage.value,
          onRetry: onRetry,
        ),
        ScreenLoadStatus.success => builder(context),
      },
    );
  }
}
