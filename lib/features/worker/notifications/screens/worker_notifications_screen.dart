import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/services/local_storage_service.dart';
import '../../services/worker_notification_service.dart';

/// Çalışan bildirimleri ekranı - Enhanced
///
/// Özellikler:
/// 1. İstatistik kartları (Okunmamış, Bugün, Toplam)
/// 2. Filtreleme (Tümü, Okunmamış, Okunmuş)
/// 3. Tip filtreleme (Tümü, Talepler, Hatırlatıcılar, Ödemeler)
/// 4. Modern UI/UX
class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  final _localStorage = LocalStorageService.instance;
  final _notificationService = WorkerNotificationService();

  bool _isLoading = true;
  int? _workerId;
  List<Map<String, dynamic>> _notifications = [];
  String _selectedFilter = 'all'; // all, unread, read
  String _selectedType = 'all'; // all, attendance, payment

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  List<Map<String, dynamic>> get filteredNotifications {
    var filtered = _notifications;

    // Okunma durumuna göre filtrele
    if (_selectedFilter == 'unread') {
      filtered = filtered.where((n) => n['is_read'] == false).toList();
    } else if (_selectedFilter == 'read') {
      filtered = filtered.where((n) => n['is_read'] == true).toList();
    }

    // Bildirim tipine göre filtrele
    if (_selectedType == 'attendance') {
      filtered = filtered
          .where(
            (n) => (n['notification_type'] as String).startsWith('attendance'),
          )
          .toList();
    } else if (_selectedType == 'payment') {
      filtered = filtered
          .where(
            (n) => (n['notification_type'] as String).startsWith('payment'),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final session = await _localStorage.getWorkerSession();
      if (session == null) return;

      _workerId = int.parse(session['workerId']!);

      // Önce eski okunmuş bildirimleri sil (1 günden eski)
      await _deleteOldReadNotifications(_workerId!);

      final notifications = await _notificationService.getAllNotifications(
        _workerId!,
      );

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Bildirim yükleme hatası: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Eski okunmuş bildirimleri sil (1 günden eski)
  Future<void> _deleteOldReadNotifications(int workerId) async {
    try {
      // Bugünün başlangıcını UTC'de hesapla
      final now = DateTime.now().toUtc();
      final todayStartUtc = DateTime.utc(now.year, now.month, now.day);
      final todayStartStr = todayStartUtc.toIso8601String();

      debugPrint('🗑️ Eski bildirimler siliniyor...');
      debugPrint('  Şu an (UTC): $now');
      debugPrint('  Bugün başlangıç (UTC): $todayStartUtc');
      debugPrint('  Silme kriteri: created_at < $todayStartStr');

      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('recipient_id', workerId)
          .eq('recipient_type', 'worker')
          .eq('is_read', true)
          .lt('created_at', todayStartStr);

      debugPrint('✅ Eski okunmuş bildirimler silindi (worker)');
    } catch (e) {
      debugPrint('⚠️ Eski bildirim silme hatası (worker): $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    if (_workerId == null) return;

    await _notificationService.markAllAsRead(_workerId!);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Tümünü okundu işaretle butonu
                if (_notifications.any((n) => n['is_read'] == false))
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: w * 0.04, top: h * 0.01),
                    child: TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: Icon(Icons.done_all, size: w * 0.045),
                      label: Text(
                        'Tümünü okundu işaretle',
                        style: TextStyle(fontSize: w * 0.035),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.01,
                        ),
                      ),
                    ),
                  ),

                // İstatistik kartları
                if (_notifications.isNotEmpty) _buildStatsCards(w, h, isDark),

                // Filtre butonları
                if (_notifications.isNotEmpty) _buildFilterChips(w, h, isDark),

                // Bildirim listesi
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? _buildEmptyState(w, h, theme, isDark)
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: primaryColor,
                          child: _buildNotificationList(w, h, theme, isDark),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCards(double w, double h, bool isDark) {
    final unreadCount = _notifications
        .where((n) => n['is_read'] == false)
        .length;
    final todayCount = _notifications.where((n) {
      final createdAt = DateTime.parse(n['created_at']).toLocal();
      final today = DateTime.now();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.01),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.mark_email_unread_outlined,
              label: 'Okunmamış',
              value: unreadCount.toString(),
              color: const Color(0xFF4338CA),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.today_outlined,
              label: 'Bugün',
              value: todayCount.toString(),
              color: Colors.orange,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.notifications_outlined,
              label: 'Toplam',
              value: _notifications.length.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double w,
    double h,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.008, horizontal: w * 0.02),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: w * 0.05),
          SizedBox(height: h * 0.003),
          Text(
            value,
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.026,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(double w, double h, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(left: w * 0.04, top: h * 0.01, bottom: h * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Okunma durumu filtreleri
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip(
                    w,
                    h,
                    isDark,
                    label: 'Tümü',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  SizedBox(width: w * 0.02),
                  _buildFilterChip(
                    w,
                    h,
                    isDark,
                    label: 'Okunmamış',
                    isSelected: _selectedFilter == 'unread',
                    onTap: () => setState(() => _selectedFilter = 'unread'),
                  ),
                  SizedBox(width: w * 0.02),
                  _buildFilterChip(
                    w,
                    h,
                    isDark,
                    label: 'Okunmuş',
                    isSelected: _selectedFilter == 'read',
                    onTap: () => setState(() => _selectedFilter = 'read'),
                  ),
                  SizedBox(width: w * 0.04), // Sağ padding için
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.01),
          // Bildirim tipi filtreleri
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypeChip(
                    w,
                    h,
                    isDark,
                    icon: Icons.filter_list,
                    label: 'Tümü',
                    isSelected: _selectedType == 'all',
                    onTap: () => setState(() => _selectedType = 'all'),
                  ),
                  SizedBox(width: w * 0.02),
                  _buildTypeChip(
                    w,
                    h,
                    isDark,
                    icon: Icons.calendar_today,
                    label: 'Yevmiye',
                    isSelected: _selectedType == 'attendance',
                    onTap: () => setState(() => _selectedType = 'attendance'),
                  ),
                  SizedBox(width: w * 0.02),
                  _buildTypeChip(
                    w,
                    h,
                    isDark,
                    icon: Icons.payments,
                    label: 'Ödemeler',
                    isSelected: _selectedType == 'payment',
                    onTap: () => setState(() => _selectedType = 'payment'),
                  ),
                  SizedBox(width: w * 0.04), // Sağ padding için
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    double w,
    double h,
    bool isDark, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(
    double w,
    double h,
    bool isDark, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.035,
          vertical: h * 0.008,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: w * 0.04,
              color: isSelected
                  ? primaryColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600),
            ),
            SizedBox(width: w * 0.015),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double w, double h, ThemeData theme, bool isDark) {
    String emptyMessage = 'Henüz bildirim yok';
    IconData emptyIcon = Icons.notifications_none_rounded;

    if (_selectedFilter == 'unread') {
      emptyMessage = 'Okunmamış bildiriminiz yok';
      emptyIcon = Icons.mark_email_read_outlined;
    } else if (_selectedFilter == 'read') {
      emptyMessage = 'Okunmuş bildiriminiz yok';
      emptyIcon = Icons.drafts_outlined;
    } else if (_selectedType != 'all') {
      emptyMessage = 'Bu tipte bildirim bulunamadı';
      emptyIcon = Icons.filter_list_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: w * 0.15,
            color: const Color(0xFF4338CA).withValues(alpha: 0.2),
          ),
          SizedBox(height: h * 0.02),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            _selectedFilter != 'all' || _selectedType != 'all'
                ? 'Farklı bir filtre deneyin'
                : 'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    double w,
    double h,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, h * 0.12),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationCard(w, h, notification, theme, isDark);
      },
    );
  }

  Widget _buildNotificationCard(
    double w,
    double h,
    Map<String, dynamic> notification,
    ThemeData theme,
    bool isDark,
  ) {
    final id = notification['id'] as int;
    final title = notification['title'] as String;
    var message = notification['message'] as String;

    // fullDay ve halfDay'i Türkçe'ye çevir
    message = message
        .replaceAll('(fullDay)', '(Tam Gün)')
        .replaceAll('(halfDay)', '(Yarım Gün)')
        .replaceAll('fullDay', 'Tam Gün')
        .replaceAll('halfDay', 'Yarım Gün');

    final isRead = notification['is_read'] as bool;
    final createdAt = DateTime.parse(notification['created_at']).toLocal();
    final notificationType = notification['notification_type'] as String;
    final relatedId = notification['related_id'] as int?;

    final icon = _getNotificationIcon(notificationType);
    final color = _getNotificationColor(notificationType, theme);

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await _markAsRead(id);
        }
        _handleNotificationTap(notificationType, relatedId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF9FAFB))
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: !isRead
              ? Border(
                  left: BorderSide(color: const Color(0xFF4338CA), width: 4),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(w * 0.04),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: isRead ? 0.5 : 1.0,
                child: Container(
                  width: w * 0.11,
                  height: w * 0.11,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: w * 0.055),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: isRead ? 0.7 : 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.004),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: isRead ? 0.5 : 0.6,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                        'tr_TR',
                      ).format(createdAt),
                      style: TextStyle(
                        fontSize: w * 0.03,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bildirime tıklandığında ilgili sayfaya yönlendir
  void _handleNotificationTap(String notificationType, int? relatedId) {
    debugPrint('🔔 Bildirime tıklandı: $notificationType (ID: $relatedId)');

    switch (notificationType) {
      case 'attendance_approved':
      case 'attendance_rejected':
      case 'attendance_reminder':
        debugPrint('  📍 Bildirimler sayfasında kalınıyor');
        break;
      case 'payment_received':
        debugPrint('  📍 Ödeme geçmişi sayfasına yönlendiriliyor...');
        _navigateToPaymentHistory();
        break;
      case 'payment_updated':
      case 'payment_deleted':
        debugPrint('  📍 Bildirimler sayfasında kalınıyor');
        break;
      default:
        debugPrint('  ⚠️ Bilinmeyen bildirim tipi');
    }
  }

  Future<void> _navigateToPaymentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('worker_attendance_initial_tab', 1);
      await prefs.setString('worker_notification_type', 'payment_received');
      await prefs.setBool('has_pending_notification', true);
      debugPrint('✅ Ödeme geçmişi yönlendirmesi için bilgi kaydedildi');

      // Ana ekrana geri dön ve tab değişimini tetikle
      if (mounted) {
        // Bildirimler sayfasından çık, ana ekran tab'ı otomatik değişecek
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('❌ Yönlendirme bilgisi kaydedilemedi: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'attendance_request':
        return Icons.calendar_today;
      case 'attendance_reminder':
        return Icons.alarm;
      case 'attendance_approved':
        return Icons.check_circle;
      case 'attendance_rejected':
        return Icons.cancel;
      case 'payment_received':
      case 'payment_notification':
        return Icons.payment;
      case 'payment_updated':
        return Icons.edit_notifications;
      case 'payment_deleted':
        return Icons.delete_outline;
      case 'general':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, ThemeData theme) {
    switch (type) {
      case 'attendance_request':
        return Colors.blue;
      case 'attendance_reminder':
        return Colors.orange;
      case 'attendance_approved':
        return Colors.green;
      case 'attendance_rejected':
        return Colors.red;
      case 'payment_received':
      case 'payment_notification':
        return Colors.green;
      case 'payment_updated':
        return Colors.blue;
      case 'payment_deleted':
        return Colors.red;
      case 'general':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
