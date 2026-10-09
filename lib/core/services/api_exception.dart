import 'package:dio/dio.dart';

/// Custom API Exception for standardized error handling across the app.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request to server was cancelled.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout with server.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timeout in connection with server.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Send timeout in connection with server.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Bad certificate encountered.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection or server unreachable.',
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return ApiException._handleBadResponse(dioError.response);
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: dioError.message ?? 'An unexpected error occurred.',
          statusCode: dioError.response?.statusCode,
        );
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final responseData = response?.data;
    String message = 'Received invalid status code: $statusCode';

    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('message')) {
        message = responseData['message'].toString();
      } else if (responseData.containsKey('error')) {
        message = responseData['error'].toString();
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message.isNotEmpty ? message : 'Bad Request.',
          statusCode: statusCode,
          data: responseData,
        );
      case 401:
        return ApiException(
          message: message.isNotEmpty ? message : 'Unauthorized access. Please login again.',
          statusCode: statusCode,
          data: responseData,
        );
      case 403:
        return ApiException(
          message: message.isNotEmpty ? message : 'Access forbidden.',
          statusCode: statusCode,
          data: responseData,
        );
      case 404:
        return ApiException(
          message: message.isNotEmpty ? message : 'Requested resource not found.',
          statusCode: statusCode,
          data: responseData,
        );
      case 422:
        return ApiException(
          message: message.isNotEmpty ? message : 'Validation error.',
          statusCode: statusCode,
          data: responseData,
        );
      case 500:
        return ApiException(
          message: message.isNotEmpty ? message : 'Internal server error. Please try again later.',
          statusCode: statusCode,
          data: responseData,
        );
      case 502:
      case 503:
        return ApiException(
          message: 'Server is currently unavailable. Please try again later.',
          statusCode: statusCode,
          data: responseData,
        );
      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: responseData,
        );
    }
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
