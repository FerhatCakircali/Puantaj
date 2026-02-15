import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF4F8EF7); // Modern mavi ana renk
  static const _surfaceGradient = LinearGradient(
    colors: [Color(0xFFF7F9FB), Color(0xFFE3EAF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF23272B), Color(0xFF181C20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      primary: _seedColor,
      secondary: Color(0xFF00BFAE),
      background: Color(0xFFF4F7FB),
      surface: Colors.white,
      error: Color(0xFFD32F2F),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F7FB),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _seedColor,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _seedColor,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: Colors.white.withOpacity(0.98),
      shadowColor: _seedColor.withOpacity(0.10),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _seedColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      labelStyle: TextStyle(
        color: _seedColor.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontWeight: FontWeight.w400,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        elevation: 5,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
        shadowColor: _seedColor.withOpacity(0.18),
        animationDuration: const Duration(milliseconds: 250),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _seedColor,
        side: BorderSide(color: _seedColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _seedColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      tileColor: Colors.white.withOpacity(0.98),
      selectedTileColor: _seedColor.withOpacity(0.10),
      iconColor: _seedColor,
      textColor: Colors.black87,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[300],
      thickness: 1.3,
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _seedColor,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 17),
      elevation: 6,
      actionTextColor: Color(0xFF00BFAE),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    iconTheme: const IconThemeData(size: 28, color: _seedColor),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white.withOpacity(0.98),
      selectedItemColor: _seedColor,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      showUnselectedLabels: true,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _seedColor,
      unselectedLabelColor: Colors.grey[500],
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _seedColor, width: 3),
        insets: EdgeInsets.symmetric(horizontal: 28),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _seedColor,
      ),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      textStyle: const TextStyle(fontSize: 15, color: Colors.black87),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      primary: _seedColor,
      secondary: Color(0xFF00BFAE),
      background: Color(0xFF181C20),
      surface: Color(0xFF23272B),
      error: Color(0xFFD32F2F),
    ),
    scaffoldBackgroundColor: const Color(0xFF181C20),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF23272B),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: const Color(0xFF23272B),
      shadowColor: Colors.black.withOpacity(0.16),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF23272B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontWeight: FontWeight.w400,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        elevation: 5,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
        shadowColor: _seedColor.withOpacity(0.18),
        animationDuration: const Duration(milliseconds: 250),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      tileColor: const Color(0xFF23272B),
      selectedTileColor: _seedColor.withOpacity(0.13),
      iconColor: _seedColor,
      textColor: Colors.white,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[800],
      thickness: 1.3,
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _seedColor,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 17),
      elevation: 6,
      actionTextColor: Color(0xFF00BFAE),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    iconTheme: const IconThemeData(size: 28, color: Colors.white),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF23272B),
      selectedItemColor: _seedColor,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      showUnselectedLabels: true,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _seedColor,
      unselectedLabelColor: Colors.grey[500],
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _seedColor, width: 3),
        insets: EdgeInsets.symmetric(horizontal: 28),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Color(0xFF23272B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Color(0xFF23272B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      textStyle: const TextStyle(fontSize: 15, color: Colors.white),
    ),
  );
}
