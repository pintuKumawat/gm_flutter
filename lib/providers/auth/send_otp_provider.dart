import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/auth/send_otp_model.dart';
import 'package:grahmitracus/repositories/auth/send_otp_repo.dart';

/// Provider for managing initiate login / send OTP state.
class SendOtpProvider extends ChangeNotifier {
  final SendOtpRepo _sendOtpRepo;

  SendOtpProvider({SendOtpRepo? sendOtpRepo})
      : _sendOtpRepo = sendOtpRepo ?? SendOtpRepo();

  bool _isLoading = false;
  String? _errorMessage;
  SendOtpResponse? _response;
  bool _isSuccess = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SendOtpResponse? get response => _response;
  bool get isSuccess => _isSuccess;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Initiates customer login and requests OTP sending.
  Future<bool> sendOtp({
    required String phone,
    void Function(SendOtpResponse response)? onSuccess,
    void Function(String errorMessage)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final res = await _sendOtpRepo.sendOtp(phone: phone);
      _response = res;
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

  /// Reset state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _response = null;
    _isSuccess = false;
    notifyListeners();
  }
}