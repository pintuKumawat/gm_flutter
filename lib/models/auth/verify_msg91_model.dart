/// Request model for MSG91 access token verification.
class VerifyMsg91Request {
  final String accessToken;

  const VerifyMsg91Request({
    required this.accessToken,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
      };

  factory VerifyMsg91Request.fromJson(Map<String, dynamic> json) {
    return VerifyMsg91Request(
      accessToken: json['accessToken'] as String? ?? '',
    );
  }
}

/// Response model for MSG91 access token verification.
class VerifyMsg91Response {
  final bool success;
  final String message;
  final VerifyMsg91Data? data;
  final bool? devMode;

  const VerifyMsg91Response({
    required this.success,
    required this.message,
    this.data,
    this.devMode,
  });

  factory VerifyMsg91Response.fromJson(Map<String, dynamic> json) {
    return VerifyMsg91Response(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? VerifyMsg91Data.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      devMode: json['devMode'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
        'devMode': devMode,
      };
}

/// Payload data containing verified phone number.
class VerifyMsg91Data {
  final String mobile;

  const VerifyMsg91Data({
    required this.mobile,
  });

  factory VerifyMsg91Data.fromJson(Map<String, dynamic> json) {
    return VerifyMsg91Data(
      mobile: json['mobile'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'mobile': mobile,
      };
}
