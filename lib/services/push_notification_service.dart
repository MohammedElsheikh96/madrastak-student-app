import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification.dart';
import 'notification_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _fcmToken;
  bool _isInitialized = false;
  Timer? _soundDebounceTimer;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token and register with backend
    await _getAndRegisterToken();

    // Set up message handlers
    _setupMessageHandlers();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'إشعارات عالية الأهمية',
      description: 'إشعارات التطبيق',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _getAndRegisterToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        final deviceType = Platform.isAndroid ? 'Android' : 'iOS';
        await _notificationService.registerDevice(_fcmToken!, deviceType);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _onTokenRefresh(String token) async {
    debugPrint('FCM Token refreshed: $token');
    _fcmToken = token;

    final deviceType = Platform.isAndroid ? 'Android' : 'iOS';
    await _notificationService.registerDevice(token, deviceType);
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(message);

    // Play notification sound with debounce
    _playNotificationSoundDebounced();

    // Refresh notification list
    await _notificationService.refreshNotifications();

    // If notification data contains full notification object, add it directly
    if (message.data.isNotEmpty) {
      try {
        final notification = AppNotification.fromJson(message.data);
        _notificationService.addNotification(notification);
      } catch (e) {
        // Data doesn't match notification format, just refresh
        debugPrint('Could not parse notification from message data: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'إشعار جديد',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'إشعارات عالية الأهمية',
            channelDescription: 'إشعارات التطبيق',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['id'],
      );
    }
  }

  void _playNotificationSoundDebounced() {
    // Cancel any pending sound
    _soundDebounceTimer?.cancel();

    // Debounce for 500ms
    _soundDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _playNotificationSound();
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      // Sound file might not exist, fallback to system sound
      debugPrint('Could not play notification sound: $e');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from background notification: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          'App opened from terminated state: ${initialMessage.messageId}');
      _navigateFromNotification(initialMessage.data);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
    if (response.payload != null) {
      _navigateFromNotification({'id': response.payload});
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    // Extract navigation data
    final redirectUrl = data['redirectUrl'];
    final courseId = data['courseId'] ??
        data['notificationDetails']?['space']?['externalCourseId']?.toString();
    final postId =
        data['postId'] ?? data['notificationDetails']?['postId']?.toString();
    final commentId = data['commentId'];

    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      // Navigate to redirect URL
      _navigateToUrl(redirectUrl);
    } else if (courseId != null && postId != null) {
      // Navigate to course landing with post
      _navigateToCoursePost(courseId, postId, commentId);
    }
  }

  void _navigateToUrl(String url) {
    // This should be implemented based on your app's navigation
    debugPrint('Navigate to URL: $url');
  }

  void _navigateToCoursePost(String courseId, String postId, String? commentId) {
    // This should be implemented based on your app's navigation
    debugPrint(
        'Navigate to course: $courseId, post: $postId, comment: $commentId');
  }

  // Re-register token when app visibility changes (e.g., comes to foreground)
  Future<void> onAppVisibilityChanged(bool isVisible) async {
    if (isVisible && _fcmToken != null) {
      final deviceType = Platform.isAndroid ? 'Android' : 'iOS';
      await _notificationService.registerDevice(_fcmToken!, deviceType);
    }
  }

  void dispose() {
    _soundDebounceTimer?.cancel();
    _audioPlayer.dispose();
  }
}
