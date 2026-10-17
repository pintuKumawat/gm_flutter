import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/auth/send_otp_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:grahmitracus/screens/auth/register_page.dart';
import 'package:grahmitracus/screens/auth/otp_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  final void Function(BuildContext context)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  final TextEditingController _referralController = TextEditingController();
  final FocusNode _referralFocusNode = FocusNode();

  bool _isPhoneFocused = false;
  bool _isReferralFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });
    _referralFocusNode.addListener(() {
      setState(() {
        _isReferralFocused = _referralFocusNode.hasFocus;
      });
    });
    _phoneController.addListener(() {
      setState(() {});
    });
    _referralController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _referralController.dispose();
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
          content: Text(
            'Please enter a valid 10-digit mobile number',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    await context.read<SendOtpProvider>().sendOtp(
      phone: phone,
      onSuccess: (response) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'OtpScreen'),
            builder: (context) => OtpScreen(
              phoneNumber: phone,
              reqId: response.reqId,
              referralCode: _referralController.text.trim().isNotEmpty
                  ? _referralController.text.trim()
                  : null,
              onLoginSuccess: widget.onLoginSuccess,
            ),
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        20.height,
                        _buildLogo(),
                        20.height,
                        _buildHeader(),
                        24.height,
                        _buildPhoneInputField(),
                        16.height,
                        _buildReferralBox(),
                        5.height,
                        _buildRegisterText(),
                        const Spacer(),
                        _buildContinueButton(),
                        12.height,
                        _buildTermsText(),
                        20.height,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/Grahmitra_logo.png',
      height: 32.h,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to GrahMitra',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        4.height,
        Text(
          'Enter your phone number',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isPhoneFocused
              ? AppColors.brandPurple
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🇮🇳', style: TextStyle(fontSize: 22.sp)),
          12.width,
          Text(
            '+91',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          16.width,
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
                color: const Color(0xFF1E293B),
                letterSpacing: 1.0,
              ),
              cursorColor: AppColors.brandPurple,
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isPhoneValid && !_isLoading) ? _handleContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPurple,
          disabledBackgroundColor: AppColors.brandPurple.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Request OTP',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildReferralBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isReferralFocused
              ? AppColors.brandPurple
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            color: const Color(0xFF94A3B8),
            size: 20.sp,
          ),
          12.width,
          Expanded(
            child: TextField(
              controller: _referralController,
              focusNode: _referralFocusNode,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                letterSpacing: 1.0,
              ),
              cursorColor: AppColors.brandPurple,
              decoration: InputDecoration(
                hintText: 'REFERRAL CODE?',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          if (_referralController.text.isEmpty)
            Icon(
              Icons.add_circle_outline,
              color: const Color(0xFF94A3B8),
              size: 20.sp,
            ),
        ],
      ),
    );
  }

  Widget _buildRegisterText() {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          children: [
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Register',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RegisterPage(onLoginSuccess: widget.onLoginSuccess),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openPrivacyPolicy(context),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openPrivacyPolicy(context),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    HapticFeedback.selectionClick();
    try {
      final Uri url = Uri.parse('https://grahmitra.com/privacy-policy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Privacy Policy. Please try again.'),
          ),
        );
      }
    }
  }
}
