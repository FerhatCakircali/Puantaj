import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/employee_reminder.dart';
import '../services/employee_reminder_service.dart';
import '../services/notification_service.dart';
import '../widgets/common_button.dart';
import '../main.dart'; // themeModeNotifier için
import 'home_screen.dart'; // globalSelectedIndexNotifier için import
import '../core/user_data_notifier.dart'; // userDataNotifier için import
import '../services/auth_service.dart'; // AuthService için

class EmployeeReminderDetailScreen extends StatefulWidget {
  final int? reminderId;

  const EmployeeReminderDetailScreen({Key? key, this.reminderId})
    : super(key: key);

  @override
  State<EmployeeReminderDetailScreen> createState() =>
      _EmployeeReminderDetailScreenState();
}

class _EmployeeReminderDetailScreenState
    extends State<EmployeeReminderDetailScreen> {
  final EmployeeReminderService _reminderService = EmployeeReminderService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isDeleting = false;
  EmployeeReminder? _reminder;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int? reminderId = widget.reminderId;

      // Eğer widget üzerinden ID gelmezse SharedPreferences'tan kontrol et
      if (reminderId == null) {
        final prefs = await SharedPreferences.getInstance();
        reminderId = prefs.getInt('active_employee_reminder_id');
      }

      if (reminderId == null) {
        _showSnackBar('Hatırlatıcı bulunamadı');
        return;
      }

      // Tüm hatırlatıcıları al
      final reminders = await _reminderService.getEmployeeReminders(
        includeCompleted: true,
      );

      // ID'ye göre hatırlatıcıyı bul
      final reminder = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => throw Exception('Hatırlatıcı bulunamadı'),
      );

      setState(() {
        _reminder = reminder;
      });

      // Hatırlatıcıyı tamamlandı olarak işaretle
      await _reminderService.markReminderAsCompleted(reminderId);

      // SharedPreferences'tan temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_employee_reminder_id');
    } catch (e) {
      print('Hatırlatıcı yüklenirken hata: $e');
      _showSnackBar('Hatırlatıcı yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalScaffoldKey,
      appBar: AppBar(title: const Text('Çalışan Hatırlatıcısı')),
      drawer: _buildDrawer(context),
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
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(_reminder!.workerName[0]),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reminder!.workerName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hatırlatıcı Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(_reminder!.reminderDate)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Hatırlatıcı Mesajı:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _reminder!.message,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_reminder!.isCompleted)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bu hatırlatıcı tamamlandı',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  CommonButton(
                    onPressed: () {
                      if (_isDeleting) return;
                      // Onay dialogu göster
                      _showDeleteConfirmationDialog();
                    },
                    label: 'Tamam',
                    icon: Icons.check,
                    isLoading: _isDeleting,
                  ),
                ],
              ),
            ),
    );
  }

  // Silme onay dialogu
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hatırlatıcıyı Sil'),
          content: const Text(
            'Bu hatırlatıcı bildirim mesajı silinecek. Onaylıyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _deleteReminder(); // Hatırlatıcıyı sil
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  // Hatırlatıcıyı sil
  Future<void> _deleteReminder() async {
    if (_reminder?.id == null) {
      _showSnackBar('Hatırlatıcı bulunamadı');
      return;
    }

    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final reminderId = _reminder!.id!;
    print('Detay ekrandan silme başlatıldı: id=$reminderId');

    try {
      // Hatırlatıcıyı sil
      final success = await _reminderService.deleteEmployeeReminder(reminderId);

      if (success) {
        print('Detay ekrandan silme başarılı: id=$reminderId');
        _showSnackBar('Hatırlatıcı başarıyla silindi');

        // Bu ekran genellikle NotificationSettingsScreen'den push ile açılıyor.
        // Silme başarılıysa bir üst ekrana "silindi" sonucu dönelim.
        // Böylece üst ekran isterse listeyi hemen yenileyebilir.
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        print('Detay ekrandan silme başarısız: id=$reminderId');
        _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
      }
    } catch (e) {
      print('Hatırlatıcı silinirken hata: $e');
      _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
    }
  }

  // Drawer menüsü - HomeScreen'dekine benzer şekilde güncellendi
  Widget _buildDrawer(BuildContext context) {
    // userDataNotifier dinleyerek güncel kullanıcı bilgisini al
    final currentUser = userDataNotifier.value;
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';

    return Drawer(
      width:
          MediaQuery.of(context).size.width *
          0.75, // Çekmece genişliği ekranın %75'i
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      elevation: 16.0,
      child: Column(
        children: <Widget>[
          // Başlık Alanı
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Uygulama simgesi
                Image.asset('assets/icons/icon.png', width: 60, height: 60),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Puantaj',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Takip',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Kullanıcı adı ve soyadı
                      if (firstName.isNotEmpty || lastName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            '$firstName $lastName',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerItem(
                  icon: Icons.people_alt_outlined,
                  text: 'Çalışanlar',
                  onTap: () {
                    // Ana sayfaya git ve çalışanlar sekmesini seç (0)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 0;
                    }
                    context.go('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_month_outlined,
                  text: 'Yevmiye',
                  onTap: () {
                    // Ana sayfaya git ve yevmiye sekmesini seç (1)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 1;
                    }
                    context.go('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment_outlined,
                  text: 'Ödeme',
                  onTap: () {
                    // Ana sayfaya git ve ödeme sekmesini seç (2)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 2;
                    }
                    context.go('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart_outlined,
                  text: 'Raporlar',
                  onTap: () {
                    // Ana sayfaya git ve raporlar sekmesini seç (3)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 3;
                    }
                    context.go('/home');
                  },
                ),
                // Admin kullanıcısıysa Admin Paneli öğesini göster
                if (currentUser?['is_admin'] == true)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Admin Panel',
                    onTap: () {
                      // Ana sayfaya git ve admin paneli sekmesini seç (4)
                      if (globalSelectedIndexNotifier != null) {
                        globalSelectedIndexNotifier!.value = 4;
                      }
                      context.go('/home');
                    },
                  ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  text: 'Profil',
                  onTap: () {
                    // Ana sayfaya git ve profil sekmesini seç (5)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 5;
                    }
                    context.go('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  text: 'Bildirim Ayarları',
                  onTap: () => context.go('/notification_settings'),
                ),
                _buildDrawerItem(
                  icon: Icons.account_circle_outlined,
                  text: 'Kullanıcı Hesapları',
                  onTap: () {
                    // Ana sayfaya git ve kullanıcı hesapları sekmesini seç (7)
                    if (globalSelectedIndexNotifier != null) {
                      globalSelectedIndexNotifier!.value = 7;
                    }
                    context.go('/home');
                  },
                ),
                const Divider(
                  height: 32,
                  thickness: 0.5,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey,
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, child) {
                    final isDark = mode == ThemeMode.dark;
                    return _buildDrawerItem(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      text: isDark ? 'Açık Tema' : 'Koyu Tema',
                      onTap: () {
                        themeModeNotifier.value = isDark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Çıkış Yap öğesi
          const Divider(
            height: 16,
            thickness: 0.5,
            indent: 20,
            endIndent: 20,
            color: Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(10),
                hoverColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.1),
                splashColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.0),
        ],
      ),
    );
  }

  // Drawer öğeleri için yardımcı fonksiyon
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: theme.colorScheme.primary.withOpacity(0.08),
          splashColor: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Çıkış yapma dialogu
  void _showLogoutDialog(BuildContext context) {
    // Şu anki context'i sakla
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dialog'u kapat
            },
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Dialog'u kapat

              // Çıkış yap
              await _authService.signOut();

              // Ana sayfa yönlendirme
              authStateNotifier.value = false;
              context.go('/login');
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
