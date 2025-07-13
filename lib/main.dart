import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/common/screen/initialization_error_screen.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:pdu_mobile_rto_app/features/admin/screen/admin_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/screens/login/login_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/service/local_notification_service.dart';
import 'package:pdu_mobile_rto_app/features/wells_selections/wells_active.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/status.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';
import 'package:pdu_mobile_rto_app/core/di/service_locator.dart';
import 'package:pdu_mobile_rto_app/firebase_options.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

ValueNotifier<InitializationStatus> initializationNotifier = ValueNotifier(InitializationStatus.pending);
String? globalInitializationError;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message via Firebase handler: ${message.messageId}");
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // DartPluginRegistrant.ensureInitialized();

  FcmService.setupBackgroundMessageHandler();

  debugPrint("Persistent background service is running to keep app alive.");
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

Future<void> initializeKeepAliveService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      autoStartOnBoot: true,
      initialNotificationContent: "Persiapan Menerima Notifikasi",
      initialNotificationTitle: "Notification Handler",

    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
  service.startService();
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform
    );

    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await initializeKeepAliveService();


    dependencyInjectionSetup();


    final FcmService fcmService = Get.find<FcmService>();

    try {
      await HiveService.initializeHive(); //

    } catch (e) {
      globalInitializationError =
      "Failed to initialize local data storage. Please restart the app. If the problem persists, contact support. Details: $e";
      initializationNotifier.value = InitializationStatus.failure;
      runApp(MainApp(initialScreen: InitializationErrorScreen(
          errorMessage: globalInitializationError!,
          onRetry: main)));
      return;
    }

    try {
      await LocalNotificationService.initialize(); //
    } catch (e, s) {
      debugPrint('LocalNotificationService initialization failed: $e');
    }

    try {
      await fcmService.initForMainApp();
    } catch (e) {
      debugPrint('FCM setup or permission request failed: $e');
    }


    final AuthService authService = Get.find<AuthService>(); //
    bool loggedIn = false;
    try {
      loggedIn = await authService.isLoggedIn(); //
    } catch (e, s) {
      debugPrint('Failed to check login status: $e');
    }

    Widget initialScreen = const LoginScreen(); // Default

    if (loggedIn) {

      try {
        await fcmService.registerDeviceWithPduServer();
      } catch (e) {
        debugPrint('Failed to register device with PDU server post-login check: $e');
      }


      String? role;

      try {
        role = await authService.getRole();
      } catch (e) {
        debugPrint('Failed to get user role: $e');
        role = "USER";
      }
      if (kDebugMode) {
        debugPrint(
            'main.dart: User is loggedIn. Retrieved role from SharedPreferences: "$role"');
      }


      if (role != null && role.toUpperCase() == 'ADMIN') {
        initialScreen = const AdminScreen();
      } else {
        initialScreen = const WellsActiveScreen();
      }
    }
    initializationNotifier.value = InitializationStatus.success;
    runApp(MainApp(initialScreen: initialScreen));
  } catch(e) {
    debugPrint('Critical application initialization failed: $e');
    globalInitializationError = "A critical error occurred during app startup. Please try again. Details: $e";
    initializationNotifier.value = InitializationStatus.failure;
    runApp(MainApp(initialScreen: InitializationErrorScreen(errorMessage: globalInitializationError!, onRetry: main))); // Pass main itself to retry
  }
}

class MainApp extends StatelessWidget {
  final Widget initialScreen;

  const MainApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarColor: CColors.primaryColor
        )
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => S.of(context).pduMobileRto,
      theme: CAppTheme.lightTheme,
      darkTheme: CAppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: ValueListenableBuilder(valueListenable: initializationNotifier,
          builder: (context, status, child) {
            if (status == InitializationStatus.failure) {
              return InitializationErrorScreen(
                  errorMessage: globalInitializationError ?? "Unknown error",
                  onRetry: main
              );
            }
            return initialScreen;
          }
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en')
      ],
    );
  }
}
