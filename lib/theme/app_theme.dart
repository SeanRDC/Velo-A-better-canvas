// Core Design System Theme Configuration
import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF78909C);
  
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primary,
        onPrimary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Colors.black,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        secondary: Color(0xFF757575),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        onPrimary: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        error: Color(0xFFCF6679),
        onError: Colors.black,
        secondary: Color(0xFF9E9E9E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}