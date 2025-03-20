import 'package:flutter/material.dart';

class ColoredText extends StatelessWidget {


  final String text;
  final double textSize;
  final Color textColor;
  final bool isBold;

  const ColoredText({super.key, required this.text, required this.textColor, required this.textSize, required this.isBold});


  @override
  Widget build(BuildContext context) {
      return Material(
        type: MaterialType.transparency,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: textSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal
          ),
        ),
      );
  }

}