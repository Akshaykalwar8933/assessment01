import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Montserrat';

  static TextStyle _base(double size, FontWeight weight, Color color) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        height: 1.25,
      );

  static TextStyle get pageTitle =>
      _base(24, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get sectionTitle =>
      _base(20, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get statValue =>
      _base(22, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get statLabel =>
      _base(16, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get body =>
      _base(16, FontWeight.w400, AppColors.textPrimary);
  static TextStyle get bodySmall =>
      _base(14, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get button => _base(14, FontWeight.w600, AppColors.black);
  static TextStyle get caption =>
      _base(12, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get memberName =>
      _base(16, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get chartTotal =>
      _base(40, FontWeight.w700, AppColors.black).copyWith(height: 1.1);
  static TextStyle get tab =>
      _base(14, FontWeight.w500, AppColors.textSecondary);
  static TextStyle get logo =>
      _base(20, FontWeight.w500, AppColors.black).copyWith(letterSpacing: 3.sp);
}
