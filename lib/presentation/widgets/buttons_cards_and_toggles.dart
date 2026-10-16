import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TwoOptionSegmentedToggle<T> extends StatelessWidget {
  const TwoOptionSegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: option, value: label) in options.entries)
            Expanded(
              child: Semantics(
                selected: option == value,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    color: option == value
                        ? AppColors.black
                        : Colors.transparent,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: option == value
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: option == value
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CountSummaryCard extends StatelessWidget {
  const CountSummaryCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tint,
    this.trailing,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData? icon;
  final Color iconColor;
  final Color tint;

  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$value', style: AppTextStyles.statValue),
                      SizedBox(width: 14.w),
                      trailing ??
                          Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: BoxDecoration(
                              color: tint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 20.r, color: iconColor),
                          ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.statLabel,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FullWidthOutlinedArrowButton extends StatelessWidget {
  const FullWidthOutlinedArrowButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.white,
        minimumSize: Size(double.infinity, 46.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.r)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(letterSpacing: 0.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 24.r),
        ],
      ),
    );
  }
}

class RoundedPillButton extends StatelessWidget {
  const RoundedPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.background,
        minimumSize: Size(0, 40.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.r),
            SizedBox(width: 8.w),
            Text(label, style: AppTextStyles.button),
            if (badge > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$badge',
                  style: AppTextStyles.caption.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
