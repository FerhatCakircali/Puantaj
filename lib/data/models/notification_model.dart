import 'dart:convert';
import '../../domain/entities/notification.dart';

/// Notification data model
///
/// Maps database records to Notification domain entity.
class NotificationModel {
  final int id;
  final int recipientId;
  final String recipientType;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? metadata;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      recipientId: json['recipient_id'] as int,
      recipientType: json['recipient_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['notification_type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      metadata: json['metadata'] as String?,
    );
  }

  Notification toEntity() {
    NotificationType typeEnum;
    switch (type.toLowerCase()) {
      case 'attendance_reminder':
        typeEnum = NotificationType.attendanceReminder;
        break;
      case 'attendance_request':
        typeEnum = NotificationType.attendanceRequest;
        break;
      case 'payment_notification':
      case 'payment_received':
        typeEnum = NotificationType.paymentNotification;
        break;
      case 'payment_updated':
        typeEnum = NotificationType.paymentUpdated;
        break;
      case 'payment_deleted':
        typeEnum = NotificationType.paymentDeleted;
        break;
      default:
        typeEnum = NotificationType.general;
    }

    Map<String, dynamic>? metadataMap;
    if (metadata != null) {
      try {
        metadataMap = jsonDecode(metadata!) as Map<String, dynamic>;
      } catch (e) {
        metadataMap = null;
      }
    }

    return Notification(
      id: id,
      recipientId: recipientId,
      recipientType: recipientType,
      title: title,
      message: message,
      type: typeEnum,
      isRead: isRead,
      createdAt: DateTime.parse(createdAt),
      metadata: metadataMap,
    );
  }

  static Map<String, dynamic> fromEntity(Notification notification) {
    String typeString;
    switch (notification.type) {
      case NotificationType.attendanceReminder:
        typeString = 'attendance_reminder';
        break;
      case NotificationType.attendanceRequest:
        typeString = 'attendance_request';
        break;
      case NotificationType.paymentNotification:
        typeString = 'payment_notification';
        break;
      case NotificationType.paymentUpdated:
        typeString = 'payment_updated';
        break;
      case NotificationType.paymentDeleted:
        typeString = 'payment_deleted';
        break;
      case NotificationType.general:
        typeString = 'general';
        break;
    }

    return {
      'id': notification.id,
      'recipient_id': notification.recipientId,
      'recipient_type': notification.recipientType,
      'title': notification.title,
      'message': notification.message,
      'notification_type': typeString,
      'is_read': notification.isRead,
      'created_at': notification.createdAt.toIso8601String(),
      'metadata': notification.metadata != null
          ? jsonEncode(notification.metadata)
          : null,
    };
  }
}
