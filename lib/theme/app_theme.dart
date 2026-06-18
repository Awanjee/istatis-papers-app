// =================================================================
// Arco Design System v1 — Flutter theme (iStatis / Arco Papers)
// Dark-only. Canvas #0D0F12, accent Sky #7DD3FC.
// Fonts: Plus Jakarta Sans (UI) + JetBrains Mono (data only).
// =================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ----------------------------- COLORS -----------------------------
class AppColors {
  AppColors._();

  // neutrals
  static const canvas = Color(0xFF0D0F12);
  static const surface1 = Color(0xFF14171B);
  static const surface2 = Color(0xFF1A1E23);
  static const surface3 = Color(0xFF20252B);
  static const borderSubtle = Color(0xFF23282F);
  static const border = Color(0xFF2C323A);
  static const borderStrong = Color(0xFF3A424C);

  // text
  static const text1 = Color(0xFFEEF1F4);
  static const text2 = Color(0xFFA8B0B9);
  static const text3 = Color(0xFF717982);

  // accent - Sky
  static const accent = Color(0xFF7DD3FC);
  static const accentHover = Color(0xFFA5E0FD);
  static const accentPress = Color(0xFF5CC2F5);
  static const accentContrast = Color(0xFF04222E);

  // semantic
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);

  // soft tints
  static final accentSoft = accent.withOpacity(0.10);
  static final accentSoft2 = accent.withOpacity(0.16);
  static final accentBorder = accent.withOpacity(0.30);
  static final successSoft = success.withOpacity(0.12);
  static final warningSoft = warning.withOpacity(0.12);
  static final dangerSoft = danger.withOpacity(0.12);

  // legacy aliases so existing code still compiles
  static const primary = accent;
  static const background = canvas;
  static const card = surface1;
  static const muted = text3;
}

/// ----------------------------- RADIUS -----------------------------
class AppRadius {
  AppRadius._();
  static const double xs = 4, sm = 6, md = 8, lg = 12, xl = 16, pill = 999;

  static const rXs = BorderRadius.all(Radius.circular(xs));
  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rPill = BorderRadius.all(Radius.circular(pill));
}

/// --------------------------- SPACING (8pt) ------------------------
class AppSpacing {
  AppSpacing._();
  static const double s1 = 4,
      s2 = 8,
      s3 = 12,
      s4 = 16,
      s5 = 20,
      s6 = 24,
      s8 = 32,
      s10 = 40,
      s12 = 48,
      s16 = 64;
}

/// --------------------------- ELEVATION ----------------------------
class AppShadows {
  AppShadows._();
  static const level1 = [
    BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1))
  ];
  static const level2 = [
    BoxShadow(color: Color(0x6B000000), blurRadius: 20, offset: Offset(0, 6))
  ];
  static const level3 = [
    BoxShadow(color: Color(0x85000000), blurRadius: 40, offset: Offset(0, 16))
  ];
}

/// ----------------------------- TYPE -------------------------------
class AppText {
  AppText._();

  static TextStyle _sans(double size, FontWeight w,
          {double height = 1.3, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: spacing,
          color: AppColors.text1);

  static TextStyle get display =>
      _sans(40, FontWeight.w700, height: 1.08, spacing: -1.0);
  static TextStyle get h1 =>
      _sans(30, FontWeight.w700, height: 1.15, spacing: -0.6);
  static TextStyle get h2 =>
      _sans(24, FontWeight.w600, height: 1.20, spacing: -0.36);
  static TextStyle get h3 =>
      _sans(19, FontWeight.w600, height: 1.30, spacing: -0.19);
  static TextStyle get bodyLg => _sans(16, FontWeight.w400, height: 1.60);
  static TextStyle get body => _sans(15, FontWeight.w400, height: 1.55);
  static TextStyle get small =>
      _sans(13, FontWeight.w400, height: 1.45)
          .copyWith(color: AppColors.text2);
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
      fontSize: 12, letterSpacing: 0.24, color: AppColors.text2);
}

/// ----------------------------- THEME ------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData get light => dark; // dark-only system

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.accentContrast,
      secondary: AppColors.accent,
      onSecondary: AppColors.accentContrast,
      surface: AppColors.surface1,
      onSurface: AppColors.text1,
      error: AppColors.danger,
      onError: Color(0xFF2A0606),
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: scheme,
      textTheme: TextTheme(
        displaySmall: AppText.display,
        headlineMedium: AppText.h1,
        headlineSmall: AppText.h2,
        titleLarge: AppText.h3,
        bodyLarge: AppText.bodyLg,
        bodyMedium: AppText.body,
        bodySmall: AppText.small,
        labelSmall: AppText.mono,
      ),
      dividerColor: AppColors.borderSubtle,

      // app bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.text1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppText.h3,
        iconTheme: const IconThemeData(color: AppColors.text2),
      ),

      // buttons - 44px tall, md radius
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentContrast,
          minimumSize: const Size(double.infinity, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.rMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text1,
          minimumSize: const Size(double.infinity, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          side: const BorderSide(color: AppColors.borderStrong),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.rMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),

      // inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4, vertical: 14),
        hintStyle: AppText.body.copyWith(color: AppColors.text3),
        labelStyle: AppText.small.copyWith(color: AppColors.text2),
        border: const OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: const OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: AppColors.danger)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: AppColors.danger, width: 1.5)),
      ),

      // cards
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      // bottom nav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface1,
        indicatorColor: AppColors.accentSoft2,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.text3),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.text3)),
      ),

      // chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        labelStyle: AppText.small,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      ),
    );
  }
}
