import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour tokens (exact same as the web prototype) ───────────────────────────
class NColors {
  NColors._();

  static const Color primary  = Color(0xFF00FF29); // neon green — CTAs, active, price lock
  static const Color secondary = Color(0xFF060A0F); // near-black — app background
  static const Color surface  = Color(0xFF1C1C1C); // card background
  static const Color muted    = Color(0xFF666666); // secondary text, placeholders
  static const Color white    = Color(0xFFFFFFFF); // primary text on dark bg
  static const Color error    = Color(0xFFFF4D4D); // for validation only — not in main palette
}

// ── Typography ────────────────────────────────────────────────────────────────
// Space Grotesk   → headings / slide titles
// Inter           → body / UI text
// JetBrains Mono  → all prices and numbers
class NTextStyles {
  NTextStyles._();

  static TextStyle display(double size, {Color color = NColors.white, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, color: color, fontWeight: weight);

  static TextStyle body(double size, {Color color = NColors.white, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);

  static TextStyle mono(double size, {Color color = NColors.primary, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color, fontWeight: weight);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData nowaitoTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NColors.secondary,
    colorScheme: const ColorScheme.dark(
      primary:   NColors.primary,
      secondary: NColors.secondary,
      surface:   NColors.surface,
      error:     NColors.error,
      onPrimary: NColors.secondary,
      onSurface: NColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: NColors.secondary,
      foregroundColor: NColors.white,
      elevation: 0,
      titleTextStyle: NTextStyles.display(17),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NColors.primary,
        foregroundColor: NColors.secondary,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: NTextStyles.body(14, color: NColors.secondary, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NColors.white,
        side: const BorderSide(color: NColors.muted),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: NTextStyles.body(14, weight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NColors.surface,
      hintStyle: NTextStyles.body(14, color: NColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NColors.muted),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: NColors.muted.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NColors.primary),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: NColors.surface,
      selectedItemColor: NColors.primary,
      unselectedItemColor: NColors.muted,
    ),
    dividerColor: NColors.muted,
    useMaterial3: true,
  );
}
