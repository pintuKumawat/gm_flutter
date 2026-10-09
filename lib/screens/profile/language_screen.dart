import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selected_language') ?? 'en';
    });
  }

  Future<void> _saveSelectedLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
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
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Language',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your preferred language',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              16.height,
              _buildLanguageOption(
                languageName: 'English',
                nativeName: 'English',
                languageCode: 'en',
              ),
              12.height,
              _buildLanguageOption(
                languageName: 'Hindi',
                nativeName: 'हिन्दी',
                languageCode: 'hi',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String languageName,
    required String nativeName,
    required String languageCode,
  }) {
    final isSelected = _selectedLanguage == languageCode;

    return InkWell(
      onTap: () => _saveSelectedLanguage(languageCode),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPurple.withValues(alpha: 0.05) : AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.brandPurple : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language_rounded,
              color: isSelected ? AppColors.brandPurple : AppColors.textSecondary,
              size: 24.sp,
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageName,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (languageName != nativeName) ...[
                    4.height,
                    Text(
                      nativeName,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandPurple,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
