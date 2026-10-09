import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
              Text(
                'Privacy Policy',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              8.height,
              Text(
                'Last Updated: [Placeholder Date]',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              24.height,
              _buildPolicySection(
                title: '1. Introduction',
                content:
                    'At GrahMitra, your privacy is strictly protected. We do not sell your personal data. Your data privacy is our top priority. We do not share your private contact information with unauthorized third parties without your direct consent. [Additional content to be provided]',
              ),
              _buildPolicySection(
                title: '2. Information We Collect',
                content: '[Placeholder content for Information We Collect]',
              ),
              _buildPolicySection(
                title: '3. How We Use Your Information',
                content: '[Placeholder content for How We Use Your Information]',
              ),
              _buildPolicySection(
                title: '4. Information Sharing',
                content: '[Placeholder content for Information Sharing]',
              ),
              _buildPolicySection(
                title: '5. Data Security',
                content: '[Placeholder content for Data Security]',
              ),
              _buildPolicySection(
                title: '6. Your Rights',
                content: '[Placeholder content for Your Rights]',
              ),
              _buildPolicySection(
                title: '7. Cookies and Tracking',
                content: '[Placeholder content for Cookies and Tracking]',
              ),
              _buildPolicySection(
                title: '8. Third-Party Services',
                content: '[Placeholder content for Third-Party Services]',
              ),
              _buildPolicySection(
                title: '9. Children\'s Privacy',
                content: '[Placeholder content for Children\'s Privacy]',
              ),
              _buildPolicySection(
                title: '10. Changes to This Privacy Policy',
                content: '[Placeholder content for Changes to This Privacy Policy]',
              ),
              _buildPolicySection(
                title: '11. Contact Us',
                content: '[Please contact Customer Support for privacy inquiries]',
              ),
              32.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          8.height,
          Text(
            content,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
