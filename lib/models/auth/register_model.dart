/// Request model for POST /api/register-request
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'password': password,
      };

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}

/// Response model for POST /api/register-request
class RegisterRequestResponse {
  final bool success;
  final String message;
  final String? reqId;

  const RegisterRequestResponse({
    required this.success,
    required this.message,
    this.reqId,
  });

  factory RegisterRequestResponse.fromJson(Map<String, dynamic> json) {
    return RegisterRequestResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      reqId: json['reqId'] as String? ?? json['request_id'] as String? ?? json['req_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'reqId': reqId,
      };
}

/// Request model for POST /api/register-verify
class RegisterVerifyRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  final String accessToken;
  final String? referralCode;

  const RegisterVerifyRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.accessToken,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'password': password,
      'accessToken': accessToken,
    };
    if (referralCode != null && referralCode!.trim().isNotEmpty) {
      map['referral_code'] = referralCode!.trim();
      map['referralCode'] = referralCode!.trim();
    }
    return map;
  }

  factory RegisterVerifyRequest.fromJson(Map<String, dynamic> json) {
    return RegisterVerifyRequest(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      referralCode: json['referral_code'] as String? ?? json['referralCode'] as String?,
    );
  }
}

/// Response model for POST /api/register-verify
class RegisterVerifyResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;

  const RegisterVerifyResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
  });

  factory RegisterVerifyResponse.fromJson(Map<String, dynamic> json) {
    return RegisterVerifyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}
