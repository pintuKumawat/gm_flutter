import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';

class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({super.key});

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
          'Customer Support',
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
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.headset_mic_rounded,
                        color: AppColors.brandPurple,
                        size: 48.sp,
                      ),
                    ),
                    24.height,
                    Text(
                      'Need Help?',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    12.height,
                    Text(
                      'We\'re here to help you with your orders,\npayments, account, and other questions.',
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
              
              Text(
                'How can we help?',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              16.height,
              
              _buildSupportOption(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat with Support',
                subtitle: 'Get help from our support team',
                onTap: () {},
              ),
              _buildSupportOption(
                icon: Icons.phone_outlined,
                title: 'Call Customer Care',
                subtitle: 'Talk to our support team',
                onTap: () {},
              ),
              _buildSupportOption(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'Send us your query',
                onTap: () {},
              ),
              
              32.height,
              
              32.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.subtleBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.brandPurple,
                  size: 20.sp,
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    4.height,
                    Text(
                      subtitle,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconSubtle,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }


}
