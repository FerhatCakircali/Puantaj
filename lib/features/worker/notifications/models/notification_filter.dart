import 'package:flutter/material.dart';

/// Bildirim filtreleme seçenekleri
enum NotificationReadFilter {
  all,
  unread,
  read;

  String get label {
    switch (this) {
      case NotificationReadFilter.all:
        return 'Tümü';
      case NotificationReadFilter.unread:
        return 'Okunmamış';
      case NotificationReadFilter.read:
        return 'Okunmuş';
    }
  }
}

/// Bildirim tipi filtreleme seçenekleri
enum NotificationTypeFilter {
  all,
  attendance,
  payment;

  String get label {
    switch (this) {
      case NotificationTypeFilter.all:
        return 'Tümü';
      case NotificationTypeFilter.attendance:
        return 'Yevmiye';
      case NotificationTypeFilter.payment:
        return 'Ödemeler';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationTypeFilter.all:
        return Icons.filter_list;
      case NotificationTypeFilter.attendance:
        return Icons.calendar_today;
      case NotificationTypeFilter.payment:
        return Icons.payments;
    }
  }
}
