import 'package:flutter/material.dart';

/// Paleta odpowiadająca oryginalnemu design systemowi (ciepły ciemny + akcent
/// „bursztynowy”). Trzymana osobno, żeby łatwo było przełączyć na inne brand
/// colors bez grzebania w ThemeData.
class AppColors {
  const AppColors._();

  // Brand
  static const Color accent = Color(0xFFE8C07D); // ciepły bursztyn
  static const Color accent2 = Color(0xFFD9A857);

  // Dark surfaces
  static const Color darkBg = Color(0xFF0F0E0D);
  static const Color darkSurface = Color(0xFF191614);
  static const Color darkSurface2 = Color(0xFF231F1B);
  static const Color darkBorder = Color(0xFF2A2622);
  static const Color darkBorder2 = Color(0xFF3A342E);

  // Light surfaces
  static const Color lightBg = Color(0xFFFAF6F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF1EBE0);
  static const Color lightBorder = Color(0xFFE4DACB);
  static const Color lightBorder2 = Color(0xFFCFC1AA);

  // Text
  static const Color darkText = Color(0xFFEFE7DA);
  static const Color darkTextMuted = Color(0xFFA69B87);
  static const Color darkTextSubtle = Color(0xFF7A7060);
  static const Color lightText = Color(0xFF1E1A15);
  static const Color lightTextMuted = Color(0xFF5A5145);
  static const Color lightTextSubtle = Color(0xFF8C806E);

  // Semantic
  static const Color red = Color(0xFFE87D7D);
  static const Color green = Color(0xFF7DC98A);
  static const Color yellow = Color(0xFFE8C07D);
}
