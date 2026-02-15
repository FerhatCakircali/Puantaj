import 'dart:io';
import 'package:flutter/material.dart';
import '../models/notification_settings.dart';
import '../models/employee_reminder.dart';
import '../services/notification_service.dart';
import '../services/attendance_check.dart';
import '../services/employee_reminder_service.dart';
import '../widgets/common_button.dart';
import '../services/worker_service.dart';
import '../models/worker.dart';
import '../screens/employee_reminder_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../main.dart'; // globalScaffoldKey için

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final EmployeeReminderService _reminderService = EmployeeReminderService();
  final WorkerService _workerService = WorkerService();
  final AuthService _authService = AuthService();

  late TabController _tabController;

  bool _isLoading = true;
  // Başlangıçta kapalı: Ayarlar veritabanından yüklenince doğru değer set edilir.
  // Böylece kullanıcı bildirimleri kapalıyken switch yanlışlıkla açık görünmez.
  bool _isEnabled = false;
  String _selectedTime = '18:00';
  NotificationSettings? _settings;

  // Çalışan hatırlatıcıları için değişkenler
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<EmployeeReminder> _reminders = [];
  // Silme işlemi başlatılıp henüz tamamlanmayan hatırlatıcılar.
  // Amaç: _loadReminders gecikmeli tamamlandığında, sunucudan gelen eski verinin UI'a geri basmasını engellemek.
  final Set<int> _pendingDeleteReminderIds = <int>{};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingWorkers = false;
  bool _isLoadingReminders = false;

  // _loadReminders'in yarış durumlarında (concurrent) en son sonucu uygulamak için sayaç.
  int _remindersLoadRequestId = 0;

  // İzin durumlarını kontrol etmek için değişkenler
  bool _hasNotificationPermission = false;
  bool _hasBatteryOptimizationDisabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('NotificationSettingsScreen initState');
    _loadSettings();
    _loadWorkers();
    _loadReminders();

    // Kaydedilmiş sekme indeksini kontrol et
    _checkSavedTabIndex();
    _checkPermissions();
  }

  @override
  void dispose() {
    print('NotificationSettingsScreen dispose');
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa görünür olduğunda hatırlatıcıları yenile
    _loadReminders();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoadingWorkers = true;
    });

    try {
      final workers = await _workerService.getWorkers();
      setState(() {
        _workers = workers;
        _filteredWorkers = workers;
      });
    } catch (e) {
      print('Çalışanlar yüklenirken hata: $e');
      _showSnackBar('Çalışanlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        _isLoadingWorkers = false;
      });
    }
  }

  void _filterWorkers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWorkers = _workers;
      } else {
        _filteredWorkers = _workers
            .where(
              (worker) =>
                  worker.fullName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _loadSettings() async {
    print('_loadSettings başlatıldı');
    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcı ID'sini kontrol et
      final userId = await _notificationService.getCurrentUserId();
      if (userId == null) {
        print('Kullanıcı ID bulunamadı');
        _showSnackBar('Oturum bilgisi alınamadı');
        return;
      }

      final settings = await _notificationService.getNotificationSettings();
      print('Alınan ayarlar: $settings');

      if (settings != null) {
        setState(() {
          _settings = settings;
          _isEnabled = settings.enabled;
          _selectedTime = settings.time;
        });
        print(
          'Ayarlar yüklendi: id=${settings.id}, enabled=${settings.enabled}, time=${settings.time}',
        );
      } else {
        print('Ayarlar bulunamadı, bildirimler kapalı olarak ayarlanıyor');
        // Bildirimleri kapalı olarak ayarla
        setState(() {
          _settings = null;
          _isEnabled = false; // Bildirimler varsayılan olarak kapalı
          _selectedTime = '18:00'; // Varsayılan saat
        });
      }
    } catch (e) {
      print('Ayarlar yüklenirken hata: $e');
      _showSnackBar('Ayarlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    print('_saveSettings başlatıldı');

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _notificationService.getCurrentUserId();
      if (userId == null) {
        print('Kullanıcı ID bulunamadı');
        _showSnackBar('Oturum bilgisi alınamadı');
        return;
      }

      // _settings null ise yeni bir ayar nesnesi oluştur
      final NotificationSettings settingsToSave =
          _settings ??
          NotificationSettings(
            userId: userId,
            time: _selectedTime,
            enabled: _isEnabled,
            lastUpdated: DateTime.now(),
          );

      // Güncel değerleri içeren yeni bir nesne oluştur
      final updatedSettings = NotificationSettings(
        id: settingsToSave.id,
        userId: userId,
        time: _selectedTime,
        enabled: _isEnabled,
        lastUpdated: DateTime.now(),
      );

      print(
        'Ayarlar güncelleniyor: id=${updatedSettings.id}, enabled=$_isEnabled, time=$_selectedTime',
      );

      print('updateNotificationSettings çağrılıyor...');
      final success = await _notificationService.updateNotificationSettings(
        updatedSettings,
      );
      print('updateNotificationSettings sonucu: $success');

      if (success) {
        // İzinleri kontrol et
        await _checkPermissions();

        // Bugün için yevmiye girişi yapılmış mı kontrol et
        final hasAttendanceToday = await _notificationService
            .hasAttendanceEntryForToday();
        final attendanceDoneLocally =
            await AttendanceCheck.isTodayAttendanceDone();

        if (hasAttendanceToday || attendanceDoneLocally) {
          _showSnackBar(
            'Bildirim ayarları kaydedildi. Bugün için yevmiye girişi zaten yapılmış.',
          );
        } else if (_isEnabled) {
          // Saat kontrolü yap
          final now = DateTime.now();
          final timeParts = _selectedTime.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          if (scheduledTime.isBefore(now)) {
            _showSnackBar(
              'Bildirim ayarları kaydedildi. Belirtilen saat geçtiği için bildirim yarın etkin olacak.',
            );
          } else {
            _showSnackBar(
              'Bildirim ayarları kaydedildi. Bildirim bugün ${_selectedTime} saatinde gönderilecek.',
            );
          }
        } else {
          _showSnackBar(
            'Bildirim ayarları kaydedildi. Bildirimler devre dışı bırakıldı.',
          );
        }

        print('Ayarlar başarıyla kaydedildi');

        // Ayarları yeniden yükle
        await _loadSettings();
      } else {
        _showSnackBar('Bildirim ayarları kaydedilirken bir hata oluştu');
        print('Ayarlar kaydedilemedi');
      }
    } catch (e) {
      print('Ayarlar kaydedilirken hata: $e');
      _showSnackBar('Ayarlar kaydedilirken bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay currentTime = TimeOfDay(
      hour: int.parse(_selectedTime.split(':')[0]),
      minute: int.parse(_selectedTime.split(':')[1]),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              dialTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.sendTestNotification();
    _showSnackBar('Test bildirimi gönderildi');
  }

  Future<void> _showEmployeeReminderDialog(Worker worker) async {
    final DateTime now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay selectedTime = TimeOfDay.now();
    final TextEditingController messageController = TextEditingController();

    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${worker.fullName} için Hatırlatıcı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tarih:'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: DateTime(now.year + 5),
                      builder: (context, child) {
                        return Theme(data: Theme.of(context), child: child!);
                      },
                    );

                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Saat:'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(data: Theme.of(context), child: child!);
                      },
                    );

                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hatırlatıcı Mesajı:'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Hatırlatıcı mesajınızı yazın...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lütfen bir hatırlatıcı mesajı girin',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        // Seçilen tarih ve saati birleştir
                        final reminderDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Hatırlatıcı oluştur
                        final reminder = EmployeeReminder(
                          userId: worker.userId,
                          workerId: worker.id!,
                          workerName: worker.fullName,
                          reminderDate: reminderDate,
                          message: messageController.text.trim(),
                        );

                        // Hatırlatıcıyı kaydet
                        final result = await _reminderService
                            .addEmployeeReminder(reminder);

                        if (result != null) {
                          Navigator.pop(context);
                          _showSnackBar(
                            '${worker.fullName} için hatırlatıcı eklendi',
                          );
                          // Hatırlatıcı listesini güncelle
                          _loadReminders();
                        } else {
                          _showSnackBar(
                            'Hatırlatıcı eklenirken bir hata oluştu',
                          );
                        }
                      } catch (e) {
                        print('Hatırlatıcı eklenirken hata: $e');
                        _showSnackBar(
                          'Hatırlatıcı eklenirken bir hata oluştu: $e',
                        );
                      } finally {
                        setDialogState(() {
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadReminders() async {
    final requestId = ++_remindersLoadRequestId;
    setState(() {
      _isLoadingReminders = true;
    });

    try {
      final reminders = await _reminderService.getEmployeeReminders();

      // Eğer bu istekten sonra daha yeni bir istek başladıysa, bu sonucu uygulamayalım.
      if (!mounted || requestId != _remindersLoadRequestId) return;

      setState(() {
        // Silme beklemede olanları UI'da göstermeyelim.
        _reminders = reminders
            .where(
              (r) => r.id == null || !_pendingDeleteReminderIds.contains(r.id),
            )
            .toList();
      });
    } catch (e) {
      print('Hatırlatıcılar yüklenirken hata: $e');
      _showSnackBar('Hatırlatıcılar yüklenirken bir hata oluştu');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReminders = false;
      });
    }
  }

  // Hatırlatıcıyı UI listesinden anında kaldırıp (optimistic update) sonra veritabanından siler.
  // Silme başarısız olursa, hatırlatıcıyı listeye geri ekler.
  Future<void> _deleteReminderOptimistic(
    int listIndex,
    EmployeeReminder reminder,
  ) async {
    if (reminder.id == null) return;

    final reminderId = reminder.id!;
    print('Hatırlatıcı silme başlatıldı: id=$reminderId, listIndex=$listIndex');

    // Silme sürecinde loadReminders eski veriyi basmasın diye işaretle.
    _pendingDeleteReminderIds.add(reminderId);

    // Önce UI'dan kaldır
    setState(() {
      // Index kayabilir; bu yüzden id üzerinden kaldırmak daha güvenli.
      _reminders.removeWhere((r) => r.id == reminderId);
    });

    try {
      final success = await _reminderService.deleteEmployeeReminder(reminderId);
      if (success) {
        _pendingDeleteReminderIds.remove(reminderId);
        print('Hatırlatıcı silme başarılı: id=$reminderId');
        _showSnackBar('Hatırlatıcı silindi');
        // Ek güvenlik: Sunucu ile UI senkron kalsın diye bir kez yenile
        _loadReminders();
      } else {
        _pendingDeleteReminderIds.remove(reminderId);
        print('Hatırlatıcı silme başarısız: id=$reminderId');
        // Başarısızsa geri ekle
        setState(() {
          final safeIndex = listIndex.clamp(0, _reminders.length);
          _reminders.insert(safeIndex, reminder);
        });
        _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
      }
    } catch (e) {
      _pendingDeleteReminderIds.remove(reminderId);
      // Hata olursa geri ekle
      setState(() {
        final safeIndex = listIndex.clamp(0, _reminders.length);
        _reminders.insert(safeIndex, reminder);
      });
      print('Hatırlatıcı silinirken hata: $e');
      _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
    }
  }

  // Kaydedilmiş sekme indeksini kontrol et
  Future<void> _checkSavedTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTabIndex = prefs.getInt('notification_settings_tab_index');

      if (savedTabIndex != null) {
        // Sekme indeksini ayarla
        setState(() {
          _tabController.animateTo(savedTabIndex);
        });

        // Kullanıldıktan sonra temizle
        await prefs.remove('notification_settings_tab_index');
      }
    } catch (e) {
      print('Sekme indeksi kontrol edilirken hata: $e');
    }
  }

  // İzinleri kontrol et
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      // Bildirim izinlerini kontrol et
      final notificationStatus = await Permission.notification.status;

      // Pil optimizasyonu izinlerini kontrol et
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      setState(() {
        _hasNotificationPermission = notificationStatus.isGranted;
        _hasBatteryOptimizationDisabled = batteryStatus.isGranted;
      });

      print('Bildirim izni: $_hasNotificationPermission');
      print('Pil optimizasyonu devre dışı: $_hasBatteryOptimizationDisabled');
    }
  }

  // İzinleri iste
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Bildirim izinlerini iste
      if (!_hasNotificationPermission) {
        final status = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = status.isGranted;
        });
      }

      // Pil optimizasyonu izinlerini iste
      if (!_hasBatteryOptimizationDisabled) {
        final status = await Permission.ignoreBatteryOptimizations.request();
        setState(() {
          _hasBatteryOptimizationDisabled = status.isGranted;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null, // Boş text yerine null kullanarak boşluğu engelliyoruz
        toolbarHeight: 0, // Toolbar yüksekliğini sıfıra indiriyoruz
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_active),
              text: 'Yevmiye Hatırlatıcısı',
            ),
            Tab(icon: Icon(Icons.person_add), text: 'Çalışan Hatırlatıcıları'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Yevmiye Hatırlatıcısı Sekmesi
            _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                const Text(
                                  '"Hatırlatıcıyı Etkinleştir" butonu aktif olduğu sürece ve yevmiye girişi yapılmadığında her gün belirlenen saatte bildirim gönderilir.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text(
                                    'Hatırlatıcıyı Etkinleştir',
                                  ),
                                  value: _isEnabled,
                                  onChanged: (value) async {
                                    // Kullanıcı hatırlatıcıyı açtığında gerekli izinleri anında iste.
                                    // İzin verilmezse, hatırlatıcıyı açık bırakmayıp tekrar kapatıyoruz.
                                    if (value) {
                                      await _requestPermissions();
                                      await _checkPermissions();

                                      if (!_hasNotificationPermission) {
                                        if (!mounted) return;
                                        _showSnackBar(
                                          'Bildirim izni verilmediği için hatırlatıcı açılamadı.',
                                        );
                                        setState(() {
                                          _isEnabled = false;
                                        });
                                        return;
                                      }
                                    }

                                    if (!mounted) return;
                                    setState(() {
                                      _isEnabled = value;
                                    });
                                    print(
                                      'Hatırlatıcı durumu değiştirildi: $_isEnabled',
                                    );

                                    // Kullanıcı switch'e dokunduğunda ayarı anında kaydet.
                                    // Böylece ayrıca "Ayarları Kaydet" butonuna basmadan bildirimler
                                    // aktif/pasif olur ve zamanlama yapılır.
                                    await _saveSettings();
                                  },
                                  secondary: Icon(
                                    _isEnabled
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                    color: _isEnabled
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  enabled: _isEnabled,
                                  title: const Text('Hatırlatma Saati'),
                                  subtitle: Text(_selectedTime),
                                  trailing: const Icon(Icons.access_time),
                                  onTap: _isEnabled ? _selectTime : null,
                                ),
                                if (_settings == null && !_isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Bildirim ayarlarınız bulunmuyor. Bildirimleri etkinleştirip saati belirledikten sonra "Ayarları Kaydet" butonuna tıklayın.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CommonButton(
                                onPressed: _isLoading
                                    ? () {}
                                    : () {
                                        print(
                                          'Ayarları Kaydet butonuna tıklandı',
                                        );
                                        _saveSettings();
                                      },
                                label: 'Ayarları Kaydet',
                                icon: Icons.save,
                                isLoading: _isLoading,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CommonButton(
                                onPressed: _isLoading
                                    ? () {}
                                    : () {
                                        print(
                                          'Test Bildirimi Gönder butonuna tıklandı',
                                        );
                                        _sendTestNotification();
                                      },
                                label: 'Test Bildirimi Gönder',
                                icon: Icons.send,
                                isLoading: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bildirim İzinleri',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Bildirimlerin düzgün çalışıp çalışmadığını "Test Bildirimi Gönder" butonuna basarak test edebilirsiniz. Bildirimlerin çalışması için cihaz ayarlarından bildirim izinlerini etkinleştirmeniz gerekebilir.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            // Çalışan Hatırlatıcıları Sekmesi
            Column(
              children: [
                // Arama alanı
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Çalışan Ara',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterWorkers('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _filterWorkers,
                  ),
                ),

                // Hatırlatıcılar ve çalışanlar için kalan alan
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        // Alt sekme çubuğu
                        TabBar(
                          tabs: const [
                            Tab(text: 'Hatırlatıcılar'),
                            Tab(text: 'Çalışanlar'),
                          ],
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),

                        // Sekme içerikleri
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Hatırlatıcılar sekmesi
                              _isLoadingReminders
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _reminders.isEmpty
                                  ? _buildEmptyRemindersView()
                                  : _buildRemindersListView(),

                              // Çalışanlar sekmesi
                              _isLoadingWorkers
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _filteredWorkers.isEmpty
                                  ? const Center(
                                      child: Text('Çalışan bulunamadı'),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredWorkers.length,
                                      itemBuilder: (context, index) {
                                        final worker = _filteredWorkers[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            child: Text(worker.fullName[0]),
                                          ),
                                          title: Text(worker.fullName),
                                          subtitle: Text(worker.title ?? ''),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                          ),
                                          onTap: () =>
                                              _showEmployeeReminderDialog(
                                                worker,
                                              ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderSection() {
    setState(() {
      _tabController.animateTo(1);
    });
  }

  Widget _buildRemindersSection() {
    return Expanded(
      child: Column(
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Mevcut Hatırlatıcılar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadReminders,
                  tooltip: 'Yenile',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Hatırlatıcılar listesi
          _isLoadingReminders
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount:
                        _reminders.length +
                        1, // +1 for "Yeni Hatırlatıcı Ekle" section
                    itemBuilder: (context, index) {
                      // Yeni Hatırlatıcı Ekle bölümü
                      if (index == 0) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: InkWell(
                            onTap: () {
                              // Yeni hatırlatıcı eklemek için çalışan listesini göster
                              _showAddReminderSection();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                      Icons.add,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Yeni Hatırlatıcı Ekle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Hatırlatıcı listesi
                      final reminderIndex = index - 1;
                      final reminder = _reminders[reminderIndex];
                      final isToday =
                          reminder.reminderDate.day == DateTime.now().day &&
                          reminder.reminderDate.month == DateTime.now().month &&
                          reminder.reminderDate.year == DateTime.now().year;
                      final isPast = reminder.reminderDate.isBefore(
                        DateTime.now(),
                      );

                      return Dismissible(
                        key: Key('reminder_${reminder.id}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hatırlatıcıyı Sil'),
                              content: const Text(
                                'Bu hatırlatıcıyı silmek istediğinizden emin misiniz?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('İptal'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Sil'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteReminderOptimistic(reminderIndex, reminder);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(reminder.workerName[0]),
                            ),
                            title: Text(reminder.workerName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(reminder.reminderDate),
                                  style: TextStyle(
                                    color: isToday
                                        ? Colors.green
                                        : isPast
                                        ? Colors.red
                                        : null,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                                Text(
                                  reminder.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: reminder.isCompleted
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(Icons.notifications_active),
                            onTap: () async {
                              // Detay ekrandan silme yapılırsa, pop(true) ile geri dönecek.
                              // Bu durumda listeyi anında yenileyerek UI'ın güncel kalmasını sağlıyoruz.
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EmployeeReminderDetailScreen(
                                            reminderId: reminder.id,
                                          ),
                                    ),
                                  );

                              if (result == true) {
                                _loadReminders();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const Divider(),
          // Çalışan seçme bölümü başlığı
          _buildWorkerSelectionHeader(),
        ],
      ),
    );
  }

  Widget _buildEmptyRemindersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Henüz hatırlatıcı eklenmemiş',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Çalışanlarınız için hatırlatıcı eklemek için "Çalışanlar" sekmesine geçin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRemindersListView() {
    return Column(
      children: [
        // Başlık ve yenileme butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'Mevcut Hatırlatıcılar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadReminders,
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),

        // Hatırlatıcı listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount:
                _reminders.length + 1, // +1 for "Yeni Hatırlatıcı Ekle" section
            itemBuilder: (context, index) {
              // Yeni Hatırlatıcı Ekle bölümü
              if (index == 0) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InkWell(
                    onTap: () {
                      // İkinci sekmeye geç
                      DefaultTabController.of(context).animateTo(1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Yeni Hatırlatıcı Ekle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Hatırlatıcı listesi
              final reminderIndex = index - 1;
              final reminder = _reminders[reminderIndex];
              final isToday =
                  reminder.reminderDate.day == DateTime.now().day &&
                  reminder.reminderDate.month == DateTime.now().month &&
                  reminder.reminderDate.year == DateTime.now().year;
              final isPast = reminder.reminderDate.isBefore(DateTime.now());

              return Dismissible(
                key: Key('reminder_${reminder.id}'),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hatırlatıcıyı Sil'),
                      content: const Text(
                        'Bu hatırlatıcıyı silmek istediğinizden emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteReminderOptimistic(reminderIndex, reminder);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(reminder.workerName[0])),
                    title: Text(reminder.workerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(reminder.reminderDate),
                          style: TextStyle(
                            color: isToday
                                ? Colors.green
                                : isPast
                                ? Colors.red
                                : null,
                            fontWeight: isToday ? FontWeight.bold : null,
                          ),
                        ),
                        Text(
                          reminder.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: reminder.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.notifications_active),
                    onTap: () async {
                      // Detay ekrandan silme yapılırsa, pop(true) ile geri dönecek.
                      // Bu durumda listeyi anında yenileyerek UI'ın güncel kalmasını sağlıyoruz.
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => EmployeeReminderDetailScreen(
                            reminderId: reminder.id,
                          ),
                        ),
                      );

                      if (result == true) {
                        _loadReminders();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerSelectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Çalışan Seçin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
