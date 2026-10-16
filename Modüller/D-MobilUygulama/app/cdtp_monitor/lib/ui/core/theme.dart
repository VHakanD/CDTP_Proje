import 'package:flutter/material.dart';

/// Wireframe'in gri tonları + yalnız durum için iki renk. Kamera ekranıyla
/// uyumlu olsun diye koyu tema kullanılır.
abstract final class AppColors {
  static const bg = Color(0xFF151617);
  static const surface = Color(0xFF1F2022);
  static const ink = Color(0xFFE6E6E6);
  static const mid = Color(0xFFA3A3A3);
  static const line = Color(0xFF6F6F6F);
  static const hair = Color(0xFF3A3B3D);
  static const scene = Color(0xFF0E0F10);
  static const pass = Color(0xFF6FCF97);
  static const fail = Color(0xFFEB5757);
  static const warn = Color(0xFFF2C94C);
}

ThemeData buildTheme() {
  const mono = 'monospace';
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.ink,
      onPrimary: AppColors.bg,
      secondary: AppColors.mid,
      outline: AppColors.line,
      outlineVariant: AppColors.hair,
      error: AppColors.fail,
    ),
    fontFamily: mono,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: TextStyle(fontFamily: mono, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.bg,
        disabledBackgroundColor: AppColors.hair,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.hair, space: 1),
  );
}
