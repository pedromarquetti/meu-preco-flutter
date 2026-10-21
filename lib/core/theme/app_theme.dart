import 'package:flutter/material.dart';

/// Centralized application themes following Material 3 guidelines.
class AppTheme {
  const AppTheme._();

  /// Brand seed color used to generate the color scheme.
  static const Color seedColor = Colors.blueAccent;

  /// Light theme configuration.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);
    return ThemeData(useMaterial3: true, colorScheme: colorScheme);
  }

  /// Dark theme configuration.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(useMaterial3: true, colorScheme: colorScheme);
  }
}
