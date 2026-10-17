import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/auth/send_otp_provider.dart';
import 'package:grahmitracus/providers/auth/verify_otp_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/providers/cart/order_provider.dart';
import 'package:grahmitracus/providers/profile/wallet_provider.dart';
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
  int _countdownSeconds = 60;
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
      _countdownSeconds = 60;
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
          content: Text(
            'Please enter complete 4-digit OTP',
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

    final locationProvider = context.read<LocationProvider>();

    await context.read<VerifyOtpProvider>().verifyOtp(
      phone: widget.phoneNumber,
      otp: _enteredOtp,
      reqId: _currentReqId,
      referralCode: widget.referralCode,
      locationProvider: locationProvider,
      onSuccess: (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message.isNotEmpty
                  ? response.message
                  : 'OTP Verified Successfully! Welcome to GrahMitra.',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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
            content: Text(
              displayMsg,
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
            content: Text(
              'New OTP sent successfully to +91 ${widget.phoneNumber}',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
          'OTP Verification',
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
          'We have sent a verification code to',
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
              '+91 ${widget.phoneNumber}',
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
            // Handle paste / autofill of multiple digits
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
                'Verify OTP',
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
