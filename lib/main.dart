import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/service/local_notification_service.dart';
import 'package:pdu_mobile_rto_app/features/wells_selections/wells_active.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';
import 'package:pdu_mobile_rto_app/core/di/service_locator.dart';
import 'package:pdu_mobile_rto_app/firebase_options.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

Future<void> _requestNotificationPermissions() async {
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

Future<String> getPersistentClientId() async {
  final prefs = await SharedPreferences.getInstance();
  String? clientId = prefs.getString('persistent_client_id');
  if (clientId == null) {
    clientId = Uuid().v4();
    await prefs.setString('persistent_client_id', clientId);
    if (kDebugMode) {
      print('Generated new persistent client ID: $clientId');
    }
  }
  return clientId;
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => _MainAppState();

}

class _MainAppState extends State<MainApp> {
  final ApiClient _apiClient = ApiClient();


  @override
  void initState() {
    super.initState();
    _initializeAndRegisterDevice();
  }

  Future<void> _initializeAndRegisterDevice() async {
    await _setupFCMListeners();
    _registerDeviceWithServer();
  }


  Future<void> _registerDeviceWithServer({String? newFcmToken}) async {
    String userId = await getPersistentClientId();

    String? fcmToken = newFcmToken ?? await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      if (kDebugMode) {
        print("Attempting to register device with FCM Token: $fcmToken for User ID: $userId");
      }
      bool success = await _apiClient.registerDevice(
        userId: userId,
        fcmToken: fcmToken,
        // platform can be derived in ApiClient or passed explicitly
      );
      if (success) {
        if (kDebugMode) {
          print("Device registered successfully with server.");
        }
      } else {
        if (kDebugMode) {
          print("Failed to register device with server.");
          // TODO: Implement retry logic or error handling
        }
      }
    } else {
      if (kDebugMode) {
        print("FCM Token was null, cannot register device.");
      }
    }
  }


  Future<void> _setupFCMListeners() async {
    // Get initial token (also handled by _registerDeviceWithServer if newFcmToken is null)
    // String? initialToken = await FirebaseMessaging.instance.getToken();
    // if (kDebugMode) {
    //   print("Initial FCM Token: $initialToken");
    // }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("FCM Token Refreshed: $newToken");
      }
      _registerDeviceWithServer(newFcmToken: newToken); // Send refreshed token
    }).onError((err) {
      if (kDebugMode) {
        print("Error refreshing FCM token: $err");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ... (your existing foreground message handling) ...
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

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarColor: CColors.primaryColor
        )
    );


    return MaterialApp(
        title: 'Test App',
        theme: CAppTheme.lightTheme,
        darkTheme: CAppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: WellsActiveScreen()
    );
  }


}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _requestNotificationPermissions();

  await HiveService.initializeHive();
  final parameterBox = await HiveService.openParameterBox();
  if(parameterBox.isEmpty) {
    await HiveService.initializeDefaultData(parameterBox);
  }

  final depthParameterBox = await HiveService.openDepthParameterBox();
  if(depthParameterBox.isEmpty) {
    await HiveService.initializeDefaultDepthData(depthParameterBox);
  }

  await LocalNotificationService.initialize();

  dependencyInjectionSetup();


  runApp(const MainApp());

}

