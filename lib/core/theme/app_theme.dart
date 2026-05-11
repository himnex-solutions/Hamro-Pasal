import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryColor = Color(0xFF1E6FD9);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4D93E8);
  static const Color accentColor = Color(0xFF00C9A7);
  static const Color accentDark = Color(0xFF00A88A);

  // Semantic Colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Neutral Light
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextHint = Color(0xFF94A3B8);

  // Neutral Dark
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: lightSurface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: lightTextPrimary),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: lightTextPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: lightTextPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: lightTextPrimary),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: lightTextSecondary),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
        hintStyle: GoogleFonts.poppins(color: lightTextHint, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: lightTextSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF6FF),
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryLight,
        secondary: accentColor,
        error: errorColor,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: darkTextPrimary),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: darkTextPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: darkTextPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: darkTextPrimary),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: darkTextSecondary),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryLight, width: 2)),
        hintStyle: GoogleFonts.poppins(color: darkTextHint, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
