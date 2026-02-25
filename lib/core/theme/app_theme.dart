import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_text_styles.dart';
import 'theme_components_light.dart';
import 'theme_components_dark.dart';

/// 2026 Enterprise Luxury Theme - High-End SaaS Aesthetic
/// Design Philosophy: Magazine-quality layout with refined elegance
class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: ThemeColors.lightPrimary,
      secondary: ThemeColors.lightSecondary,
      surface: ThemeColors.lightSurface,
      error: ThemeColors.lightAccent,
      tertiary: ThemeColors.lightAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
      outline: ThemeColors.lightBorder,
      outlineVariant: ThemeColors.lightBorderSubtle,
    ),
    scaffoldBackgroundColor: ThemeColors.lightBackground,
    appBarTheme: ThemeComponentsLight.appBarTheme,
    cardTheme: ThemeComponentsLight.cardTheme,
    inputDecorationTheme: ThemeComponentsLight.inputDecorationTheme,
    elevatedButtonTheme: ThemeComponentsLight.elevatedButtonTheme,
    filledButtonTheme: ThemeComponentsLight.filledButtonTheme,
    outlinedButtonTheme: ThemeComponentsLight.outlinedButtonTheme,
    textButtonTheme: ThemeComponentsLight.textButtonTheme,
    listTileTheme: ThemeComponentsLight.listTileTheme,
    dividerTheme: ThemeComponentsLight.dividerTheme,
    snackBarTheme: ThemeComponentsLight.snackBarTheme,
    textTheme: ThemeTextStyles.lightTextTheme,
    iconTheme: ThemeComponentsLight.iconTheme,
    bottomNavigationBarTheme: ThemeComponentsLight.bottomNavigationBarTheme,
    tabBarTheme: ThemeComponentsLight.tabBarTheme,
    dialogTheme: ThemeComponentsLight.dialogTheme,
    popupMenuTheme: ThemeComponentsLight.popupMenuTheme,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: ThemeColors.darkPrimary,
      secondary: ThemeColors.darkSecondary,
      surface: ThemeColors.darkSurface,
      error: ThemeColors.darkAccent,
      tertiary: ThemeColors.darkAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF1F5F9),
      outline: ThemeColors.darkBorder,
      outlineVariant: ThemeColors.darkBorderSubtle,
    ),
    scaffoldBackgroundColor: ThemeColors.darkBackground,
    appBarTheme: ThemeComponentsDark.appBarTheme,
    cardTheme: ThemeComponentsDark.cardTheme,
    inputDecorationTheme: ThemeComponentsDark.inputDecorationTheme,
    elevatedButtonTheme: ThemeComponentsDark.elevatedButtonTheme,
    filledButtonTheme: ThemeComponentsDark.filledButtonTheme,
    outlinedButtonTheme: ThemeComponentsDark.outlinedButtonTheme,
    textButtonTheme: ThemeComponentsDark.textButtonTheme,
    listTileTheme: ThemeComponentsDark.listTileTheme,
    dividerTheme: ThemeComponentsDark.dividerTheme,
    snackBarTheme: ThemeComponentsDark.snackBarTheme,
    textTheme: ThemeTextStyles.darkTextTheme,
    iconTheme: ThemeComponentsDark.iconTheme,
    floatingActionButtonTheme: ThemeComponentsDark.floatingActionButtonTheme,
    bottomNavigationBarTheme: ThemeComponentsDark.bottomNavigationBarTheme,
    tabBarTheme: ThemeComponentsDark.tabBarTheme,
    dialogTheme: ThemeComponentsDark.dialogTheme,
    bottomSheetTheme: ThemeComponentsDark.bottomSheetTheme,
    popupMenuTheme: ThemeComponentsDark.popupMenuTheme,
    drawerTheme: ThemeComponentsDark.drawerTheme,
  );
}
