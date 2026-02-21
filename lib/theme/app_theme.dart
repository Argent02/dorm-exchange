import 'package:flutter/material.dart';

// ─── Design Tokens ─────────────────────────────────────────
// Centralized tokens for consistency across the app.

const Color _darkBlue = Color(0xFF0F172A);
const Color _glassWhite = Color(0x0DFFFFFF);
const Color _glassBorder = Color(0x18FFFFFF);
const Color _accent = Color(0xFF38BDF8);
const Color _accentMuted = Color(0xFF0EA5E9);
const Color _surfaceContainer = Color(0xFF1E293B);
const Color _error = Color(0xFFEF4444);
const Color _success = Color(0xFF22C55E);

/// Spacing scale (4pt grid)
abstract class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Border radius scale
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;
}

/// Theme-aware colors for use across the app.
extension AppColors on ColorScheme {
  Color get onSurfaceMuted => Colors.white.withValues(alpha: 0.6);
  Color get placeholderIcon => Colors.white.withValues(alpha: 0.3);
  Color get surfaceOverlay => Colors.white.withValues(alpha: 0.08);
  Color get surfaceOverlayStrong => Colors.white.withValues(alpha: 0.12);
  Color get accentMuted => _accentMuted;
  Color get errorColor => _error;
  Color get successColor => _success;
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: _accent,
    secondary: const Color(0xFFFBBF24),
    surface: _darkBlue,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    outline: _glassBorder,
    surfaceContainerHighest: _surfaceContainer,
  ),
  scaffoldBackgroundColor: _darkBlue,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    color: _glassWhite,
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _glassWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: _glassBorder),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: _accent,
    unselectedItemColor: Color(0xFF94A3B8),
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
);
