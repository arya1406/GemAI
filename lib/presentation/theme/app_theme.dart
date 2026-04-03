import 'package:flutter/material.dart';

/// App-wide theme configuration.
class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
