import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:pdu_mobile_rto_app/features/admin/screen/admin_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/screens/login/login_screen.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
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

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
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
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'PDU Mobile RTO',
        theme: CAppTheme.lightTheme,
        darkTheme: CAppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: initialScreen,
    );
  }

}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  dependencyInjectionSetup();

  final FcmService fcmService = GetIt.I<FcmService>();

  await fcmService.requestNotificationPermissions();
  await fcmService.setupFcmListeners();

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

  final AuthService authService = GetIt.I<AuthService>();

  final bool loggedIn = await authService.isLoggedIn();
  Widget initialScreen = const LoginScreen(); // Default

  if (loggedIn) {
    await fcmService.registerDeviceWithPduServer();

    final String? role = await authService.getRole(); // Fetch the stored role

    // --- DEBUGGING POINT ---
    if (kDebugMode) {
      print('main.dart: User is loggedIn. Retrieved role from SharedPreferences: "$role"');
    }
    // -----------------------

    if (role != null && role.toUpperCase() == 'ADMIN') {
      initialScreen = const AdminScreen();
    } else {
      // This branch is taken if role is not "ADMIN" or if role is null
      initialScreen = const WellsActiveScreen();
      if (kDebugMode && role != 'ADMIN') {
        print('main.dart: Role is "$role", not "ADMIN". Defaulting to WellsActiveScreen.');
      }
    }

  }

  runApp(MainApp(initialScreen: initialScreen,));

}

