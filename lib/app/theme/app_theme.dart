import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
    surface: AppColors.lightSurface,
  );

  return _base(scheme, Brightness.light).copyWith(
    scaffoldBackgroundColor: AppColors.lightInk,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.lightText,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.brand.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.brandDeep : AppColors.lightMuted,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
    ),
    inputDecorationTheme: _input(
      fill: AppColors.lightSurfaceHigh,
      border: AppColors.lightBorder,
      hint: AppColors.lightMuted,
    ),
    snackBarTheme: _snack(AppColors.lightSurfaceHigh, AppColors.lightText),
    dividerColor: AppColors.lightBorder,
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandBright,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
  );

  return _base(scheme, Brightness.dark).copyWith(
    scaffoldBackgroundColor: AppColors.darkInk,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.darkText,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.brandBright.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.brandBright : AppColors.darkMuted,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    inputDecorationTheme: _input(
      fill: AppColors.darkSurfaceHigh,
      border: AppColors.darkBorder,
      hint: AppColors.darkMuted,
    ),
    snackBarTheme: _snack(AppColors.darkSurfaceHigh, AppColors.darkText),
    dividerColor: AppColors.darkBorder,
  );
}

ThemeData _base(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? AppColors.brandBright : AppColors.brand,
        foregroundColor: isDark ? AppColors.darkInk : Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        foregroundColor: isDark ? AppColors.brandBright : AppColors.brandDeep,
      ),
    ),
  );
}

InputDecorationTheme _input({
  required Color fill,
  required Color border,
  required Color hint,
}) {
  return InputDecorationTheme(
    filled: true,
    fillColor: fill,
    hintStyle: TextStyle(color: hint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );
}

SnackBarThemeData _snack(Color bg, Color fg) {
  return SnackBarThemeData(
    backgroundColor: bg,
    contentTextStyle: TextStyle(color: fg),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );
}
