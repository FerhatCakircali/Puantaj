import 'package:flutter/material.dart';
import 'theme_colors.dart';

/// Dark mode component theme'leri
class ThemeComponentsDark {
  static AppBarTheme get appBarTheme => const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFF1F5F9),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: Color(0xFFF1F5F9),
      letterSpacing: -1.5,
      height: 1.0,
    ),
    toolbarHeight: 80,
  );

  static CardThemeData get cardTheme => CardThemeData(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Color(0xFF0D1220),
    surfaceTintColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
  );

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: ThemeColors.darkBorderSubtle,
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
        color: ThemeColors.darkPrimary.withValues(alpha: 0.4),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: ThemeColors.darkAccent.withValues(alpha: 0.4),
        width: 2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: ThemeColors.darkAccent.withValues(alpha: 0.6),
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: TextStyle(
      color: Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    hintStyle: TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w400,
      fontSize: 15,
    ),
    prefixIconColor: ThemeColors.darkPrimary.withValues(alpha: 0.5),
    suffixIconColor: ThemeColors.darkPrimary.withValues(alpha: 0.5),
  );

  static ElevatedButtonThemeData get elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: ThemeColors.darkPrimary,
          foregroundColor: Color(0xFF0F172A),
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
      backgroundColor: ThemeColors.darkPrimary,
      foregroundColor: Color(0xFF0F172A),
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
          side: BorderSide(color: ThemeColors.darkBorder, width: 1),
          foregroundColor: ThemeColors.darkPrimary,
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
      foregroundColor: ThemeColors.darkPrimary,
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
    iconColor: ThemeColors.darkPrimary.withValues(alpha: 0.6),
    textColor: Color(0xFFF1F5F9),
    selectedColor: ThemeColors.darkPrimary,
    minVerticalPadding: 12,
  );

  static DividerThemeData get dividerTheme => DividerThemeData(
    color: ThemeColors.darkBorder,
    thickness: 0.5,
    space: 16,
  );

  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: Color(0xFF1E293B),
    contentTextStyle: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    elevation: 0,
    actionTextColor: ThemeColors.darkPrimary,
  );

  static IconThemeData get iconTheme =>
      IconThemeData(size: 24, color: ThemeColors.darkPrimary, weight: 300);

  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      FloatingActionButtonThemeData(
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        highlightElevation: 16,
        backgroundColor: ThemeColors.darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        extendedIconLabelSpacing: 12,
        extendedTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        sizeConstraints: BoxConstraints.tightFor(width: 64, height: 64),
      );

  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.darkSurface,
        selectedItemColor: ThemeColors.darkPrimary,
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
    unselectedLabelColor: Color(0xFF475569),
    indicator: BoxDecoration(
      color: ThemeColors.darkPrimary,
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
    backgroundColor: ThemeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    elevation: 0,
    insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
    titleTextStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: Color(0xFFF1F5F9),
      letterSpacing: -0.8,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 16,
      color: Color(0xFF94A3B8),
      height: 1.6,
    ),
  );

  static BottomSheetThemeData get bottomSheetTheme => BottomSheetThemeData(
    backgroundColor: ThemeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    elevation: 0,
    modalBackgroundColor: ThemeColors.darkSurface,
    modalElevation: 0,
    clipBehavior: Clip.antiAlias,
  );

  static PopupMenuThemeData get popupMenuTheme => PopupMenuThemeData(
    color: ThemeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 15, color: Color(0xFFE2E8F0)),
  );

  static DrawerThemeData get drawerTheme => DrawerThemeData(
    backgroundColor: ThemeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    width: 300,
  );
}
