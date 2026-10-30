import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/dailyduel_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'DailyDuel',
    );
  }
}
