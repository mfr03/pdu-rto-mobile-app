import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen_pair.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';
import 'package:pdu_mobile_rto_app/core/di/service_locator.dart';


void main() {


  dependencyInjectionSetup();


  runApp(const MainApp());

}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
      home: DrillingChartScreen()
    );
  }
}
