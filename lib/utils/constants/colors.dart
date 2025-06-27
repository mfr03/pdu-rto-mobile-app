import 'package:flutter/material.dart';

class CColors {
  CColors._();
  
  static const Color primaryColor = Color(0xFFE75C33);
  static const Color secondaryColor = Color(0xFFF9DAD1);
  static const Color tertiaryColor = Color(0xFF1E1E1E);
  static const Color white = Colors.white;
  static const Color red = Colors.red;
  static const Color redDarkTheme = Color(0xFFCF6679);
  static const Color black = Colors.black;

  static const ColorScheme lightThemeColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: white,
      secondary: secondaryColor,
      onSecondary: tertiaryColor,
      error: red,
      onError: white,
      surface: white,
      onSurface: tertiaryColor
  );
  
  static const ColorScheme darkThemeColorScheme = ColorScheme(
      brightness:Brightness.dark,
      primary: primaryColor,
      onPrimary: tertiaryColor,
      secondary: primaryColor,
      onSecondary: white,
      error: redDarkTheme,
      onError: black,
      surface: tertiaryColor,
      onSurface: secondaryColor
  );
}






