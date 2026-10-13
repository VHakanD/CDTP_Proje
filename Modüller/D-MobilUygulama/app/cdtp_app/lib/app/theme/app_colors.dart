import 'package:flutter/material.dart';

/// Uygulama renk paleti.
///
/// Ana renk grimsi mavi (slate), ikincil renk turkuaz. Basarisiz durumlar icin
/// turkuazin tamamlayicisi olan mercan tonu kullanilir (renk teorisi: tamamlayici
/// renk dikkat ceker, bu yuzden sadece hata/kaldi durumunda gorunur).
class AppColors {
  AppColors._();

  // Acik tema
  static const slate = Color(0xFF3E5C76);
  static const slateDark = Color(0xFF2B4257);
  static const turquoise = Color(0xFF1A9E9E);
  static const turquoiseSoft = Color(0xFFCDEDEB);
  static const background = Color(0xFFF3F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFE8EEF2);
  static const outline = Color(0xFFD5DEE5);
  static const textPrimary = Color(0xFF1C2A36);
  static const textSecondary = Color(0xFF5B6B7A);

  // Koyu tema
  static const darkBackground = Color(0xFF10171D);
  static const darkSurface = Color(0xFF18222B);
  static const darkSurfaceAlt = Color(0xFF22303B);
  static const darkOutline = Color(0xFF2F3F4C);
  static const darkSlate = Color(0xFF8DB0CF);
  static const darkTurquoise = Color(0xFF4FC9C4);
  static const darkTextPrimary = Color(0xFFE3EAF0);
  static const darkTextSecondary = Color(0xFF9AABBA);

  // Durum renkleri (iki temada ortak)
  static const pass = Color(0xFF1F8F7A);
  static const fail = Color(0xFFC8553D);
  static const warning = Color(0xFFD9A441);
  static const missing = Color(0xFF8796A5);
}
