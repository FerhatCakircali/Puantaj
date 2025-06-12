// Supabase ile uyumlu veritabanı sürüm kontrol sınıfı
class DbCompatibility {
  static const int currentDbVersion = 1; // Şu anki veritabanı versiyonu

  // Supabase JSON dosyalarından yedek versiyon kontrolü
  static Future<int> getBackupDbVersion(Map<String, dynamic> backupData) async {
    try {
      // JSON verisinden version alanını oku
      if (backupData.containsKey('version')) {
        return backupData['version'] as int;
      }
    } catch (e) {
      print('Backup version check error: $e');
    }
    // Eğer yoksa, eski yedek (varsayılan 1)
    return 1;
  }

  static bool isCompatible(int backupVersion) {
    // Gerekirse burada daha gelişmiş kontrol ekleyebilirsiniz
    return backupVersion == currentDbVersion;
  }
}
