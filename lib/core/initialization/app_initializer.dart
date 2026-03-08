import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/index.dart';
import '../../data/local/hive_service.dart';
import '../../data/local/sync_manager.dart';
import '../../services/fcm_service.dart';
import '../app_globals.dart';

/// Uygulama servislerini başlatan sınıf
class AppInitializer {
  /// Tüm servisleri sırayla başlatır
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _loadEnvironment();
    await _initializeHive();
    await _initializeSyncManager();
    await _initializeServices();
    _initializeSupabase();
    await _initializeFCM();
  }

  /// .env dosyasını yükler
  static Future<void> _loadEnvironment() async {
    await dotenv.load(fileName: '.env');
  }

  /// Hive yerel veritabanını başlatır
  static Future<void> _initializeHive() async {
    await HiveService.instance.initialize();
  }

  /// Sync Manager'ı başlatır
  static Future<void> _initializeSyncManager() async {
    await SyncManager.instance.initialize();
  }

  /// Tüm servisleri başlatır
  static Future<void> _initializeServices() async {
    await ServiceInitializer.initialize();
  }

  /// Supabase client referansını alır
  static void _initializeSupabase() {
    supabase = Supabase.instance.client;
  }

  /// FCM servisini başlatır
  static Future<void> _initializeFCM() async {
    await FCMService.instance.initialize();
  }
}
