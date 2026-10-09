import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Clean and readable debug logger for Dio HTTP network requests
class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌────────────────── API REQUEST ──────────────────');
      debugPrint('│ Method: ${options.method}');
      debugPrint('│ URL: ${options.uri}');
      if (options.headers.isNotEmpty) {
        debugPrint('│ Headers: ${options.headers}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ Query Parameters: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('│ Body: ${options.data}');
      }
      debugPrint('└─────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌────────────────── API RESPONSE ─────────────────');
      debugPrint('│ Status Code: ${response.statusCode}');
      debugPrint('│ URL: ${response.requestOptions.uri}');
      debugPrint('│ Data: ${response.data}');
      debugPrint('└─────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌────────────────── API ERROR ────────────────────');
      debugPrint('│ Type: ${err.type}');
      debugPrint('│ Status Code: ${err.response?.statusCode}');
      debugPrint('│ URL: ${err.requestOptions.uri}');
      debugPrint('│ Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('│ Response: ${err.response?.data}');
      }
      debugPrint('└─────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}
