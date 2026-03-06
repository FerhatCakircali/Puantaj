/// Bildirim kayıt modeli
/// Veritabanındaki notifications tablosuna karşılık gelir.
/// Sistem tarafından gönderilen bildirimlerin kaydını tutar.
/// NOT: Bu model NotificationPayload'dan farklıdır:
/// - NotificationPayload: Flutter local notifications için payload
/// - NotificationRecord: Veritabanı kaydı için model
class NotificationRecord {
  /// Bildirim ID'si (veritabanı primary key)
  final int? id;

  /// Gönderen ID'si (opsiyonel, system bildirimleri için null olabilir)
  final int? senderId;

  /// Gönderen tipi: 'user', 'worker', 'system'
  final String senderType;

  /// Alıcı ID'si
  final int recipientId;

  /// Alıcı tipi: 'user', 'worker'
  final String recipientType;

  /// Bildirim tipi: 'attendance_request', 'attendance_reminder',
  /// 'attendance_approved', 'attendance_rejected', 'general'
  final String notificationType;

  /// Bildirim başlığı
  final String title;

  /// Bildirim mesajı
  final String message;

  /// Okundu mu?
  final bool isRead;

  /// İlişkili kayıt ID'si (opsiyonel)
  /// Örnek: attendance_request_id, reminder_id
  final int? relatedId;

  /// Oluşturulma zamanı
  final DateTime createdAt;

  /// NotificationRecord constructor
  NotificationRecord({
    this.id,
    this.senderId,
    required this.senderType,
    required this.recipientId,
    required this.recipientType,
    required this.notificationType,
    required this.title,
    required this.message,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  /// Veritabanı map'inden NotificationRecord oluşturur
  factory NotificationRecord.fromMap(Map<String, dynamic> map) {
    return NotificationRecord(
      id: map['id'] as int?,
      senderId: map['sender_id'] as int?,
      senderType: map['sender_type'] as String,
      recipientId: map['recipient_id'] as int,
      recipientType: map['recipient_type'] as String,
      notificationType: map['notification_type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      isRead: map['is_read'] as bool? ?? false,
      relatedId: map['related_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// NotificationRecord'u veritabanı map'ine çevirir
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      'sender_type': senderType,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'is_read': isRead,
      if (relatedId != null) 'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// NotificationRecord kopyasını oluşturur (immutable pattern)
  NotificationRecord copyWith({
    int? id,
    int? senderId,
    String? senderType,
    int? recipientId,
    String? recipientType,
    String? notificationType,
    String? title,
    String? message,
    bool? isRead,
    int? relatedId,
    DateTime? createdAt,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationRecord(id: $id, type: $notificationType, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationRecord &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderType == senderType &&
        other.recipientId == recipientId &&
        other.recipientType == recipientType &&
        other.notificationType == notificationType &&
        other.title == title &&
        other.message == message &&
        other.isRead == isRead &&
        other.relatedId == relatedId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        senderType.hashCode ^
        recipientId.hashCode ^
        recipientType.hashCode ^
        notificationType.hashCode ^
        title.hashCode ^
        message.hashCode ^
        isRead.hashCode ^
        relatedId.hashCode ^
        createdAt.hashCode;
  }
}
