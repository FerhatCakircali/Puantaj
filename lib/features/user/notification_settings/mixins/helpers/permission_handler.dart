import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Bildirim izinlerini yöneten helper sınıfı
class NotificationPermissionHandler {
  /// Bildirim iznini kontrol eder
  static Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    // iOS veya diğer platformlar için izin varsayılan olarak true
    return true;
  }

  /// Bildirim izni ister
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // iOS veya diğer platformlar için izin varsayılan olarak true
    return true;
  }
}
