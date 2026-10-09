import 'dart:io';
import 'package:dio/dio.dart';
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/interceptors/auth_interceptor.dart';
import 'package:grahmitracus/core/services/interceptors/logging_interceptor.dart';

/// Centralized Dio-based API Service for HTTP network communications.
class ApiService {
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  static ApiService get instance => _instance;

  ApiService._internal() {
    _authInterceptor = AuthInterceptor();
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        sendTimeout: EnvConfig.connectTimeout,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _authInterceptor,
      ApiLoggingInterceptor(),
    ]);
  }

  /// Exposed Dio client if direct access is required
  Dio get client => _dio;

  /// Update the Base URL at runtime if necessary
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;   
  }

  /// Set Auth Bearer Token for subsequent authenticated requests
  void setAuthToken(String token) {
    _authInterceptor.setToken(token);
  }

  /// Clear the stored Auth Bearer Token
  void clearAuthToken() {
    _authInterceptor.clearToken();
  }

  /// Current Auth Token
  String? get currentToken => _authInterceptor.token;

  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Upload a single file with optional form data
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileKey,
    String? fileName,
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {...?additionalData};
      formDataMap[fileKey] = await MultipartFile.fromFile(
        filePath,
        filename: fileName ?? filePath.split('/').last,
      );

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post<T>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Download a file and save to disk
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
