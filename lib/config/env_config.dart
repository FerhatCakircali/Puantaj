import 'package:flutter/foundation.dart';

/// Environment Configuration
///
/// Hassas bilgileri (API keys, URLs) yönetir.
/// Production'da environment variables kullanılır.
///
/// Kullanım:
/// ```dart
/// await SupabaseService.instance.initialize(
///   url: EnvConfig.supabaseUrl,
///   anonKey: EnvConfig.supabaseAnonKey,
/// );
/// ```
class EnvConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_ID.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY_HERE',
  );

  static const String resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: 'YOUR_RESEND_API_KEY_HERE',
  );

  // Development için local config
  // Production'da environment variables kullanılmalı
  static String get supabaseUrlDev {
    if (const bool.hasEnvironment('SUPABASE_URL')) {
      return supabaseUrl;
    }
    // Development modunda secrets.dart'tan oku
    try {
      // ignore: unused_local_variable
      final secrets = _loadSecrets();
      return secrets['supabaseUrl'] as String;
    } catch (e) {
      debugPrint('⚠️ EnvConfig: secrets.dart bulunamadı. Lütfen oluşturun.');
      return supabaseUrl;
    }
  }

  static String get supabaseAnonKeyDev {
    if (const bool.hasEnvironment('SUPABASE_ANON_KEY')) {
      return supabaseAnonKey;
    }
    try {
      final secrets = _loadSecrets();
      return secrets['supabaseAnonKey'] as String;
    } catch (e) {
      debugPrint('⚠️ EnvConfig: secrets.dart bulunamadı. Lütfen oluşturun.');
      return supabaseAnonKey;
    }
  }

  static String get resendApiKeyDev {
    if (const bool.hasEnvironment('RESEND_API_KEY')) {
      return resendApiKey;
    }
    try {
      final secrets = _loadSecrets();
      return secrets['resendApiKey'] as String;
    } catch (e) {
      debugPrint('⚠️ EnvConfig: secrets.dart bulunamadı.');
      return resendApiKey;
    }
  }

  // Local secrets yükleme (development için)
  static Map<String, dynamic> _loadSecrets() {
    // Bu fonksiyon secrets.dart dosyasından değerleri okur
    // secrets.dart dosyası .gitignore'da olmalıdır
    throw UnimplementedError(
      'Local config not found. Please create lib/config/secrets.dart from secrets.dart.example',
    );
  }
}
