import 'package:flutter/material.dart';

/// Theme service interface
///
/// Defines contract for theme management operations.
/// Implementations handle theme persistence and switching.
abstract class IThemeService {
  /// Initialize theme service
  Future<void> initialize();

  /// Get current theme mode
  ThemeMode getCurrentTheme();

  /// Set theme mode
  Future<void> setTheme(ThemeMode mode);

  /// Stream of theme mode changes
  Stream<ThemeMode> get themeStream;
}
