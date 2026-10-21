import 'package:flutter/material.dart';

/// Centralized application themes following Material 3 guidelines.
///
/// All brand color, typography, shape, spacing, elevation, input, button, and
/// focus decisions live here so feature widgets never introduce raw brand
/// colors of their own. The palette is derived from the Meu Preço app icon
/// (`assets/main_icon.svg`), whose background is a green-to-blue gradient.
class AppTheme {
  const AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand palette (source of truth: assets/main_icon.svg)
  // ---------------------------------------------------------------------------

  /// Primary brand green — the icon gradient's start stop (`#00C853`).
  static const Color brandGreen = Color(0xFF00C853);

  /// Secondary brand blue — the icon gradient's end stop (`#0091EA`).
  static const Color brandBlue = Color(0xFF0091EA);

  /// Light accent used by the icon's cart treatment (`#E0F7FA`).
  static const Color brandMist = Color(0xFFE0F7FA);

  /// The brand's signature gradient, matching the app icon background.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreen, brandBlue],
  );

  /// Seed color used to generate the Material 3 color schemes. A seed between
  /// the two gradient stops keeps generated roles balanced across the brand.
  static const Color seedColor = brandBlue;

  /// Fixed tonal anchors seeded from the icon palette so surfaces and accents
  /// stay recognisably on-brand in both brightnesses.
  static const Color _lightSurface = Color(0xFFF6FBF9);
  static const Color _lightOnSurface = Color(0xFF101C18);
  static const Color _darkSurface = Color(0xFF0E1512);
  static const Color _darkOnSurface = Color(0xFFE1EAE5);

  // ---------------------------------------------------------------------------
  // Shared design tokens
  // ---------------------------------------------------------------------------

  /// Base spacing unit (4 dp grid).
  static const double spacingUnit = 4;

  /// Small corner radius for dense controls and chips.
  static const double radiusSmall = 8;

  /// Medium corner radius for inputs, cards, and buttons.
  static const double radiusMedium = 12;

  /// Large corner radius for sheets and prominent surfaces.
  static const double radiusLarge = 20;

  /// Minimum interactive target size (accessibility).
  static const double minTouchTarget = 48;

  /// Overlay color for content drawn on top of the live camera preview (scanner
  /// instructions and framing box), where the background is unpredictable.
  static const Color cameraOverlay = Colors.white;

  // ---------------------------------------------------------------------------
  // Public theme builders
  // ---------------------------------------------------------------------------

  /// Light theme configuration.
  static ThemeData light() => _build(Brightness.light);

  /// Dark theme configuration.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          secondary: brandGreen,
          brightness: brightness,
        ).copyWith(
          surface: isDark ? _darkSurface : _lightSurface,
          onSurface: isDark ? _darkOnSurface : _lightOnSurface,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(0, minTouchTarget)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}
