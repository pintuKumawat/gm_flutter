import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/core/services/firebase_notification_service.dart';
import 'package:grahmitracus/models/auth/register_model.dart';
import 'package:grahmitracus/repositories/auth/register_repo.dart';

/// Provider for managing customer registration states.
class RegisterProvider extends ChangeNotifier {
  final RegisterRepo _registerRepo;

  RegisterProvider({RegisterRepo? registerRepo})
      : _registerRepo = registerRepo ?? RegisterRepo();

  bool _isLoading = false;
  String? _errorMessage;
  RegisterRequestResponse? _requestResponse;
  RegisterVerifyResponse? _verifyResponse;
  bool _isSuccess = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RegisterRequestResponse? get requestResponse => _requestResponse;
  RegisterVerifyResponse? get verifyResponse => _verifyResponse;
  bool get isSuccess => _isSuccess;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Requests customer registration and initiates OTP.
  Future<bool> registerRequest({
    required RegisterRequest request,
    void Function(RegisterRequestResponse response)? onSuccess,
    void Function(String errorMessage)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final res = await _registerRepo.registerRequest(request: request);
      _requestResponse = res;
      _isSuccess = res.success;

      if (res.success) {
        _isLoading = false;
        notifyListeners();
        onSuccess?.call(res);
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        onError?.call(res.message);
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _isSuccess = false;
      notifyListeners();
      onError?.call(e.message);
      return false;
    } catch (e) {
      final msg = 'An unexpected error occurred: ${e.toString()}';
      _errorMessage = msg;
      _isLoading = false;
      _isSuccess = false;
      notifyListeners();
      onError?.call(msg);
      return false;
    }
  }

  /// Verifies registration OTP and completes customer account creation.
  Future<bool> registerVerify({
    required RegisterVerifyRequest request,
    String? reqId,
    void Function(RegisterVerifyResponse response)? onSuccess,
    void Function(String errorMessage)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final res = await _registerRepo.registerVerify(request: request, reqId: reqId);
      _verifyResponse = res;
      _isSuccess = res.success;

      if (res.success) {
        // Persist tokens and configure ApiService
        if (res.accessToken != null && res.accessToken!.isNotEmpty) {
          await AuthStorageService.saveTokens(
            accessToken: res.accessToken!,
            refreshToken: res.refreshToken ?? '',
          );
          ApiService.instance.setAuthToken(res.accessToken!);

          // Sync FCM token with backend now that user is authenticated
          await FirebaseNotificationService.syncToken();
        }

        _isLoading = false;
        notifyListeners();
        onSuccess?.call(res);
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        onError?.call(res.message);
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _isSuccess = false;
      notifyListeners();
      onError?.call(e.message);
      return false;
    } catch (e) {
      final msg = 'An unexpected error occurred: ${e.toString()}';
      _errorMessage = msg;
      _isLoading = false;
      _isSuccess = false;
      notifyListeners();
      onError?.call(msg);
      return false;
    }
  }

  /// Reset provider state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _requestResponse = null;
    _verifyResponse = null;
    _isSuccess = false;
    notifyListeners();
  }
}
