import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/auth/verify_otp_model.dart';

/// Repository handling OTP & Login verification network calls.
class VerifyOtpRepo {
  final ApiService _apiService;

  VerifyOtpRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  String normalizePhoneNumber(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      return '91$digitsOnly';
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly;
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      return '91${digitsOnly.substring(1)}';
    }
    return digitsOnly;
  }

  /// Verifies OTP with MSG91 first, then passes the resulting MSG91 accessToken to backend `/api/login-with-otp`
  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
    String? reqId,
    String? referralCode,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phone);
    final authKey = EnvConfig.msg91AuthKey;
    final widgetId = EnvConfig.msg91WidgetId;
    final tokenAuth = EnvConfig.msg91TokenAuth;

    String? msg91AccessToken;

    try {
      if (widgetId.isNotEmpty) {
        final uri = Uri.parse(ApiEndpoints.msg91VerifyOtp);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          if (authKey.isNotEmpty) 'authkey': authKey,
          if (tokenAuth.isNotEmpty) 'token-auth': tokenAuth,
          if (tokenAuth.isNotEmpty) 'tokenAuth': tokenAuth,
        };
        final bodyMap = <String, dynamic>{
          'widgetId': widgetId,
          'identifier': normalizedPhone,
          'otp': otp.trim(),
          if (reqId != null && reqId.isNotEmpty) 'reqId': reqId,
          if (tokenAuth.isNotEmpty) 'tokenAuth': tokenAuth,
          if (authKey.isNotEmpty) 'authkey': authKey,
        };

        final msg91Response = await http
            .post(uri, headers: headers, body: jsonEncode(bodyMap))
            .timeout(EnvConfig.connectTimeout);

        if (msg91Response.statusCode == 200) {
          final Map<String, dynamic> jsonMap = jsonDecode(msg91Response.body);
          if (jsonMap['type'] == 'error' || jsonMap['success'] == false) {
            throw ApiException(
              message: jsonMap['message']?.toString() ?? 'Invalid or expired OTP.',
            );
          }
          msg91AccessToken = jsonMap['message']?.toString() ??
              jsonMap['access-token']?.toString() ??
              jsonMap['accessToken']?.toString();
        } else {
          String errMsg = 'Invalid or expired OTP.';
          try {
            final jsonMap = jsonDecode(msg91Response.body);
            if (jsonMap.containsKey('message')) errMsg = jsonMap['message'].toString();
          } catch (_) {}
          throw ApiException(message: errMsg);
        }
      }

      // Fallback dev mode token if MSG91 is unconfigured or in non-production dev mode
      if (msg91AccessToken == null || msg91AccessToken.isEmpty) {
        msg91AccessToken = 'mock_widget_access_token_123';
      }

      final request = VerifyOtpRequest(
        phone: phone,
        accessToken: msg91AccessToken,
        referralCode: referralCode,
      );

      final response = await _apiService.post(
        ApiEndpoints.loginWithOtp,
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return VerifyOtpResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw const ApiException(message: 'Invalid response format received from server');
      }
    } on TimeoutException {
      throw const ApiException(message: 'Network request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Verifies MSG91 access token with the backend server.
  ///
  /// Endpoint: POST `/api/auth/verify-msg91` (Auth Required: No)
  Future<VerifyMsg91Response> verifyMsg91({
    required String accessToken,
  }) async {
    try {
      final request = VerifyMsg91Request(accessToken: accessToken);
      final response = await _apiService.post(
        ApiEndpoints.verifyMsg91,
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return VerifyMsg91Response.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(message: 'Invalid response format received from server');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}