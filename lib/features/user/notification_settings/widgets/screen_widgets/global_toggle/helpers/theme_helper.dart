import 'package:flutter/material.dart';

/// Tema yardımcı sınıfı
class ThemeHelper {
  /// Cihazın tablet olup olmadığını kontrol eder
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Karanlık mod olup olmadığını kontrol eder
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Switch track outline rengini döndürür
  static WidgetStateProperty<Color?> getSwitchTrackOutlineColor(
    BuildContext context,
  ) {
    final isDark = isDarkMode(context);

    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent;
      }
      return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
    });
  }

  /// Switch inactive thumb rengini döndürür
  static Color getSwitchInactiveThumbColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade300 : Colors.white;
  }

  /// Switch inactive track rengini döndürür
  static Color getSwitchInactiveTrackColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade800 : Colors.grey.shade400;
  }
}
