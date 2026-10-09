import 'package:dio/dio.dart';
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';

/// Interceptor to automatically add Auth Bearer Token to headers and handle 401 JWT token refresh
class AuthInterceptor extends Interceptor {
  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  void clearToken() {
    _authToken = null;
  }

  String? get token => _authToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_authToken != null && _authToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // Do not attempt refresh on auth endpoints to avoid infinite loops
      if (path.contains(ApiEndpoints.refreshToken) ||
          path.contains(ApiEndpoints.login) ||
          path.contains(ApiEndpoints.loginWithOtp)) {
        return handler.next(err);
      }

      try {
        final refreshToken = await AuthStorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: EnvConfig.baseUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final isSuccess = data['success'] as bool? ?? true;

            if (isSuccess && data.containsKey('accessToken')) {
              final newAccessToken = data['accessToken'] as String;
              final newRefreshToken = (data['refreshToken'] as String?) ?? refreshToken;

              // Save rotated tokens locally
              await AuthStorageService.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Update in-memory interceptor token
              setToken(newAccessToken);

              // Retry original request with new access token
              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await Dio(
                BaseOptions(
                  baseUrl: EnvConfig.baseUrl,
                  headers: retryOptions.headers,
                ),
              ).fetch(retryOptions);

              return handler.resolve(retryResponse);
            }
          }
        }
      } catch (_) {
        // Refresh failed: clear local tokens
        await AuthStorageService.clearTokens();
        clearToken();
      }
    }

    return handler.next(err);
  }
}
