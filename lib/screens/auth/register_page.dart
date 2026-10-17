import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/auth/register_model.dart';
import 'package:grahmitracus/providers/auth/register_provider.dart';
import 'package:grahmitracus/screens/auth/register_otp_screen.dart';

class RegisterPage extends StatefulWidget {
  final void Function(BuildContext context)? onLoginSuccess;

  const RegisterPage({super.key, this.onLoginSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _referralFocusNode = FocusNode();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final focusNodes = [
      _firstNameFocusNode,
      _lastNameFocusNode,
      _phoneFocusNode,
      _emailFocusNode,
      _passwordFocusNode,
      _referralFocusNode,
    ];
    for (var node in focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _referralFocusNode.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;
  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorToast(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            10.width,
            Expanded(
              child: Text(
                message,
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
  }

  void _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final referralCode = _referralController.text.trim();

    if (firstName.isEmpty) {
      _showErrorToast('Please enter your first name');
      return;
    }
    if (lastName.isEmpty) {
      _showErrorToast('Please enter your last name');
      return;
    }
    if (!_isPhoneValid) {
      _showErrorToast('Please enter a valid 10-digit mobile number');
      return;
    }
    if (!_isEmailValid) {
      _showErrorToast('Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      _showErrorToast('Password must be at least 6 characters');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final request = RegisterRequest(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      password: password,
    );

    await context.read<RegisterProvider>().registerRequest(
      request: request,
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

        final verifyData = RegisterVerifyRequest(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          password: password,
          accessToken: '',
          referralCode: referralCode.isNotEmpty ? referralCode : null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'RegisterOtpScreen'),
            builder: (context) => RegisterOtpScreen(
              registerData: verifyData,
              reqId: response.reqId,
              onLoginSuccess: widget.onLoginSuccess,
            ),
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        _showErrorToast(errorMessage);
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
                        _buildNameFields(),
                        16.height,
                        _buildPhoneInputField(),
                        16.height,
                        _buildInputField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          hintText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email_outlined,
                        ),
                        16.height,
                        _buildPasswordField(),
                        16.height,
                        _buildInputField(
                          controller: _referralController,
                          focusNode: _referralFocusNode,
                          hintText: 'Referral Code (Optional)',
                          keyboardType: TextInputType.text,
                          icon: Icons.card_giftcard_rounded,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const Spacer(),
                        _buildRegisterButton(),
                        12.height,
                        _buildLoginCta(),
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
          'Create Account',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        6.height,
        Text(
          'Enter your details to register as a customer',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            controller: _firstNameController,
            focusNode: _firstNameFocusNode,
            hintText: 'First Name',
            keyboardType: TextInputType.name,
            icon: Icons.person_outline_rounded,
          ),
        ),
        12.width,
        Expanded(
          child: _buildInputField(
            controller: _lastNameController,
            focusNode: _lastNameFocusNode,
            hintText: 'Last Name',
            keyboardType: TextInputType.name,
            icon: Icons.person_outline_rounded,
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
          color: _phoneFocusNode.hasFocus
              ? AppColors.brandPurple
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 16.sp)),
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
          8.width,
          Container(width: 1.2.w, height: 22.h, color: AppColors.borderSubtle),
          12.width,
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              cursorColor: AppColors.borderFocused,
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_phoneController.text.isNotEmpty)
            if (_isPhoneValid)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20.sp,
              )
            else
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _phoneController.clear();
                  setState(() {});
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

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputType keyboardType,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.brandPurple
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.iconSubtle, size: 20.sp),
          10.width,
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.borderFocused,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _passwordFocusNode.hasFocus
              ? AppColors.brandPurple
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0.h),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.iconSubtle,
            size: 20.sp,
          ),
          10.width,
          Expanded(
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _isPasswordObscured,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.borderFocused,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isPasswordObscured = !_isPasswordObscured;
              });
            },
            child: Icon(
              _isPasswordObscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.iconSubtle,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPurple,
          disabledBackgroundColor: AppColors.brandPurple.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(vertical: 10.h),
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
                'Register & Continue',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginCta() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Login',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.linkPurple,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
            ),
          ],
        ),
      ),
    );
  }
}
