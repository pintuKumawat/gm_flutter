import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 48.sp,
                color: AppColors.brandPurple,
              ),
            ),
            16.height,
            Text(
              'No Notifications',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            8.height,
            Text(
              "You're all caught up!\nNew updates and activity will appear here.",
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
