import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class to manage application environment configurations.
class EnvConfig {
  EnvConfig._();

  /// Default fallback URL if .env is not present or failed to load.
  static const String _defaultBaseUrl = 'https://api.grahmitra.com';
  static const int _defaultTimeout = 15000;

  /// Initializes the environment configuration.
  static Future<void> init({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      if (kDebugMode) {
        print('✅ Environment loaded successfully from $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load $fileName file: $e. Using fallback defaults.');
      }
    }
  }

  /// Base URL of the backend server.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('BASE_URL') ?? _defaultBaseUrl;
  }

  /// Request timeout in milliseconds.
  static Duration get connectTimeout {
    final timeoutStr = dotenv.maybeGet('API_TIMEOUT');
    final timeoutMs = int.tryParse(timeoutStr ?? '') ?? _defaultTimeout;
    return Duration(milliseconds: timeoutMs);
  }

  /// Receive timeout in milliseconds.
  static Duration get receiveTimeout {
    final timeoutStr = dotenv.maybeGet('API_TIMEOUT');
    final timeoutMs = int.tryParse(timeoutStr ?? '') ?? _defaultTimeout;
    return Duration(milliseconds: timeoutMs);
  }

  /// Checks if running in production mode.
  static bool get isProduction => kReleaseMode;

  /// Checks if running in debug mode.
  static bool get isDebug => kDebugMode;

  /// MSG91 Auth Key
  static String get msg91AuthKey {
    const fromEnv = String.fromEnvironment('MSG91_AUTH_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('MSG91_AUTH_KEY') ?? '';
  }

  /// MSG91 Template ID
  static String get msg91TemplateId {
    const fromEnv = String.fromEnvironment('MSG91_TEMPLATE_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('MSG91_TEMPLATE_ID') ?? '';
  }

  /// MSG91 Widget ID
  static String get msg91WidgetId {
    const fromEnv = String.fromEnvironment('MSG91_WIDGET_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('MSG91_WIDGET_ID') ?? '';
  }

  /// MSG91 Token Auth for Widget API
  static String get msg91TokenAuth {
    const fromEnv = String.fromEnvironment('MSG91_TOKEN_AUTH');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('MSG91_TOKEN_AUTH') ?? '';
  }
}
