import 'package:flutter/material.dart';

class AppTheme {
  static const cream = Color(0xFFF8F2E7);
  static const burgundy = Color(0xFF762E40);
  static const forest = Color(0xFF234B3D);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: burgundy,
      primary: burgundy,
      secondary: forest,
      surface: cream,
    ),
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: forest,
      centerTitle: false,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cream,
      indicatorColor: burgundy.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
