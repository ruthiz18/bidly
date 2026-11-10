import 'package:flutter/material.dart';

/// Single source of truth for Bidly's look. Colours are sampled from the
/// Figma swatches; change them here and every screen follows.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF2D3748); // buttons, headers
  static const secondary = Color(0xFF384666); // gradients, accents
  static const tertiary = Color(0xFF637498); // muted text, icons
  static const neutral = Color(0xFFF4F6FB); // page background

  static const surface = Colors.white; // cards
  static const field = Color(0xFFEEF1F8); // input fill
  static const accentSoft = Color(0xFFDDE3F8); // chips, info banners
  static const text = Color(0xFF1A202C);
  static const textMuted = tertiary;

  static const success = Color(0xFF2E7D5B); // winning / leading
  static const danger = Color(0xFFD32F2F); // outbid / live / urgent
}

class AppRadii {
  AppRadii._();

  static const double card = 24;
  static const double field = 16;
  static const double chip = 20;
  static const double pill = 999; // buttons are fully rounded in the design
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    const pillShape = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.neutral,

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text),
        headlineMedium: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutral,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: pillShape,
          elevation: 2,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: pillShape,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(54),
          shape: pillShape,
          side: BorderSide.none,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.tertiary),
        prefixIconColor: AppColors.tertiary,
        suffixIconColor: AppColors.tertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.text),
        secondaryLabelStyle:
            const TextStyle(fontSize: 13, color: Colors.white),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.tertiary,
        type: BottomNavigationBarType.fixed,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.tertiary.withValues(alpha: 0.4)),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.tertiary.withValues(alpha: 0.2),
        space: 1,
      ),
    );
  }
}
