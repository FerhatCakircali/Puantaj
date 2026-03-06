import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';

/// Supabase client service - Singleton pattern
/// Manages Supabase client initialization and provides access to the client.
/// Follows Singleton pattern to ensure single instance across the app.
/// Usage:
/// ```dart
/// final client = SupabaseService.instance.client;
/// final response = await client.from('workers').select();
/// ```
class SupabaseService {
  SupabaseService._();

  static final SupabaseService _instance = SupabaseService._();

  /// Singleton instance
  static SupabaseService get instance => _instance;

  SupabaseClient? _client;

  /// Supabase client instance
    /// Throws [DatabaseException] if not initialized
  SupabaseClient get client {
    if (_client == null) {
      throw DatabaseException('Supabase client not initialized');
    }
    return _client!;
  }

  /// Whether the service is initialized
  bool get isInitialized => _client != null;

  /// Initializes Supabase client
    /// Should be called once at app startup before any database operations.
  /// Pass url and anonKey from your environment configuration.
    /// Throws [DatabaseException] if parameters are invalid.
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      if (url.isEmpty) {
        throw DatabaseException('Supabase URL boş olamaz');
      }

      if (anonKey.isEmpty) {
        throw DatabaseException('Supabase anon key boş olamaz');
      }

      // Initialize Supabase with auto refresh token
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          autoRefreshToken: true, // Otomatik token yenileme - oturum açık kalır
        ),
        realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
      );

      _client = Supabase.instance.client;

      if (kDebugMode) {
        debugPrint('Supabase initialized successfully');
      }
    } catch (e) {
      if (e is DatabaseException) {
        rethrow;
      }
      throw DatabaseException('Supabase başlatılamadı: $e');
    }
  }

  /// Checks if the client is connected to Supabase
    /// Returns true if client is initialized and can communicate with server
  Future<bool> checkConnection() async {
    try {
      if (!isInitialized) return false;

      // Try a simple query to check connection
      await client.from('workers').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      return false;
    }
  }

  /// Disposes the service (for testing purposes)
  void dispose() {
    _client = null;
  }
}
