import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/utils/theme/elevated_button_theme.dart';
import 'package:pdu_mobile_rto_app/utils/theme/text_theme.dart';

class CAppTheme {

  CAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    textTheme: CTextTheme.lightTextTheme,
    elevatedButtonTheme: CElevatedButtonTheme.lightElevatedButtonTheme
  );

  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      textTheme: CTextTheme.darkTextTheme,
      elevatedButtonTheme: CElevatedButtonTheme.darkElevatedButtonTheme
  );


}