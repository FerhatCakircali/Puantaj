import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama text stilleri
class ThemeTextStyles {
  /// Light mode text theme
  static final lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
      color: const Color(0xFF0F172A),
      height: 1.1,
    ).copyWith(inherit: true),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
      color: const Color(0xFF0F172A),
      height: 1.1,
    ).copyWith(inherit: true),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: const Color(0xFF0F172A),
      height: 1.2,
    ).copyWith(inherit: true),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
      color: const Color(0xFF0F172A),
      height: 1.2,
    ).copyWith(inherit: true),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: const Color(0xFF0F172A),
      height: 1.3,
    ).copyWith(inherit: true),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: const Color(0xFF1E293B),
    ).copyWith(inherit: true),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: const Color(0xFF1E293B),
    ).copyWith(inherit: true),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: const Color(0xFF1E293B),
    ).copyWith(inherit: true),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: const Color(0xFF334155),
    ).copyWith(inherit: true),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFF334155),
    ).copyWith(inherit: true),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFF475569),
    ).copyWith(inherit: true),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFF64748B),
    ).copyWith(inherit: true),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: const Color(0xFF1E293B),
    ).copyWith(inherit: true),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: const Color(0xFF334155),
    ).copyWith(inherit: true),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: const Color(0xFF64748B),
    ).copyWith(inherit: true),
  );

  /// Dark mode text theme
  static final darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
      color: const Color(0xFFF1F5F9),
      height: 1.1,
    ).copyWith(inherit: true),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
      color: const Color(0xFFF1F5F9),
      height: 1.1,
    ).copyWith(inherit: true),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: const Color(0xFFF1F5F9),
      height: 1.2,
    ).copyWith(inherit: true),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
      color: const Color(0xFFF1F5F9),
      height: 1.2,
    ).copyWith(inherit: true),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: const Color(0xFFF1F5F9),
      height: 1.3,
    ).copyWith(inherit: true),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: const Color(0xFFE2E8F0),
    ).copyWith(inherit: true),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: const Color(0xFFE2E8F0),
    ).copyWith(inherit: true),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: const Color(0xFFE2E8F0),
    ).copyWith(inherit: true),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: const Color(0xFFCBD5E1),
    ).copyWith(inherit: true),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFFCBD5E1),
    ).copyWith(inherit: true),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFF94A3B8),
    ).copyWith(inherit: true),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: const Color(0xFF64748B),
    ).copyWith(inherit: true),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: const Color(0xFFE2E8F0),
    ).copyWith(inherit: true),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: const Color(0xFFCBD5E1),
    ).copyWith(inherit: true),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: const Color(0xFF94A3B8),
    ).copyWith(inherit: true),
  );
}
