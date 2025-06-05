import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    elevatedButtonTheme: CElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: const AppBarTheme( // ADD THIS
      backgroundColor: CColors.primaryColor,
      elevation: 2.0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20, // Or CSizes.appBarTitleSize if you have one
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white), // For back arrows, actions
      systemOverlayStyle: SystemUiOverlayStyle( // Default style for screens with this AppBar theme
        statusBarColor: CColors.primaryColor, // Match AppBar background
        statusBarIconBrightness: Brightness.light, // Assuming primaryColor is dark
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      textTheme: CTextTheme.darkTextTheme,
      elevatedButtonTheme: CElevatedButtonTheme.darkElevatedButtonTheme,
      appBarTheme: AppBarTheme( // ADD THIS for dark theme consistency
        backgroundColor: CColors.primaryColor, // Or a darker variant if preferred
        elevation: 2.0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: CColors.primaryColor, // Or a darker variant
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
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