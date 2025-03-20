import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
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

  static BoxDecoration standardBoxDecorationPrimaryColor = BoxDecoration(
    color: CColors.primaryColor,
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(CSizes.standardBorderRadiusSize),
      topLeft: Radius.circular(CSizes.standardBorderRadiusSize)
    )
  );

  static BoxDecoration standardBoxDecorationSecondaryColor = BoxDecoration(
      color: CColors.secondaryColor,
      borderRadius: BorderRadius.only(
          topRight: Radius.circular(CSizes.standardBorderRadiusSize),
          topLeft: Radius.circular(CSizes.standardBorderRadiusSize)
      )
  );
  static BoxDecoration elevatedContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 5)
      )
    ]
  );

  static EdgeInsetsGeometry parameterDashboardPadding = EdgeInsets.only(
    top: 12,
    left: 16,
    right: 16,
    bottom: 4
  );
}