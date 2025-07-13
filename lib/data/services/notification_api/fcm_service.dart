// lib/features/notification/service/fcm_service.dart (example path)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart'; // PDU Server ApiClient
import 'package:pdu_mobile_rto_app/firebase_options.dart';

class FcmService {
  final ApiClient _pduNotificationApiClient;

  FcmService(this._pduNotificationApiClient);

  Future<void> initForMainApp() async {
    await requestNotificationPermissions();
    await setupListenersForMainApp();
  }

  static void setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> handleNotificationAcknowledge(String? ruleId) async {
    if (ruleId != null && ruleId.isNotEmpty) {
      try {
        debugPrint(
            'Attempting to acknowledge notification for rule ID: $ruleId (from tap)');
        bool ackSuccess =
            await _pduNotificationApiClient.acknowledgeNotification(ruleId);
        if (ackSuccess) {
          debugPrint(
              'Successfully acknowledged notification for rule ID: $ruleId with server.');
        } else {
          debugPrint(
              'Failed to acknowledge notification for rule ID: $ruleId with server.');
        }
      } catch (e) {
        debugPrint('Error calling acknowledge API for rule ID $ruleId: $e');
      }
    } else {
      debugPrint('No rule_id found in notification payload to acknowledge.');
    }
  }

  Future<void> setupListenersForMainApp() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      registerDeviceWithPduServer(newFcmToken: newToken);
    }).onError((err) {
      debugPrint("Error refreshing FCM token: $err");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Got a message whilst in the foreground!: ${message.notification?.title}');
      if (message.notification != null) {
        String? ruleIdForPayload;
        if (message.data.containsKey('rule_id')) {
          ruleIdForPayload = message.data['rule_id'] as String?;
        }
      }
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state by tapping a notification!');
        debugPrint('Terminated State Message data: ${message.data}');
        final String? ruleId = message.data['rule_id'] as String?;
        handleNotificationAcknowledge(ruleId);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('App opened from background state by tapping a notification!');
      debugPrint('Background State Message data: ${message.data}');
      final String? ruleId = message.data['rule_id'] as String?;
      handleNotificationAcknowledge(ruleId);
    });
  }

  Future<void> registerDeviceWithPduServer({String? newFcmToken}) async {
    String? fcmToken =
        newFcmToken ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
        debugPrint(
            "FcmService: Attempting to register device with PDU Server. FCM Token: $fcmToken");
      bool success =
          await _pduNotificationApiClient.registerDevice(fcmToken: fcmToken);
      if (success) {
          debugPrint("FcmService: Device registered successfully with PDU server.");
      } else {
          debugPrint("FcmService: Failed to register device with PDU server.");
      }
    } else {
      debugPrint("FcmService: FCM Token was null.");
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
      provisional:
          false, // Set to true if you want to send notifications without explicit permission on iOS (less intrusive)
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
