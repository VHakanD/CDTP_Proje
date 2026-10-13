import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 temasi. Renkler elle verilir; boylece palet tamamen kontrol altindadir.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.slate,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD6E2EC),
          onPrimaryContainer: AppColors.slateDark,
          secondary: AppColors.turquoise,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.turquoiseSoft,
          onSecondaryContainer: Color(0xFF0B4F4F),
          tertiary: AppColors.warning,
          onTertiary: Colors.black,
          error: AppColors.fail,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerLowest: AppColors.background,
          surfaceContainerLow: AppColors.background,
          surfaceContainer: AppColors.surfaceAlt,
          surfaceContainerHigh: AppColors.surfaceAlt,
          surfaceContainerHighest: AppColors.surfaceAlt,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
        ),
        background: AppColors.background,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.darkSlate,
          onPrimary: Color(0xFF0E1A24),
          primaryContainer: Color(0xFF2B4257),
          onPrimaryContainer: Color(0xFFD6E2EC),
          secondary: AppColors.darkTurquoise,
          onSecondary: Color(0xFF032B2B),
          secondaryContainer: Color(0xFF15514F),
          onSecondaryContainer: Color(0xFFCDEDEB),
          tertiary: AppColors.warning,
          onTertiary: Colors.black,
          error: AppColors.fail,
          onError: Colors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: AppColors.darkBackground,
          surfaceContainer: AppColors.darkSurfaceAlt,
          surfaceContainerHigh: AppColors.darkSurfaceAlt,
          surfaceContainerHighest: AppColors.darkSurfaceAlt,
          outline: AppColors.darkOutline,
          outlineVariant: AppColors.darkOutline,
        ),
        background: AppColors.darkBackground,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
