import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../services/user_notification_service.dart';

/// Bildirim ekranı iş mantığı
mixin NotificationLogicMixin<T extends StatefulWidget> on State<T> {
  final authService = AuthService();
  final notificationService = UserNotificationService();

  bool isLoading = true;
  int? userId;
  List<Map<String, dynamic>> notifications = [];

  /// Bildirimleri yükle
  Future<void> loadNotifications() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = await authService.currentUser;
      if (user == null) return;

      userId = user['id'] as int;

      // Önce eski okunmuş bildirimleri sil (1 günden eski)
      await _deleteOldReadNotifications(userId!);

      final loadedNotifications = await notificationService.getAllNotifications(
        userId!,
      );

      if (!mounted) return;
      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Bildirim yükleme hatası: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// Eski okunmuş bildirimleri sil (1 günden eski)
  Future<void> _deleteOldReadNotifications(int userId) async {
    try {
      // Bugünün başlangıcını UTC'de hesapla
      final now = DateTime.now().toUtc();
      final todayStartUtc = DateTime.utc(now.year, now.month, now.day);
      final todayStartStr = todayStartUtc.toIso8601String();

      debugPrint('Eski bildirimler siliniyor...');
      debugPrint('Şu an (UTC): $now');
      debugPrint('Bugün başlangıç (UTC): $todayStartUtc');
      debugPrint('Silme kriteri: created_at < $todayStartStr');

      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('recipient_id', userId)
          .eq('recipient_type', 'user')
          .eq('is_read', true)
          .lt('created_at', todayStartStr);

      debugPrint('Eski okunmuş bildirimler silindi');
    } catch (e) {
      debugPrint('Eski bildirim silme hatası: $e');
    }
  }

  /// Bildirimi okundu işaretle
  Future<void> markAsRead(int notificationId) async {
    await notificationService.markAsRead(notificationId);
    loadNotifications();
  }

  /// Tümünü okundu işaretle
  Future<void> markAllAsRead() async {
    if (userId == null) return;

    await notificationService.markAllAsRead(userId!);
    loadNotifications();
  }

  /// Talep durumunu kontrol et
  Future<String?> getRequestStatus(int requestId) async {
    try {
      final response = await Supabase.instance.client
          .from('attendance_requests')
          .select('request_status')
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) return null;

      return response['request_status'] as String?;
    } catch (e) {
      debugPrint('Talep durumu kontrol hatası: $e');
      return null;
    }
  }

  /// Talebi onayla
  Future<void> handleApproveRequest(int notificationId, int requestId) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'approve_attendance_request',
        params: {'request_id_param': requestId, 'reviewed_by_param': userId},
      );

      if (result == true) {
        await markAsRead(notificationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Yevmiye talebi onaylandı'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
      } else {
        throw Exception('Talep onaylanamadı');
      }
    } catch (e) {
      debugPrint('Talep onaylama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    }
  }

  /// Talebi reddet
  Future<void> handleRejectRequest(int notificationId, int requestId) async {
    String? reason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final reasonController = TextEditingController();

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Talep Reddi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Red Sebebi (Opsiyonel)',
                    hintText: 'Neden reddedildiğini açıklayın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) => reason = value,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          reason = reasonController.text.trim();
                          Navigator.pop(context, true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Reddet'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await Supabase.instance.client.rpc(
        'reject_attendance_request',
        params: {
          'request_id_param': requestId,
          'reviewed_by_param': userId,
          'reason': (reason?.isEmpty ?? true) ? 'Sebep belirtilmedi' : reason,
        },
      );

      if (result == true) {
        await markAsRead(notificationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Yevmiye talebi reddedildi'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
      } else {
        throw Exception('Talep reddedilemedi');
      }
    } catch (e) {
      debugPrint('Talep reddetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    }
  }
}
