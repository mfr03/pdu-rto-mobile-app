// lib/features/notification/service/fcm_service.dart (example path)
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart'; // PDU Server ApiClient
import 'package:pdu_mobile_rto_app/features/notification/service/local_notification_service.dart';

class FcmService {
  final ApiClient _pduNotificationApiClient = GetIt.I<ApiClient>();

  Future<void> handleNotificationAcknowledge(String? ruleId) async {
    if (ruleId != null && ruleId.isNotEmpty) {
      final ApiClient apiClient = GetIt.I<ApiClient>(); // For PDU Notification Server
      try {
        print('Attempting to acknowledge notification for rule ID: $ruleId (from tap)');
        bool ackSuccess = await apiClient.acknowledgeNotification(ruleId);
        if (ackSuccess) {
          print('Successfully acknowledged notification for rule ID: $ruleId with server.');
        } else {
          print('Failed to acknowledge notification for rule ID: $ruleId with server.');
        }
      } catch (e) {
        print('Error calling acknowledge API for rule ID $ruleId: $e');
      }
    } else {
      print('No rule_id found in notification payload to acknowledge.');
    }
  }

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
        String? ruleIdForPayload;
        if (message.data.containsKey('rule_id')) {
          ruleIdForPayload = message.data['rule_id'] as String?;
        }

        // Only show local notification if you *want* to for foreground
        // If relying purely on server, this call would be removed.
        // For this fix, assuming it might still be active:
        // LocalNotificationService.showNotification(
        //   title: message.notification?.title ?? "New Message",
        //   body: message.notification?.body ?? "",
        //   payload: ruleIdForPayload, // IMPORTANT: Pass the rule_id (or other identifier)
        // );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state by tapping a notification!');
        print('Terminated State Message data: ${message.data}');
        final String? ruleId = message.data['rule_id'] as String?;
        handleNotificationAcknowledge(ruleId);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('App opened from background state by tapping a notification!');
      print('Background State Message data: ${message.data}');
      final String? ruleId = message.data['rule_id'] as String?;
      handleNotificationAcknowledge(ruleId);
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