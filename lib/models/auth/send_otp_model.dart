/// Request model for initiating customer login / sending OTP.
class SendOtpRequest {
  final String phone;

  const SendOtpRequest({
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
      };

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) {
    return SendOtpRequest(
      phone: json['phone'] as String? ?? '',
    );
  }
}

/// Response model for initiating customer login / sending OTP.
class SendOtpResponse {
  final bool success;
  final String message;
  final String? reqId;

  const SendOtpResponse({
    required this.success,
    required this.message,
    this.reqId,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
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