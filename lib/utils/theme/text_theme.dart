import 'package:flutter/material.dart';

class CTextTheme {
  CTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: const TextStyle().copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
  );
  static TextTheme darkTextTheme = TextTheme(

  );
}