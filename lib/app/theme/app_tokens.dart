import 'package:flutter/material.dart';

/// Merkezi renk sistemi — dark & light.
abstract final class AppColors {
  // Brand
  static const brand = Color(0xFF0D9488);
  static const brandBright = Color(0xFF2DD4BF);
  static const brandDeep = Color(0xFF0F766E);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Dark surfaces
  static const darkInk = Color(0xFF0A0E12);
  static const darkSurface = Color(0xFF12181F);
  static const darkSurfaceHigh = Color(0xFF1A222C);
  static const darkBorder = Color(0xFF2A3542);
  static const darkText = Color(0xFFF1F5F9);
  static const darkMuted = Color(0xFF94A3B8);

  // Light surfaces
  static const lightInk = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 36.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const minTouchTarget = 48.0;
  static const iconButton = 44.0;
  static const brandMark = 28.0;
}
