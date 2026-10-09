export 'verify_msg91_model.dart';

/// Request model for verifying OTP and completing customer login.
class VerifyOtpRequest {
  final String phone;
  final String accessToken;
  final String? referralCode;

  const VerifyOtpRequest({
    required this.phone,
    required this.accessToken,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phone': phone,
      'accessToken': accessToken,
    };
    if (referralCode != null && referralCode!.trim().isNotEmpty) {
      map['referralCode'] = referralCode!.trim();
    }
    return map;
  }

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) {
    return VerifyOtpRequest(
      phone: json['phone'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? json['referral_code'] as String?,
    );
  }
}

/// Response model for OTP verification and login.
class VerifyOtpResponse {
  final bool success;
  final String message;
  final bool? isNewUser;
  final String? accessToken;
  final String? refreshToken;

  const VerifyOtpResponse({
    required this.success,
    required this.message,
    this.isNewUser,
    this.accessToken,
    this.refreshToken,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      isNewUser: json['isNewUser'] as bool? ?? json['is_new_user'] as bool?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'isNewUser': isNewUser,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}
