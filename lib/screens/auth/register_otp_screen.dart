import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/auth/register_model.dart';
import 'package:grahmitracus/providers/auth/register_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/providers/cart/order_provider.dart';
import 'package:grahmitracus/providers/profile/wallet_provider.dart';
import 'package:grahmitracus/screens/main_nav/main_navigation_screen.dart';

class RegisterOtpScreen extends StatefulWidget {
  final RegisterVerifyRequest registerData;
  final String? reqId;
  final void Function(BuildContext context)? onLoginSuccess;

  const RegisterOtpScreen({
    super.key,
    required this.registerData,
    this.reqId,
    this.onLoginSuccess,
  });

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
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
    if (_isLoading) return;
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

    final request = RegisterVerifyRequest(
      firstName: widget.registerData.firstName,
      lastName: widget.registerData.lastName,
      phone: widget.registerData.phone,
      email: widget.registerData.email,
      password: widget.registerData.password,
      accessToken: _enteredOtp,
      referralCode: widget.registerData.referralCode,
    );

    final locationProvider = context.read<LocationProvider>();

    await context.read<RegisterProvider>().registerVerify(
      request: request,
      reqId: _currentReqId,
      locationProvider: locationProvider,
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
                        : 'Account created successfully! Welcome to GrahMitra.',
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

        final userId = AuthStorageService.extractUserId(response.accessToken ?? '');
        context.read<LocationProvider>().initUserSession(userId);
        context.read<OrderProvider>().initUserSession(userId);
        context.read<ProfileProvider>().fetchProfile();
        context.read<WalletProvider>().fetchWallet();

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
        final displayMsg = (errorMessage.toLowerCase().contains('invalid') || errorMessage.toLowerCase().contains('expired'))
            ? 'Invalid OTP. Please try again.'
            : errorMessage;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                10.width,
                Expanded(
                  child: Text(
                    displayMsg,
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

    final req = RegisterRequest(
      firstName: widget.registerData.firstName,
      lastName: widget.registerData.lastName,
      phone: widget.registerData.phone,
      email: widget.registerData.email,
      password: widget.registerData.password,
    );

    await context.read<RegisterProvider>().registerRequest(
      request: req,
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
                        : 'New OTP sent successfully to +91 ${widget.registerData.phone}',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify Registration OTP',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            children: [
              40.height,
              _buildHeader(),
              32.height,
              _buildOtpInputRow(),
              32.height,
              _buildBottomActions(),
              const Spacer(),
              _buildVerifyButton(),
              24.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Enter the 4-digit OTP sent to',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+91 ${widget.registerData.phone}',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            8.width,
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Text(
                'Edit',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPurple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpInputRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: _buildDigitBox(index),
        );
      }),
    );
  }

  Widget _buildDigitBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;

    return Container(
      width: 45.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isFocused ? AppColors.brandPurple : const Color(0xFFE2E8F0),
          width: 1.5,
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
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        cursorColor: AppColors.brandPurple,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.length > 1) {
            final digits = value.replaceAll(RegExp(r'\D'), '');
            for (int i = 0; i < digits.length && (index + i) < 4; i++) {
              _otpControllers[index + i].text = digits[i];
            }
            final nextFocus = (index + digits.length).clamp(0, 3);
            if (nextFocus < 3) {
              _focusNodes[nextFocus].requestFocus();
            } else {
              _focusNodes[3].unfocus();
            }
            setState(() {});
            if (_isOtpComplete && !_isLoading) {
              _handleVerify();
            }
            return;
          }

          if (value.isNotEmpty) {
            HapticFeedback.selectionClick();
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});

          if (_isOtpComplete && !_isLoading) {
            _handleVerify();
          }
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    final canResend = _countdownSeconds == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the OTP? ",
          style: AppTextStyles.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        GestureDetector(
          onTap: canResend ? _handleResend : null,
          child: Text(
            canResend ? 'Resend OTP' : 'Resend in ${_countdownSeconds}s',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: canResend ? AppColors.brandPurple : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isOtpComplete && !_isLoading) ? _handleVerify : null,
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
                'Verify & Create Account',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
