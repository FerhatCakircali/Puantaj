import 'package:flutter/material.dart';
import '../../../core/app_globals.dart';

/// Kullanıcı bildirimleri servisi
///
/// Kullanıcıların bildirimlerini yönetir
class UserNotificationService {
  /// Kullanıcının tüm bildirimlerini getirir
  Future<List<Map<String, dynamic>>> getAllNotifications(int userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .eq('recipient_type', 'user')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Bildirimler yüklenirken hata: $e');
      return [];
    }
  }

  /// Bir bildirimi okundu olarak işaretler
  Future<void> markAsRead(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Bildirim okundu işaretlenirken hata: $e');
    }
  }

  /// Kullanıcının tüm bildirimlerini okundu olarak işaretler
  Future<void> markAllAsRead(int userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('recipient_type', 'user')
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Tüm bildirimler okundu işaretlenirken hata: $e');
    }
  }
}
