import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';

class CTextTheme {
  CTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: const TextStyle().copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),

  );
  static TextTheme darkTextTheme = TextTheme(

  );

  static TextStyle parameterDashboardNumber = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: CSizes.parameterDashboardNumberTextSize,
    color: CColors.tertiaryColor
  );
}