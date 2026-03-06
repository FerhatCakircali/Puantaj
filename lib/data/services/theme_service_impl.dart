import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/services/i_theme_service.dart';
import '../../domain/services/i_storage_service.dart';
import '../../core/error_handler.dart';

/// Theme service implementation
/// Implements IThemeService using StorageService for persistence.
/// Provides reactive theme updates via stream.
class ThemeServiceImpl implements IThemeService {
  final IStorageService _storageService;
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  static const String _themeKey = 'app_theme_mode';
  ThemeMode _currentTheme = ThemeMode.system;

  ThemeServiceImpl(this._storageService);

  @override
  Future<void> initialize() async {
    try {
      ErrorHandler.logInfo('ThemeService', 'Başlatılıyor...');

      // Load saved theme from storage
      final savedTheme = await _storageService.getString(_themeKey);

      if (savedTheme != null) {
        _currentTheme = _parseThemeMode(savedTheme);
        ErrorHandler.logInfo(
          'ThemeService',
          'Kaydedilmiş tema yüklendi: $_currentTheme',
        );
      } else {
        _currentTheme = ThemeMode.system;
        ErrorHandler.logInfo(
          'ThemeService',
          'Varsayılan tema kullanılıyor: $_currentTheme',
        );
      }

      ErrorHandler.logSuccess('ThemeService', 'Başarıyla başlatıldı');
    } catch (e, stackTrace) {
      ErrorHandler.logError('ThemeService.initialize', e, stackTrace);
      // Hata durumunda varsayılan tema kullan
      _currentTheme = ThemeMode.system;
    }
  }

  @override
  ThemeMode getCurrentTheme() {
    return _currentTheme;
  }

  @override
  Future<void> setTheme(ThemeMode mode) async {
    try {
      ErrorHandler.logInfo(
        'ThemeService.setTheme',
        'Tema değiştiriliyor: $mode',
      );

      // Save to storage
      await _storageService.setString(_themeKey, _themeToString(mode));

      // Update current theme
      _currentTheme = mode;

      // Notify listeners
      _themeController.add(mode);

      ErrorHandler.logSuccess(
        'ThemeService.setTheme',
        'Tema değiştirildi: $mode',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError('ThemeService.setTheme', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  /// Dispose resources
  void dispose() {
    _themeController.close();
  }

  /// Parse ThemeMode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to string
  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
