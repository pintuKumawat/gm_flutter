import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/profile/user_profile_model.dart';
import 'package:grahmitracus/repositories/profile/profile_repo.dart';

/// Provider for managing Customer Profile state (`GET /api/me`).
class ProfileProvider extends ChangeNotifier {
  final ProfileRepo _profileRepo;

  ProfileProvider({ProfileRepo? profileRepo})
      : _profileRepo = profileRepo ?? ProfileRepo();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  bool _isSuccess = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isSuccess => _isSuccess;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Fetches customer profile from API
  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final response = await _profileRepo.getProfile();
      if (response.success && response.user != null) {
        _user = response.user;
        _isSuccess = true;
      } else {
        _errorMessage = response.message ?? 'Failed to load profile data';
        _isSuccess = false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSuccess = false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isSuccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isSaving = false;
  String? _saveError;

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;

  /// Updates the customer profile via API and refreshes local state on success.
  Future<bool> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final response = await _profileRepo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      if (response.success && response.user != null) {
        _user = response.user;
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _saveError = response.message ?? 'Failed to update profile';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _saveError = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _saveError = 'An unexpected error occurred: ${e.toString()}';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset provider state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _user = null;
    _isSuccess = false;
    notifyListeners();
  }
}
