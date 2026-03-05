import 'package:flutter/material.dart';
import 'theme_colors.dart';

/// Light mode component theme'leri
class ThemeComponentsLight {
  static AppBarTheme get appBarTheme => const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF0F172A),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: Color(0xFF0F172A),
      letterSpacing: -1.5,
      height: 1.0,
    ),
    toolbarHeight: 80,
  );

  static CardThemeData get cardTheme => CardThemeData(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    color: ThemeColors.lightSurface,
    surfaceTintColor: Colors.transparent,
    shadowColor: ThemeColors.lightShadow,
    clipBehavior: Clip.antiAlias,
  );

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: ThemeColors.lightBorderSubtle,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: ThemeColors.lightPrimary.withValues(alpha: 0.3),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: ThemeColors.lightAccent.withValues(alpha: 0.3),
        width: 2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: ThemeColors.lightAccent.withValues(alpha: 0.5),
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    hintStyle: TextStyle(
      color: Color(0xFF94A3B8),
      fontWeight: FontWeight.w400,
      fontSize: 15,
    ),
    prefixIconColor: ThemeColors.lightPrimary.withValues(alpha: 0.4),
    suffixIconColor: ThemeColors.lightPrimary.withValues(alpha: 0.4),
  );

  static ElevatedButtonThemeData get elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: ThemeColors.lightPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      );

  static FilledButtonThemeData get filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: ThemeColors.lightPrimary,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
  );

  static OutlinedButtonThemeData get outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: ThemeColors.lightBorder, width: 1),
          foregroundColor: ThemeColors.lightPrimary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      );

  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      foregroundColor: ThemeColors.lightPrimary,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
  );

  static ListTileThemeData get listTileTheme => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    tileColor: Colors.transparent,
    selectedTileColor: Colors.transparent,
    iconColor: ThemeColors.lightPrimary.withValues(alpha: 0.6),
    textColor: Color(0xFF1E293B),
    selectedColor: ThemeColors.lightPrimary,
    minVerticalPadding: 12,
  );

  static DividerThemeData get dividerTheme => DividerThemeData(
    color: ThemeColors.lightBorder,
    thickness: 0.5,
    space: 16,
  );

  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: Color(0xFF1E293B),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    elevation: 0,
    actionTextColor: ThemeColors.lightPrimary,
  );

  static IconThemeData get iconTheme =>
      const IconThemeData(size: 24, color: ThemeColors.lightPrimary);

  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      FloatingActionButtonThemeData(
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        highlightElevation: 16,
        backgroundColor: ThemeColors.lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        extendedIconLabelSpacing: 12,
        extendedTextStyle: TextStyle(
          inherit: false,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
        sizeConstraints: BoxConstraints.tightFor(width: 64, height: 64),
      );

  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.lightSurface,
        selectedItemColor: ThemeColors.lightPrimary,
        unselectedItemColor: Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        showUnselectedLabels: true,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      );

  static TabBarThemeData get tabBarTheme => TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Color(0xFF94A3B8),
    indicator: BoxDecoration(
      color: ThemeColors.lightPrimary,
      borderRadius: BorderRadius.circular(20),
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    labelPadding: EdgeInsets.symmetric(horizontal: 12),
  );

  static DialogThemeData get dialogTheme => DialogThemeData(
    backgroundColor: ThemeColors.lightSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: ThemeColors.lightBorder, width: 0.5),
    ),
    elevation: 0,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF0F172A),
      letterSpacing: -0.3,
    ),
    contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
  );

  static PopupMenuThemeData get popupMenuTheme => PopupMenuThemeData(
    color: ThemeColors.lightSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: ThemeColors.lightBorder, width: 0.5),
    ),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
  );
}
