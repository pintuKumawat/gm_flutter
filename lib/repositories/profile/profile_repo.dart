import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/profile/user_profile_model.dart';

/// Repository for Customer Profile API (`GET /api/me`)
class ProfileRepo {
  final ApiService _apiService;

  ProfileRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches the logged-in customer profile from `GET /api/me`.
  Future<UserProfileResponse> getProfile() async {
    try {
      final response = await _apiService.get(ApiEndpoints.userProfile);

      if (response.data is Map<String, dynamic>) {
        return UserProfileResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(message: 'Invalid response format received from server');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
  /// Updates the logged-in customer profile via `PUT /api/update-profile`.
  Future<UserProfileResponse> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateProfile,
        data: {
          'first_name': firstName,
          'last_name': lastName ?? '',
          'email': email,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return UserProfileResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(message: 'Invalid response format received from server');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
