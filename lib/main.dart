import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen_pair.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      theme: CAppTheme.lightTheme,
      darkTheme: CAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: DrillingChartScreenPair()
    );
  }
}
