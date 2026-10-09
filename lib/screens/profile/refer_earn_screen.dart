import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  final String _referralCode = 'GM12345';
  final String _referralLink = 'grahmitra.com/refer/GM12345';

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.plusJakartaSans(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          margin: EdgeInsets.all(16.r),
        ),
      );
    });
  }

  void _shareReferral(BuildContext context) {
    final String shareMessage =
        'Join GrahMitra using my referral code $_referralCode and enjoy the available referral benefits. Link: $_referralLink';
    _copyToClipboard(context, shareMessage, 'Share message copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Refer & Earn',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '🎁',
                        style: TextStyle(fontSize: 48.sp),
                      ),
                    ),
                    24.height,
                    Text(
                      'Refer & Earn',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    12.height,
                    Text(
                      'Invite your friends and earn\nrewards together.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              32.height,
              
              // Code Section
              Text(
                'Your Referral Code',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              8.height,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.subtleBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _referralCode,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPurple,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: AppColors.textPrimary, size: 20.sp),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _copyToClipboard(context, _referralCode, 'Referral code copied');
                      },
                    ),
                  ],
                ),
              ),
              24.height,
              
              // Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _shareReferral(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Share & Earn',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              
              40.height,
              // How it Works
              Text(
                'How Refer & Earn Works',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              16.height,
              _buildStep(
                '01',
                'Invite your friends',
                'Share your referral code or link.',
              ),
              _buildStep(
                '02',
                'Your friend joins',
                'Your friend signs up using your referral.',
              ),
              _buildStep(
                '03',
                'Earn rewards',
                'You receive the applicable referral reward.',
              ),
              
              40.height,
              // History Section
              Text(
                'Referral History',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              24.height,
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48.sp,
                      color: AppColors.iconSubtle,
                    ),
                    16.height,
                    Text(
                      'No referrals yet',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    8.height,
                    Text(
                      'Invite your friends and start earning rewards.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              32.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.brandPurple,
              ),
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                4.height,
                Text(
                  title,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                4.height,
                Text(
                  subtitle,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
