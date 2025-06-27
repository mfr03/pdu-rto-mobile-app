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


ValueNotifier<InitializationStatus> initializationNotifier = ValueNotifier(InitializationStatus.pending);
String? globalInitializationError;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    dependencyInjectionSetup();

    final FcmService fcmService = Get.find<FcmService>();

    try {
      await HiveService.initializeHive(); //
      final parameterBox = await HiveService.openParameterBox(); //
      if (parameterBox.isEmpty) {
        await HiveService.initializeDefaultData(parameterBox); //
      }
      final depthParameterBox = await HiveService.openDepthParameterBox(); //
      if (depthParameterBox.isEmpty) {
        await HiveService.initializeDefaultDepthData(depthParameterBox); //
      }
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
      print('LocalNotificationService initialization failed: $e');
    }

    try {
      await fcmService.requestNotificationPermissions(); //
      await fcmService.setupFcmListeners(); //
    } catch (e) {
      print('FCM setup or permission request failed: $e');
    }


    final AuthService authService = Get.find<AuthService>(); //
    bool loggedIn = false;
    try {
      loggedIn = await authService.isLoggedIn(); //
    } catch (e, s) {
      print('Failed to check login status: $e');
      // Treat as not logged in, or show specific error. For now, proceeds to login screen.
    }

    Widget initialScreen = const LoginScreen(); // Default

    if (loggedIn) {

      try {
        await fcmService.registerDeviceWithPduServer();
      } catch (e) {
        print('Failed to register device with PDU server post-login check: $e');
      }


      String? role;

      try {
        role = await authService.getRole();
      } catch (e) {
        print('Failed to get user role: $e');
        role = "USER";
      }
      if (kDebugMode) {
        print(
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
    print('Critical application initialization failed: $e');
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
        title: S.of(context).pduMobileRto,
        theme: CAppTheme.lightTheme,
        darkTheme: CAppTheme.darkTheme,
        themeMode: ThemeMode.system,
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
