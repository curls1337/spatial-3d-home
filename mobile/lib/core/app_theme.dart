import 'package:flutter/material.dart';

class SpatialPalette {
  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color elevated;
  final Color glass;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color cyan;
  final Color emerald;
  final Color gold;
  final Color danger;
  final Color info;

  const SpatialPalette({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.elevated,
    required this.glass,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.cyan,
    required this.emerald,
    required this.gold,
    required this.danger,
    required this.info,
  });

  static const SpatialPalette dark = SpatialPalette(
    isDark: true,
    canvas: Color(0xFF090D16),
    surface: Color(0xFF111827),
    elevated: Color(0xFF1E293B),
    glass: Color(0xCC111827),
    borderSubtle: Color(0x18FFFFFF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    cyan: Color(0xFF06B6D4),
    emerald: Color(0xFF10B981),
    gold: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF38BDF8),
  );

  static const SpatialPalette light = SpatialPalette(
    isDark: false,
    canvas: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF1F5F9),
    glass: Color(0xE0FFFFFF),
    borderSubtle: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    cyan: Color(0xFF0E7490),
    emerald: Color(0xFF047857),
    gold: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
  );

  LinearGradient get lidarGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cyan, emerald],
      );

  Color get ctaForeground => isDark ? const Color(0xFF041218) : Colors.white;
}

class AppTheme {
  static ThemeData build(bool isDark) {
    final palette = isDark ? SpatialPalette.dark : SpatialPalette.light;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: palette.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: palette.cyan,
        secondary: palette.emerald,
        surface: palette.surface,
        error: palette.danger,
      ),
      cardColor: palette.surface,
      dividerColor: palette.borderSubtle,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cyan, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
      ),
    );
  }
}
