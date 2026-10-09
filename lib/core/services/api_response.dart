/// Standard API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode = 200,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    String? message,
    int? statusCode,
    T? data,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message ?? 'An error occurred',
      statusCode: statusCode,
      data: data,
    );
  }
}
