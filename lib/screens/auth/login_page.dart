import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/auth/send_otp_provider.dart';
import 'package:grahmitracus/screens/auth/otp_screen.dart';
import 'package:grahmitracus/screens/auth/register_page.dart';

class LoginPage extends StatefulWidget {
  final void Function(BuildContext context)? onLoginSuccess;

  const LoginPage({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _referralFocusNode = FocusNode();

  bool _isReferralExpanded = false;
  bool _isPhoneFocused = false;
  bool _isLoading = false;
  bool _isReferralApplied = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });
    _phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    _phoneFocusNode.dispose();
    _referralFocusNode.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;

  void _handleContinue() async {
    final phone = _phoneController.text.trim();
    if (!_isPhoneValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              10.width,
              Expanded(
                child: Text(
                  'Please enter a valid 10-digit mobile number',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final referralCode =
        _isReferralApplied ? _referralController.text.trim() : null;

    await context.read<SendOtpProvider>().sendOtp(
      phone: phone,
      onSuccess: (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                10.width,
                Expanded(
                  child: Text(
                    response.message.isNotEmpty
                        ? response.message
                        : 'OTP sent successfully to +91 $phone',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'OtpScreen'),
            builder: (context) => OtpScreen(
              phoneNumber: phone,
              reqId: response.reqId,
              referralCode: referralCode,
              onLoginSuccess: widget.onLoginSuccess,
            ),
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                10.width,
                Expanded(
                  child: Text(
                    errorMessage,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _applyReferralCode() {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isReferralApplied = true;
    });
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Referral code "$code" applied successfully!',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }

  void _showPolicySheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 36.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              20.height,
              Text(
                title,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              12.height,
              Text(
                content,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              24.height,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'I Understand',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              40.height,
              _buildLogo(),
              36.height,
              _buildHeader(),
              30.height,
              _buildPhoneInputField(),
              16.height,
              _buildReferralField(),
              120.height,
              _buildContinueButton(),
              32.height,
              _buildTermsText(),
              20.height,
              _buildRegisterCta(),
              24.height,
            ],
          ),
        ),
      ),
    );
  }

  /// Register CTA at the bottom of Login Screen
  Widget _buildRegisterCta() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          children: [
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Register',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.linkPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'RegisterPage'),
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Brand Logo: "grah mitra" with dual-color typography
  Widget _buildLogo() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'grah ',
            style: AppTextStyles.poppins(
              fontSize: 34.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandPurple,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'mitra',
            style: AppTextStyles.poppins(
              fontSize: 34.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandOrange,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Header: Title & Subtitle with native hierarchy
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to GrahMitra',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        8.height,
        Text(
          'Enter your mobile number to get started',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  /// 3. Mobile Number Input Field with Indian Flag, +91, and GREEN Check Icon
  Widget _buildPhoneInputField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isPhoneFocused
              ? AppColors.borderFocused
              : AppColors.borderPrimary,
          width: _isPhoneFocused ? 2.0 : 1.8,
        ),
        boxShadow: _isPhoneFocused
            ? [
                BoxShadow(
                  color: AppColors.borderPrimary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🇮🇳',
                  style: TextStyle(fontSize: 16.sp),
                ),
                6.width,
                Text(
                  '+91',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          8.width,
          Container(
            width: 1.2.w,
            height: 22.h,
            color: AppColors.borderSubtle,
          ),
          12.width,
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              cursorColor: AppColors.borderFocused,
              cursorWidth: 2.0,
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          if (_phoneController.text.isNotEmpty)
            if (_isPhoneValid)
              // GREEN checkmark when 10 numbers are entered
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22.sp,
              )
            else
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _phoneController.clear();
                },
                child: Icon(
                  Icons.cancel_rounded,
                  color: AppColors.iconSubtle,
                  size: 18.sp,
                ),
              ),
        ],
      ),
    );
  }

  /// 4. Referral Code Section with Interactive Tap & Apply Action
  Widget _buildReferralField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _isReferralApplied
            ? AppColors.brandPurple.withValues(alpha: 0.05)
            : AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isReferralApplied
              ? AppColors.brandPurple
              : (_isReferralExpanded
                  ? AppColors.borderPrimary
                  : AppColors.borderSubtle),
          width: 1.4,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: _isReferralApplied
          ? Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.brandPurple,
                  size: 20.sp,
                ),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REFERRAL APPLIED',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _referralController.text.toUpperCase(),
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isReferralApplied = false;
                      _referralController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.textSecondary,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: _isReferralExpanded
                      ? AppColors.brandPurple
                      : AppColors.iconSubtle,
                  size: 20.sp,
                ),
                10.width,
                Expanded(
                  child: _isReferralExpanded
                      ? TextField(
                          controller: _referralController,
                          focusNode: _referralFocusNode,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.0,
                          ),
                          cursorColor: AppColors.brandPurple,
                          decoration: InputDecoration(
                            hintText: 'ENTER REFERRAL CODE',
                            hintStyle: AppTextStyles.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isReferralExpanded = true;
                            });
                            _referralFocusNode.requestFocus();
                          },
                          child: Text(
                            'REFERRAL CODE?',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
                if (_isReferralExpanded)
                  GestureDetector(
                    onTap: _applyReferralCode,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'APPLY',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isReferralExpanded = true;
                      });
                      _referralFocusNode.requestFocus();
                    },
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.iconSubtle,
                      size: 18.sp,
                    ),
                  ),
              ],
            ),
    );
  }

  /// 5. Continue Button with State Feedback and Smooth Elevation
  Widget _buildContinueButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isPhoneValid ? 1.0 : 0.85,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleContinue,
            borderRadius: BorderRadius.circular(18.r),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.buttonGradientStart,
                    AppColors.buttonGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonShadow,
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'Continue',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      8.width,
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 6. Footer: Interactive Terms & Privacy policy links
  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.linkPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.selectionClick();
                  _showPolicySheet(
                    'Terms of Service',
                    'By utilizing the GrahMitra application, you acknowledge and agree to comply with our community terms, usage policies, and service standards.',
                  );
                },
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.linkPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.selectionClick();
                  _showPolicySheet(
                    'Privacy Policy',
                    'Your data privacy is our top priority. We do not share your private contact information with unauthorized third parties without your direct consent.',
                  );
                },
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}