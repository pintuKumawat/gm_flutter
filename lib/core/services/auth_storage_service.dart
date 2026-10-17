import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized storage service for persisting and retrieving Authentication Tokens
class AuthStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userPhoneKey = 'user_phone';

  /// Extracts user ID from JWT access token payload
  static int? extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payload = jsonDecode(payloadString);
      final rawId = payload['id'] ?? payload['userId'] ?? payload['user_id'];
      if (rawId is int) return rawId;
      if (rawId is String) return int.tryParse(rawId);
    } catch (_) {}
    return null;
  }

  /// Save both Access Token and Refresh Token, plus user ID and phone if provided
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? userId,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    final resolvedUserId = userId ?? extractUserId(accessToken);
    if (resolvedUserId != null) {
      await prefs.setInt(_userIdKey, resolvedUserId);
    }
    if (userPhone != null && userPhone.isNotEmpty) {
      await prefs.setString(_userPhoneKey, userPhone);
    }
  }

  /// Get stored Access Token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get stored Refresh Token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get stored User ID (int)
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    if (id != null) return id;
    final token = prefs.getString(_accessTokenKey);
    if (token != null && token.isNotEmpty) {
      return extractUserId(token);
    }
    return null;
  }

  /// Get stored User Mobile Phone
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  /// Clear stored authentication tokens and user-specific session keys
  /// Note: User-isolated persisted data (saved addresses, order history, selected location)
  /// is preserved on disk under user-specific keys.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
  }
}

