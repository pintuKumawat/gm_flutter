import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/core/services/firebase_notification_service.dart';
import 'package:grahmitracus/models/auth/verify_otp_model.dart';
import 'package:grahmitracus/repositories/auth/verify_otp_repo.dart';

/// Provider for managing OTP verification and customer login state.
class VerifyOtpProvider extends ChangeNotifier {
  final VerifyOtpRepo _verifyOtpRepo;

  VerifyOtpProvider({VerifyOtpRepo? verifyOtpRepo})
      : _verifyOtpRepo = verifyOtpRepo ?? VerifyOtpRepo();

  bool _isLoading = false;
  String? _errorMessage;
  VerifyOtpResponse? _otpResponse;
  VerifyMsg91Response? _msg91Response;
  bool _isSuccess = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VerifyOtpResponse? get otpResponse => _otpResponse;
  VerifyMsg91Response? get msg91Response => _msg91Response;
  bool get isSuccess => _isSuccess;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Verifies OTP and completes customer login via POST /api/login-with-otp
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    String? reqId,
    String? referralCode,
    void Function(VerifyOtpResponse response)? onSuccess,
    void Function(String errorMessage)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final res = await _verifyOtpRepo.verifyOtp(
        phone: phone,
        otp: otp,
        reqId: reqId,
        referralCode: referralCode,
      );
      _otpResponse = res;
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
          print('====== LOGIN FCM SYNC START ======');
          print('Attempting to sync FCM token after successful login...');
          await FirebaseNotificationService.syncToken();
          print('====== LOGIN FCM SYNC END ======');
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

  /// Verifies MSG91 access token with backend.
  Future<bool> verifyMsg91({
    required String accessToken,
    void Function(VerifyMsg91Response response)? onSuccess,
    void Function(String errorMessage)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final res = await _verifyOtpRepo.verifyMsg91(accessToken: accessToken);
      _msg91Response = res;
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

  /// Reset provider state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _otpResponse = null;
    _msg91Response = null;
    _isSuccess = false;
    notifyListeners();
  }
}