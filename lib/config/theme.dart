import 'package:flutter/material.dart';

/// Theme Colors - Matching Website (themes.css)
/// Ensures visual consistency between web and mobile applications

// Background Colors
const Color bgPrimary = Color(0xFF1E293B);        // rgba(30, 41, 59, 0.95) - Main background
const Color bgCard = Color(0xFF334155);           // rgba(51, 65, 85, 0.90) - Card background
const Color bgCardHover = Color(0xFF475569);      // Hover/secondary card background

// Accent Colors
const Color accentBlue = Color(0xFF3B82F6);       // #3b82f6 - Primary accent
const Color accentHover = Color(0xFF2563EB);      // Hover state for accent

// Text Colors
const Color textPrimary = Color(0xFFE0F2FE);      // #e0f2fe - Primary text
const Color textSecondary = Color(0xFFCBD5E1);    // #cbd5e1 - Secondary text
const Color textMuted = Color(0xFF94A3B8);        // #94a3b8 - Muted text

// Status Colors
const Color successColor = Color(0xFF10B981);     // #10b981 - Success green
const Color warningColor = Color(0xFFF59E0B);     // #f59e0b - Warning amber
const Color dangerColor = Color(0xFFEF4444);      // #ef4444 - Danger red
const Color infoColor = Color(0xFF3B82F6);        // #3b82f6 - Info blue

// Medical SOS specific (bright red for emergency)
const Color medicalRed = Color(0xFFFF4444);

// Border Colors
final Color borderColor = accentBlue.withOpacity(0.3);
final Color borderSubtle = accentBlue.withOpacity(0.2);

/// App Theme Configuration
ThemeData getAppTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bgPrimary,
    cardColor: bgCard,
    primaryColor: accentBlue,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentBlue,
      surface: bgCard,
      background: bgPrimary,
      error: dangerColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
      ),
    ),
    iconTheme: const IconThemeData(color: accentBlue),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: accentBlue),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary),
      displayMedium: TextStyle(color: textPrimary),
      displaySmall: TextStyle(color: textPrimary),
      headlineLarge: TextStyle(color: textPrimary),
      headlineMedium: TextStyle(color: textPrimary),
      headlineSmall: TextStyle(color: textPrimary),
      titleLarge: TextStyle(color: textPrimary),
      titleMedium: TextStyle(color: textPrimary),
      titleSmall: TextStyle(color: textPrimary),
      bodyLarge: TextStyle(color: textSecondary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textMuted),
      labelLarge: TextStyle(color: textPrimary),
      labelMedium: TextStyle(color: textSecondary),
      labelSmall: TextStyle(color: textMuted),
    ),
  );
}
