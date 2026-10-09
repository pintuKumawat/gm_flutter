import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/auth/register_model.dart';

/// Repository handling Customer Registration network calls.
class RegisterRepo {
  final ApiService _apiService;

  RegisterRepo({ApiService? apiService})
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

  /// Requests customer registration and sends verification OTP.
  ///
  /// Endpoint: POST `/api/register-request`
  Future<RegisterRequestResponse> registerRequest({
    required RegisterRequest request,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.registerRequest,
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return RegisterRequestResponse.fromJson(
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

  /// Verifies registration OTP with MSG91 and creates the customer account.
  ///
  /// Endpoint: POST `/api/register-verify`
  Future<RegisterVerifyResponse> registerVerify({
    required RegisterVerifyRequest request,
    String? otp,
    String? reqId,
  }) async {
    try {
      final phone = request.phone;
      final rawOtp = otp ?? request.accessToken;

      String? msg91AccessToken;
      if (rawOtp != null && rawOtp.isNotEmpty) {
        final normalizedPhone = normalizePhoneNumber(phone);
        final authKey = EnvConfig.msg91AuthKey;
        final widgetId = EnvConfig.msg91WidgetId;
        final tokenAuth = EnvConfig.msg91TokenAuth;

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
            'otp': rawOtp.trim(),
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
      }

      if (msg91AccessToken == null || msg91AccessToken.isEmpty) {
        throw const ApiException(message: 'MSG91 OTP verification failed. Verification token is missing.');
      }

      final finalPayload = request.toJson();
      finalPayload['accessToken'] = msg91AccessToken;

      final response = await _apiService.post(
        ApiEndpoints.registerVerify,
        data: finalPayload,
      );

      if (response.data is Map<String, dynamic>) {
        return RegisterVerifyResponse.fromJson(
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
}
