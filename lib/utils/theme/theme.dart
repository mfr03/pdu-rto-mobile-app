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
    colorScheme: CColors.lightThemeColorScheme,
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
    colorScheme: CColors.darkThemeColorScheme,
    fontFamily: 'Montserrat',
    brightness: Brightness.dark,
    primaryColor: CColors.primaryColor, // Your main brand color
    scaffoldBackgroundColor: const Color(0xFF121212), // A common, less harsh dark background
    canvasColor: const Color(0xFF121212), // For things like Drawer backgrounds

    // Widget Themes
    textTheme: CTextTheme.darkTextTheme,
    elevatedButtonTheme: CElevatedButtonTheme.darkElevatedButtonTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E), // A dark surface color for the app bar
      elevation: 0, // A flatter look is common in dark themes
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1E1E1E),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // Card Theme for dark mode
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E), // Use the dark surface color
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
      ),
    ),

    // Input Field Theme for dark mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C), // A slightly lighter dark for input fields
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        borderSide: const BorderSide(color: CColors.primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2.0),
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

  static BoxDecoration elevatedContainerDark = BoxDecoration(
    color: const Color(0xFF1E1E1E), // Use the dark surface color
    borderRadius: BorderRadius.circular(12),
    // In dark mode, borders often work better than shadows
    border: Border.all(color: Colors.white24, width: 0.5),
  );


  static EdgeInsetsGeometry parameterDashboardPadding = EdgeInsets.only(
    top: 12,
    left: 16,
    right: 16,
    bottom: 4
  );
}