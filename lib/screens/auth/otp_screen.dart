import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/auth/send_otp_provider.dart';
import 'package:grahmitracus/providers/auth/verify_otp_provider.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/screens/main_nav/main_navigation_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? reqId;
  final String? referralCode;
  final void Function(BuildContext context)? onLoginSuccess;

  const OtpScreen({
    super.key,
    this.phoneNumber = '8740929857',
    this.reqId,
    this.referralCode,
    this.onLoginSuccess,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  int _countdownSeconds = 59;
  Timer? _timer;
  String? _currentReqId;

  @override
  void initState() {
    super.initState();
    _currentReqId = widget.reqId;
    _startResendTimer();
    // Auto-focus on first OTP digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _countdownSeconds = 59;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  bool get _isOtpComplete => _enteredOtp.length == 4;

  void _handleVerify() async {
    if (!_isOtpComplete) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              10.width,
              Expanded(
                child: Text(
                  'Please enter complete 4-digit OTP',
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

    await context.read<VerifyOtpProvider>().verifyOtp(
      phone: widget.phoneNumber,
      otp: _enteredOtp,
      reqId: _currentReqId,
      referralCode: widget.referralCode,
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
                        : 'OTP Verified Successfully! Welcome to GrahMitra.',
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

        context.read<ProfileProvider>().fetchProfile();

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
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

  void _handleResend() async {
    if (_countdownSeconds > 0) return;

    HapticFeedback.mediumImpact();
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    await context.read<SendOtpProvider>().sendOtp(
      phone: widget.phoneNumber,
      onSuccess: (response) {
        if (!mounted) return;
        setState(() {
          _currentReqId = response.reqId;
        });
        _startResendTimer();
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
                        : 'New OTP sent successfully to +91 ${widget.phoneNumber}',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
              32.height,
              _buildOtpInput(),
              140.height,
              _buildVerifyButton(),
              36.height,
              _buildBottomActions(),
              24.height,
            ],
          ),
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

  /// 2. Header: Title and subtitle with dynamic phone number
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify OTP',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        8.height,
        RichText(
          text: TextSpan(
            style: AppTextStyles.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'Enter the 4-digit OTP sent to '),
              TextSpan(
                text: '+91 ${widget.phoneNumber}',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. Modern 4-Digit OTP Input Container with Lock Icon & Digit Slots
  Widget _buildOtpInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isOtpComplete
              ? AppColors.success
              : AppColors.borderPrimary,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: _isOtpComplete
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.borderPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: _isOtpComplete
                ? AppColors.success
                : AppColors.brandPurple,
            size: 22.sp,
          ),
          12.width,
          Container(
            width: 1.2.w,
            height: 28.h,
            color: AppColors.borderSubtle,
          ),
          12.width,
          // 4 Interactive Digit Slots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return _buildDigitBox(index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Digit Box inside OTP Input
  Widget _buildDigitBox(int index) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return Container(
      width: 40.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: hasValue
            ? AppColors.brandPurple.withValues(alpha: 0.06)
            : AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isFocused
              ? AppColors.borderFocused
              : (hasValue ? AppColors.borderPrimary : AppColors.borderSubtle),
          width: isFocused ? 2.0 : 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: AppTextStyles.plusJakartaSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.borderFocused,
        decoration: InputDecoration(
          hintText: '${index + 1}',
          hintStyle: AppTextStyles.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            HapticFeedback.selectionClick();
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _handleVerify();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
      ),
    );
  }

  /// 4. Verify & Login Button
  Widget _buildVerifyButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isOtpComplete ? 1.0 : 0.85,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleVerify,
            borderRadius: BorderRadius.circular(18.r),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
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
                        'Verify & Login',
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

  /// 5. Bottom Actions: "Change number" (left) & "Resend in 51s" / "Resend OTP" (right)
  Widget _buildBottomActions() {
    final canResend = _countdownSeconds == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Change number link
        Flexible(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
              child: Text(
                'Change number',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),

        // Resend Timer / Action
        Flexible(
          child: canResend
              ? InkWell(
                  onTap: _handleResend,
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                    child: Text(
                      'Resend OTP',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Resend in '),
                      TextSpan(
                        text: '${_countdownSeconds}s',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}