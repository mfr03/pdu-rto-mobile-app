import 'package:flutter/material.dart';

class Circle extends StatelessWidget {

  final Color circleColor;
  final double circleSize;

  const Circle(this.circleColor, this.circleSize, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor
        ),
      ),
    );
  }
  
}