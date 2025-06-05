// lib/features/notification/service/fcm_service.dart (example path)
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart'; // PDU Server ApiClient
import 'package:pdu_mobile_rto_app/features/notification/service/local_notification_service.dart';

class FcmService {
  final ApiClient _pduNotificationApiClient = GetIt.I<ApiClient>();

  Future<void> setupFcmListeners() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (kDebugMode) print("FCM Token Refreshed: $newToken");
      registerDeviceWithPduServer(newFcmToken: newToken);
    }).onError((err) {
      if (kDebugMode) {
        print("Error refreshing FCM token: $err");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!: ${message.notification?.title}');
      if (message.notification != null) {
        LocalNotificationService.showNotification(
          title: message.notification?.title ?? "New Message",
          body: message.notification?.body ?? "",
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state by tapping a notification!');
        // TODO: Handle navigation based on message.data
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background state by tapping a notification!');
      // TODO: Handle navigation based on message.data
    });

  }

  Future<void> registerDeviceWithPduServer({String? newFcmToken}) async {
    String? fcmToken = newFcmToken ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      if (kDebugMode) print("FcmService: Attempting to register device with PDU Server. FCM Token: $fcmToken");
      bool success = await _pduNotificationApiClient.registerDevice(fcmToken: fcmToken);
      if (success) {
        if (kDebugMode) print("FcmService: Device registered successfully with PDU server.");
      } else {
        if (kDebugMode) print("FcmService: Failed to register device with PDU server.");
      }
    } else {
      if (kDebugMode) print("FcmService: FCM Token was null.");
    }
  }

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // Set to true if you want to send notifications without explicit permission on iOS (less intrusive)
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true
    );

  }
}