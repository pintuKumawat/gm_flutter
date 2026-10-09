import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_service.dart';

/// This is the background message handler. It must be a top-level function
/// (outside of any class) so it can run in an isolate when the app is terminated or in the background.
/// The `@pragma('vm:entry-point')` annotation ensures it is kept when the app is compiled in release mode.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We must initialize Firebase before we can use its services in the background.
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Background Data: ${message.data}');
}

class FirebaseNotificationService {
  // Creates a single instance (singleton pattern) for FirebaseMessaging.
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Instance for handling local notifications when the app is in the foreground.
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Keeps track of the device's FCM token in memory.
  static String? _fcmToken;

  /// Initializes all Firebase Cloud Messaging (FCM) configurations.
  /// This should be called once during app startup (e.g., in main.dart).
  static Future<void> initialize() async {
    // 1. Register the background handler first.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission from the user to display notifications.
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Must initialize local notifications before listening to onMessage
    // so incoming foreground notifications can be processed and shown immediately.
    await _setupLocalNotifications();

    // 4. Get the unique FCM token for this specific device.
    _fcmToken = await _messaging.getToken();
    print('FCM TOKEN: $_fcmToken');

    // 5. Try to send the token to the backend immediately (if the user is logged in).
    await syncToken();

    // 6. Foreground FCM messages do not trigger native system heads-up notification banners automatically on Android.
    // We listen to onMessage and trigger a local notification to display visible banners while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground notification received: ${message.messageId}');
      print('Foreground Title: ${message.notification?.title}');
      print('Data: ${message.data}');

      await _showLocalNotification(message);
    });

    // 7. Listen for when a user TAPS on a notification while the app is in the BACKGROUND (but not completely closed).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.data}');
    });

    // 8. Check if the app was launched directly by TAPPING a notification from a completely TERMINATED state.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('Initial message opened: ${initialMessage.data}');
    }

    // 9. Listen for token refreshes. FCM tokens can change automatically.
    _messaging.onTokenRefresh.listen((String token) async {
      print('FCM TOKEN REFRESHED: $token');
      _fcmToken = token;
      await syncToken();
    });
  }

  /// Sets up the Android notification channel and initializes the local notification plugin.
  /// Creating an AndroidNotificationChannel with max importance is required on Android 8.0+
  /// for heads-up banner notifications when the app is in the foreground.
  static Future<void> _setupLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'grahmitra_notifications',
      'GrahMitra Notifications',
      description: 'Notifications for GrahMitra updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Create notification channel for Android 8.0+
      await androidPlugin.createNotificationChannel(channel);
      // Request notification permission for Android 13+ (API 33+)
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS & Android initialization settings
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Foreground local notification tapped with payload: ${response.payload}');
      },
    );
  }

  /// Displays a local Android & iOS notification from the incoming FCM RemoteMessage.
  /// We extract title and body from the notification payload or data payload with sensible fallbacks.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ??
        message.data['title'] ??
        message.data['heading'] ??
        'Notification';

    final String body = message.notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';

    // Unique integer notification ID to prevent consecutive notifications from overwriting each other.
    final int notificationId = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Catching and logging errors ensures any runtime notification failure displays detailed stack traces for debugging.
    try {
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'grahmitra_notifications',
            'GrahMitra Notifications',
            channelDescription: 'Notifications for GrahMitra updates',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e, stackTrace) {
      print('Failed to show foreground notification: $e');
      print(stackTrace);
    }
  }

  /// Sends the current FCM token to the backend server.
  /// It only sends the token if the user is currently authenticated (logged in).
  static Future<void> syncToken() async {
    print('--> syncToken() called. Current _fcmToken: ${_fcmToken != null ? "Present (Hidden for security)" : "NULL"}');
    
    // If we don't have a token yet, do nothing.
    if (_fcmToken == null) {
      print('--> syncToken() aborted: _fcmToken is null.');
      return;
    }
    
    // Check if the user is authenticated by looking for an active session token.
    final token = ApiService.instance.currentToken;
    if (token != null && token.isNotEmpty) {
      print('--> syncToken(): User is authenticated. Sending request to ${ApiEndpoints.updateFcmToken}...');
      try {
        // Make the API call to update the FCM token on the backend.
        await ApiService.instance.post(
          ApiEndpoints.updateFcmToken,
          data: {'fcm_token': _fcmToken},
        );
        print('--> SUCCESS: FCM token successfully synchronized with backend!');
      } catch (e) {
        print('--> ERROR: Failed to sync FCM token with backend: $e');
      }
    } else {
      print('--> syncToken() aborted: User is not authenticated (No active session token).');
    }
  }
}