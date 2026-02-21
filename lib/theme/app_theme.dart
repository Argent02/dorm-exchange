import 'package:flutter/material.dart';

const Color _darkBlue = Color(0xFF0F172A);
const Color _glassWhite = Color(0x0DFFFFFF);
const Color _glassBorder = Color(0x18FFFFFF);
const Color _accent = Color(0xFF38BDF8);

/// Theme-aware colors for use across the app.
extension AppColors on ColorScheme {
  Color get onSurfaceMuted => Colors.white.withValues(alpha: 0.6);
  Color get placeholderIcon => Colors.white.withValues(alpha: 0.3);
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
    outline: const Color(0x18FFFFFF),
    surfaceContainerHighest: const Color(0xFF1E293B),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: _glassWhite,
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _glassWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
);
