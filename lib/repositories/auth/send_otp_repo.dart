import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:msg91/msg91.dart';
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/auth/send_otp_model.dart';

/// Repository handling MSG91 Send OTP integration.
class SendOtpRepo {
  /// Normalizes Indian phone numbers to MSG91 required format: 91XXXXXXXXXX
  /// Strips non-digits, leading zeroes, and avoids duplicate country codes like +91 or 9191.
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

  /// Sends OTP using MSG91 package v1.0.5 or MSG91 Widget API endpoint.
  Future<SendOtpResponse> sendOtp({
    required String phone,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phone);

    // Validate normalized mobile number (must be 12 digits: 91 + 10 digits)
    if (normalizedPhone.length != 12 || !normalizedPhone.startsWith('91')) {
      throw const ApiException(
        message: 'Invalid phone number. Please enter a valid 10-digit mobile number.',
      );
    }

    final authKey = EnvConfig.msg91AuthKey;
    final templateId = EnvConfig.msg91TemplateId;
    final widgetId = EnvConfig.msg91WidgetId;
    final tokenAuth = EnvConfig.msg91TokenAuth;

    // Validate MSG91 configuration presence
    if (authKey.isEmpty && widgetId.isEmpty && tokenAuth.isEmpty) {
      throw const ApiException(
        message: 'MSG91 configuration is missing. Please set MSG91 environment keys in .env file.',
      );
    }

    try {
      // MSG91 Widget API (POST https://api.msg91.com/api/v5/widget/sendOtp)
      // Widget API requires 'widgetId' and 'identifier' in body, with tokenAuth/authkey for authentication.
      if (widgetId.isNotEmpty) {
        final uri = Uri.parse(ApiEndpoints.msg91SendOtp);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          if (authKey.isNotEmpty) 'authkey': authKey,
          if (tokenAuth.isNotEmpty) 'token-auth': tokenAuth,
          if (tokenAuth.isNotEmpty) 'tokenAuth': tokenAuth,
        };
        final bodyMap = <String, dynamic>{
          'widgetId': widgetId,
          'identifier': normalizedPhone,
          if (tokenAuth.isNotEmpty) 'tokenAuth': tokenAuth,
          if (authKey.isNotEmpty) 'authkey': authKey,
        };
        final body = jsonEncode(bodyMap);

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(EnvConfig.connectTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonMap = jsonDecode(response.body);
          final type = jsonMap['type'] ?? jsonMap['status'];
          final message = jsonMap['message'] ?? 'OTP sent successfully';
          final reqId = jsonMap['reqId']?.toString() ??
              jsonMap['request_id']?.toString() ??
              jsonMap['req_id']?.toString() ??
              (message.toString().length > 10 ? message.toString() : null);

          if (type == 'error' || jsonMap['success'] == false) {
            throw ApiException(message: message.toString());
          }
          return SendOtpResponse(
            success: true,
            message: message.toString(),
            reqId: reqId,
          );
        } else {
          String errorMessage = 'MSG91 Widget API error (HTTP ${response.statusCode})';
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(response.body);
            if (jsonMap.containsKey('message')) {
              errorMessage = jsonMap['message'].toString();
            }
          } catch (_) {}
          throw ApiException(message: errorMessage);
        }
      } else {
        // Use msg91 package v1.0.5 API (Msg91 / Otp / OtpOptions)
        if (templateId.isEmpty) {
          throw const ApiException(
            message: 'MSG91 Template ID is required when using standard OTP API.',
          );
        }

        final msg91 = Msg91().initialize(authKey: authKey);
        final otp = msg91.getOtp();

        await otp.send(
          mobileNumber: normalizedPhone,
          options: OtpOptions(templateId: templateId),
        ).timeout(EnvConfig.connectTimeout);

        return const SendOtpResponse(
          success: true,
          message: 'OTP sent successfully',
        );
      }
    } on TimeoutException {
      throw const ApiException(
        message: 'Network request timed out. Please check your connection and try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to send OTP via MSG91: ${e.toString()}',
      );
    }
  }
}