import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Bildirim tipi enum'ı
///
/// Sistemde kullanılan bildirim tiplerini tanımlar:
/// - attendanceReminder: Yevmiye hatırlatıcısı
/// - employeeReminder: Çalışan hatırlatıcısı
enum NotificationType {
  attendanceReminder,
  employeeReminder;

  /// Enum değerini JSON string'e çevirir
  String toJson() => name;

  /// JSON string'den enum değerine çevirir
  ///
  /// Geçersiz değer durumunda varsayılan olarak attendanceReminder döner
  static NotificationType fromJson(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.attendanceReminder,
    );
  }
}

/// Bildirim payload modeli
///
/// Bildirimlerde taşınan veri yapısını temsil eder.
/// Her bildirim tipi için gerekli kullanıcı bilgilerini ve
/// opsiyonel olarak hatırlatıcı ID'sini içerir.
class NotificationPayload {
  /// Bildirim tipi
  final NotificationType type;

  /// Kullanıcı ID'si
  final int userId;

  /// Kullanıcı adı
  final String username;

  /// Kullanıcının tam adı
  final String fullName;

  /// Çalışan hatırlatıcısı için hatırlatıcı ID'si (opsiyonel)
  final int? reminderId;

  /// NotificationPayload constructor
  ///
  /// [type] Bildirim tipi (zorunlu)
  /// [userId] Kullanıcı ID'si (zorunlu)
  /// [username] Kullanıcı adı (zorunlu)
  /// [fullName] Kullanıcının tam adı (zorunlu)
  /// [reminderId] Hatırlatıcı ID'si (opsiyonel, sadece employeeReminder için)
  NotificationPayload({
    required this.type,
    required this.userId,
    required this.username,
    required this.fullName,
    this.reminderId,
  });

  /// Payload'ı JSON string'e çevirir
  ///
  /// Bildirim zamanlama sırasında payload olarak kullanılır.
  /// reminderId sadece null değilse JSON'a eklenir.
  String toJson() {
    final map = {
      'type': type.toJson(),
      'userId': userId,
      'username': username,
      'fullName': fullName,
      if (reminderId != null) 'reminderId': reminderId,
    };
    return jsonEncode(map);
  }

  /// JSON string'den NotificationPayload oluşturur
  ///
  /// Bildirime tıklandığında payload'ı ayrıştırmak için kullanılır.
  ///
  /// [jsonString] JSON formatında payload string'i
  ///
  /// Returns:
  /// - Başarılı ayrıştırma durumunda NotificationPayload instance'ı
  /// - Hata durumunda null
  ///
  /// Hata durumları:
  /// - Geçersiz JSON formatı
  /// - Eksik zorunlu alanlar
  /// - Yanlış veri tipleri
  static NotificationPayload? fromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      // Zorunlu alanları kontrol et
      if (!map.containsKey('type') ||
          !map.containsKey('userId') ||
          !map.containsKey('username') ||
          !map.containsKey('fullName')) {
        debugPrint('Payload ayrıştırma hatası: Eksik zorunlu alanlar');
        return null;
      }

      return NotificationPayload(
        type: NotificationType.fromJson(map['type'] as String),
        userId: map['userId'] as int,
        username: map['username'] as String,
        fullName: map['fullName'] as String,
        reminderId: map['reminderId'] as int?,
      );
    } catch (e) {
      debugPrint('Payload ayrıştırma hatası: $e');
      return null;
    }
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, userId: $userId, username: $username, fullName: $fullName, reminderId: $reminderId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPayload &&
        other.type == type &&
        other.userId == userId &&
        other.username == username &&
        other.fullName == fullName &&
        other.reminderId == reminderId;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        userId.hashCode ^
        username.hashCode ^
        fullName.hashCode ^
        reminderId.hashCode;
  }
}
