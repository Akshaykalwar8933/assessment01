import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ResideLogoHeader extends StatelessWidget {
  const ResideLogoHeader({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  static const String _logoAsset = 'assets/images/reside_logo.png';

  static const double _logoAspectRatio = 266 / 36;

  @override
  Widget build(BuildContext context) {
    return _WhiteHeaderWithBottomDivider(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 22.h),
        child: Row(
          children: [
            Image.asset(
              _logoAsset,
              width: 104.w,
              height: 104.w / _logoAspectRatio,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'Reside',
              errorBuilder: (_, _, _) =>
                  Text('RESIDE', style: AppTextStyles.logo),
            ),
            const Spacer(),
            Semantics(
              button: onMenuPressed != null,
              label: 'Menu, new notifications',
              child: InkResponse(
                onTap: onMenuPressed,
                radius: 28.r,
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: const _MenuIconWithNotificationDot(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackButtonTitleHeader extends StatelessWidget {
  const BackButtonTitleHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _WhiteHeaderWithBottomDivider(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4.w, 12.h, 16.w, 12.h),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: Get.back,
              icon: Icon(Icons.chevron_left_rounded, size: 32.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteHeaderWithBottomDivider extends StatelessWidget {
  const _WhiteHeaderWithBottomDivider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [child, const Divider()],
        ),
      ),
    );
  }
}

class _MenuIconWithNotificationDot extends StatelessWidget {
  const _MenuIconWithNotificationDot();

  @override
  Widget build(BuildContext context) {
    final w = 40.r;
    final line = 1.6.r;
    return SizedBox(
      width: w,
      height: 24.r,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 14.r,
            child: Container(width: w, height: line, color: AppColors.black),
          ),
          Positioned(
            right: 0,
            top: 20.r,
            child: Container(
              width: w * 0.68,
              height: line,
              color: AppColors.black,
            ),
          ),
          Positioned(
            right: 2.r,
            top: 0,
            child: Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
