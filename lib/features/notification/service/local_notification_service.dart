// lib/features/notifications/services/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static int _notificationIdCounter = 0; // To ensure unique notification IDs

  static Future<void> initialize() async {
    tz.initializeTimeZones(); // Initialize timezone data

    // Android Initialization
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Or your specific small icon like '@drawable/ic_stat_notification'

    // iOS Initialization
    final DarwinInitializationSettings darwinInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true, // Request alert permission
      requestBadgePermission: true, // Request badge permission
      requestSoundPermission: true, // Request sound permission
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    // Request notification permissions on Android 13+
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); // For Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );


    bool? initialized = await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );
    print("LocalNotificationService initialized: $initialized");
  }

  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle notification when app is in foreground on older iOS versions
    print("iOS foreground notification: id=$id, title=$title, body=$body, payload=$payload");
    // You could display an in-app dialog or route the user
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    print("Notification tapped with payload: $payload");
    final FcmService fcmService = Get.find<FcmService>();
    if (payload != null && payload.isNotEmpty) {
      // Assuming _handleNotificationAcknowledge is globally accessible from main.dart or a service
      // If main.dart defines _handleNotificationAcknowledge as a top-level function, you can call it.
      // Note: Direct calls to functions in main.dart isn't always the cleanest.
      // Consider passing a callback to initialize() or using a shared service via GetIt.
      fcmService.handleNotificationAcknowledge(payload); // Call the shared handler
    }
  }

  // Separate handler for background taps (requires @pragma('vm:entry-point') for release mode)
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    print("BACKGROUND Notification tapped with payload: $payload");

    final FcmService fcmService = Get.find<FcmService>();
    if (payload != null && payload.isNotEmpty) {
      // Assuming _handleNotificationAcknowledge is globally accessible from main.dart or a service
      // If main.dart defines _handleNotificationAcknowledge as a top-level function, you can call it.
      // Note: Direct calls to functions in main.dart isn't always the cleanest.
      // Consider passing a callback to initialize() or using a shared service via GetIt.
      fcmService.handleNotificationAcknowledge(payload); // Call the shared handler
    }

    // Handle tap when app was terminated and launched by notification
  }


  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload, // Optional: for when user taps notification
  }) async {
    final int notificationId = _notificationIdCounter++; // Unique ID for each notification

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'pdu_app_channel_id', // Channel ID
      'PDU App Notifications', // Channel Name
      channelDescription: 'Notifications for PDU Mobile RTO App parameters',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // styleInformation: BigTextStyleInformation(''), // For longer text
    );

    const DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    try {
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print("Notification shown: id=$notificationId, title=$title");
    } catch (e) {
      print("Error showing notification: $e");
    }
  }
}