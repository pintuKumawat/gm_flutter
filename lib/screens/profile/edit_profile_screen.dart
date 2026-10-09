import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.white, size: 18.sp),
              10.width,
              Text(
                'Profile updated successfully!',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.r),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = provider.saveError ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.white, size: 18.sp),
              10.width,
              Expanded(
                child: Text(
                  err,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.r),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.screenTitle),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isSaving ? null : _save,
                child: provider.isSaving
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandPurple,
                        ),
                      )
                    : Text(
                        'Save',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandPurple,
                        ),
                      ),
              );
            },
          ),
          8.width,
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar header
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 52.sp,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ),
                  20.height,

                  Text(
                    'Personal Information',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  10.height,

                  // First Name
                  _buildField(
                    controller: _firstNameCtrl,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  14.height,

                  // Last Name
                  _buildField(
                    controller: _lastNameCtrl,
                    label: 'Last Name',
                    hint: 'Enter your last name (optional)',
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  14.height,

                  // Email
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'Enter your email (optional)',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  24.height,

                  // Phone (read-only info)
                  Consumer<ProfileProvider>(
                    builder: (context, provider, _) {
                      final phone = provider.user?.phone ?? '—';
                      return Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 18.sp,
                                color: AppColors.textSecondary),
                            10.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mobile Number',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                4.height,
                                Text(
                                  phone,
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.brandPurple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Verified',
                                style: AppTextStyles.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  30.height,

                  // Save Button
                  Consumer<ProfileProvider>(
                    builder: (context, provider, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPurple,
                            disabledBackgroundColor:
                                AppColors.brandPurple.withValues(alpha: 0.5),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: provider.isSaving
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        6.height,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.plusJakartaSans(
              fontSize: 13.5.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(icon,
                size: 18.sp, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.subtleBackground,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: AppColors.brandPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: AppTextStyles.plusJakartaSans(
              fontSize: 11.sp,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
