import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/employee_reminder.dart';
import '../../services/employee_reminder_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/app_globals.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/user_data_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../home/mixins/home_drawer.dart';
import '../widgets/index.dart';

class EmployeeReminderDetailScreen extends ConsumerStatefulWidget {
  final int? reminderId;

  const EmployeeReminderDetailScreen({super.key, this.reminderId});

  @override
  ConsumerState<EmployeeReminderDetailScreen> createState() =>
      _EmployeeReminderDetailScreenState();
}

class _EmployeeReminderDetailScreenState
    extends ConsumerState<EmployeeReminderDetailScreen> {
  final EmployeeReminderService _reminderService = EmployeeReminderService();

  bool _isLoading = true;
  bool _isDeleting = false;
  EmployeeReminder? _reminder;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int? reminderId = widget.reminderId;

      // ÖNCELİK 1: Router'dan gelen reminderId (widget parametresi)
      if (reminderId != null) {
        debugPrint(
          '🎯 EmployeeReminderDetail: Router\'dan reminderId alındı: $reminderId',
        );
      } else {
        debugPrint(
          '⚠️ EmployeeReminderDetail: Router\'dan reminderId gelmedi, fallback mekanizmaları deneniyor',
        );

        // ÖNCELİK 2: NotificationService'ten kontrol et (fallback)
        try {
          final notificationService = NotificationService();
          final notification = await notificationService
              .getPendingNotification();
          if (notification != null && notification.isEmployeeReminder) {
            reminderId = notification.reminderId;
            debugPrint(
              '📬 EmployeeReminderDetail: NotificationService\'ten reminderId alındı: $reminderId',
            );
          }
        } catch (e) {
          debugPrint(
            '❌ EmployeeReminderDetail: NotificationService fallback hatası: $e',
          );
        }

        // ÖNCELİK 3: SharedPreferences'tan kontrol et (geriye dönük uyumluluk)
        if (reminderId == null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            reminderId = prefs.getInt('active_employee_reminder_id');
            if (reminderId != null) {
              debugPrint(
                '💾 EmployeeReminderDetail: SharedPreferences\'tan reminderId alındı: $reminderId',
              );
            }
          } catch (e) {
            debugPrint(
              '❌ EmployeeReminderDetail: SharedPreferences fallback hatası: $e',
            );
          }
        }
      }

      // Hiçbir kaynaktan reminderId alınamadıysa hata göster
      if (reminderId == null) {
        debugPrint(
          '❌ EmployeeReminderDetail: Hiçbir kaynaktan reminderId alınamadı',
        );
        _showSnackBar('Hatırlatıcı bulunamadı');
        return;
      }

      debugPrint(
        '🔍 EmployeeReminderDetail: Hatırlatıcı yükleniyor (ID: $reminderId)',
      );

      // Tüm hatırlatıcıları al
      final reminders = await _reminderService.getEmployeeReminders(
        includeCompleted: true,
      );

      // ID'ye göre hatırlatıcıyı bul
      final reminder = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => throw Exception('Hatırlatıcı bulunamadı'),
      );

      if (mounted) {
        setState(() {
          _reminder = reminder;
        });
      }

      debugPrint(
        '✅ EmployeeReminderDetail: Hatırlatıcı yüklendi: ${reminder.workerName}',
      );

      // Hatırlatıcıyı tamamlandı olarak işaretle
      await _reminderService.markReminderAsCompletedWithNotification(
        reminderId,
      );

      debugPrint(
        '✅ EmployeeReminderDetail: Hatırlatıcı tamamlandı olarak işaretlendi',
      );
    } catch (e, stackTrace) {
      debugPrint('EmployeeReminderDetail: Hatırlatıcı yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar('Hatırlatıcı yüklenirken bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userDataProvider);
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';
    final isAdmin = currentUser?['is_admin'] == true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: globalScaffoldKey,
      appBar: AppBar(title: const Text('Çalışan Hatırlatıcısı')),
      drawer: HomeDrawer(
        firstName: firstName,
        lastName: lastName,
        isAdmin: isAdmin,
        selectedIndex: null,
        onItemTap: (index) {
          // Drawer'ı kapat
          Navigator.pop(context);
          // Kısa gecikme sonrası navigasyon (drawer animasyonu için)
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              // Mevcut ekranı kapat ve home'a git
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              context.go('/home', extra: {'initialTab': index});
            }
          });
        },
        onThemeToggle: () async {
          final currentMode = ref.read(themeStateProvider);
          final newMode = currentMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;

          // Riverpod provider ile tema değiştir (otomatik kaydeder)
          ref.read(themeStateProvider.notifier).setTheme(newMode);
        },
        onLogout: () {
          Navigator.pop(context); // Drawer'ı kapat

          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hayır'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Dialog'u kapat

                    try {
                      final authService = AuthService();
                      await authService.signOut();
                                            if (mounted && context.mounted) {
                        final container = ProviderScope.containerOf(context);
                        container.read(authStateProvider.notifier).logout();
                        context.go('/login');
                      }
                    } catch (e) {
                      debugPrint('Çıkış hatası: $e');
                      if (mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  child: const Text('Evet'),
                ),
              ],
            ),
          );
        },
        isDarkMode: isDarkMode,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminder == null
          ? const Center(child: Text('Hatırlatıcı bulunamadı'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReminderHeader(reminder: _reminder!),
                          ReminderMessageCard(reminder: _reminder!),
                        ],
                      ),
                    ),
                  ),
                  ReminderActionButtons(
                    isDeleting: _isDeleting,
                    onConfirm: _showDeleteConfirmationDialog,
                  ),
                ],
              ),
            ),
    );
  }

  void _showDeleteConfirmationDialog() {
    DeleteConfirmationDialog.show(context, onConfirm: _deleteReminder);
  }

  // Hatırlatıcıyı sil
  Future<void> _deleteReminder() async {
    if (_reminder?.id == null) {
      if (mounted) {
        _showSnackBar('Hatırlatıcı bulunamadı');
      }
      return;
    }

    if (_isDeleting || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final reminderId = _reminder!.id!;

    try {
      debugPrint(
        '🗑️ EmployeeReminderDetail: Hatırlatıcı siliniyor (ID: $reminderId)',
      );

      final success = await _reminderService
          .deleteEmployeeReminderWithNotification(reminderId);

      if (!mounted) return;

      if (success) {
        debugPrint('EmployeeReminderDetail: Hatırlatıcı başarıyla silindi');

        // Hatırlatıcı silindikten sonra bildirim durumunu temizle
        try {
          final notificationService = NotificationService();
          await notificationService.clearPendingNotification();

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('active_employee_reminder_id');

          debugPrint('🧹 EmployeeReminderDetail: Bildirim durumu temizlendi');
        } catch (e) {
          debugPrint(
            '⚠️ EmployeeReminderDetail: Bildirim temizleme hatası (göz ardı edildi): $e',
          );
        }

        if (!mounted) return;

        // SnackBar göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hatırlatıcı başarıyla silindi'),
            duration: Duration(seconds: 2),
          ),
        );

        // Kısa gecikme sonrası navigasyon
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // Güvenli navigasyon: pop ile geri dön
        debugPrint('🔙 EmployeeReminderDetail: Geri dönülüyor');

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          debugPrint('EmployeeReminderDetail: Navigator.pop başarılı');
        } else {
          // Eğer pop yapılamazsa, home'a git
          debugPrint(
            '⚠️ EmployeeReminderDetail: Pop yapılamıyor, home\'a gidiliyor',
          );
          context.go('/home');
        }
      } else {
        debugPrint('EmployeeReminderDetail: Silme işlemi başarısız');
        if (mounted) {
          _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('EmployeeReminderDetail: Silme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar('Hatırlatıcı silinirken bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
