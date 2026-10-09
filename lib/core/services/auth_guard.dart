import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';

/// Service for checking authentication state and managing auth flow navigation
class AuthGuard {
  /// Checks if user has a valid access token in memory or local storage.
  static Future<bool> isAuthenticated() async {
    final memoryToken = ApiService.instance.currentToken;
    if (memoryToken != null && memoryToken.isNotEmpty) {
      return true;
    }
    final storedToken = await AuthStorageService.getAccessToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setAuthToken(storedToken);
      return true;
    }
    return false;
  }

  /// Pops authentication flow screens (LoginPage, OtpScreen, RegisterPage, RegisterOtpScreen)
  /// off the navigation stack to return to the caller screen.
  static void popAuthFlow(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      if (route.isFirst) return true;
      final routeName = route.settings.name;
      return routeName != 'LoginPage' &&
          routeName != 'OtpScreen' &&
          routeName != 'RegisterPage' &&
          routeName != 'RegisterOtpScreen';
    });
  }
}
