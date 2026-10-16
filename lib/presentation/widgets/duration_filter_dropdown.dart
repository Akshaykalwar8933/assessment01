import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/duration_filter.dart';
import 'display_labels.dart';

class DurationFilterDropdown extends StatelessWidget {
  const DurationFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isFullWidth = false,
  });

  final DurationFilter value;
  final ValueChanged<DurationFilter> onChanged;

  final bool isFullWidth;

  Future<void> _handleDurationOptionSelected(
    BuildContext context,
    DurationOption option,
  ) async {
    if (option != DurationOption.dateRange) {
      onChanged(DurationFilter.preset(option));
      return;
    }
    final now = DateTime.now();
    final initial = value.option == DurationOption.dateRange
        ? DateTimeRange(start: value.customStart!, end: value.customEnd!)
        : DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initial,
      helpText: 'Select date range',
    );
    if (picked != null) {
      onChanged(DurationFilter.custom(picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = isFullWidth && constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 130.w;
        return PopupMenuButton<DurationOption>(
          tooltip: 'Select duration',
          position: PopupMenuPosition.under,
          offset: Offset(0, 4.h),
          elevation: 2,
          menuPadding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: math.max(width, 130.w)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.r),
            side: const BorderSide(color: AppColors.border),
          ),
          onSelected: (option) =>
              _handleDurationOptionSelected(context, option),
          itemBuilder: (_) => [
            for (final option in DurationOption.values)
              PopupMenuItem(
                value: option,
                height: 40.h,
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: 40.h,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    border: option == DurationOption.values.last
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                  ),
                  child: Text(
                    option.label,
                    style: AppTextStyles.statLabel.copyWith(
                      color: option == value.option
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: option == value.option
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
          child: Container(
            width: isFullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: isFullWidth ? 14.h : 7.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: BorderRadius.circular(isFullWidth ? 4.r : 2.r),
            ),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Flexible(
                  fit: isFullWidth ? FlexFit.tight : FlexFit.loose,
                  child: Text(
                    value.label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: (isFullWidth ? 16 : 15).sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.keyboard_arrow_down_rounded, size: 22.r),
              ],
            ),
          ),
        );
      },
    );
  }
}
