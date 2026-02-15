import 'dart:io';
import 'package:flutter/material.dart';
import 'package:puantaj/services/notification_service.dart';
import 'package:puantaj/services/employee_reminder_service.dart';
import 'package:puantaj/models/employee_reminder.dart';
import 'package:puantaj/services/worker_service.dart';
import 'package:puantaj/models/worker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:puantaj/services/auth_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final EmployeeReminderService _reminderService = EmployeeReminderService();
  
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = false;
  bool _hasNotificationPermission = false;
  bool _hasBatteryOptimizationDisabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      
      setState(() {
        _hasNotificationPermission = notificationStatus.isGranted;
        _hasBatteryOptimizationDisabled = batteryStatus.isGranted;
      });
    }
  }
  
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
      
      await _checkPermissions();
    }
  }
  
  Future<void> _loadPendingNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pendingNotifications = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = pendingNotifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendImmediateTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test bildirimi gönderildi')),
      );
      await _loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
  
  Future<void> _sendDelayedTestNotification() async {
    try {
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 10));
      
      await _notificationService.scheduleNotification(
        id: 9998,
        title: '10 Saniye Testi',
        body: 'Bu bildirim 10 saniye sonra gösterilmek üzere planlandı',
        scheduledDate: scheduledTime,
        payload: 'test_delayed_notification',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('10 saniye sonrası için bildirim planlandı: ${scheduledTime.toString()}')),
      );
      
      await _loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
  
  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler temizlendi')),
      );
      await _loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
  
  Future<void> _cancelNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirim iptal edildi: ID=$id')),
      );
      await _loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
  
  Future<void> _createNearFutureReminder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Mevcut tarihten 2 dakika sonrasını hesapla
      final now = DateTime.now();
      final reminderDate = now.add(const Duration(minutes: 2));
      
      // Kullanıcı ID'sini al
      final authService = AuthService();
      final userId = await authService.getUserId();
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı oturumu bulunamadı')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Çalışan bilgisini al (test için ilk çalışanı kullan)
      final workerService = WorkerService();
      final workers = await workerService.getWorkers();
      
      if (workers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalışan bulunamadı. Önce çalışan ekleyin.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final worker = workers.first;
      
      // Test hatırlatıcı
      final reminder = EmployeeReminder(
        userId: userId,
        workerId: worker.id!,
        workerName: worker.fullName, // Worker modelinde 'name' değil 'fullName' var
        message: 'Test hatırlatıcısı - ${reminderDate.hour}:${reminderDate.minute}',
        reminderDate: reminderDate,
        isCompleted: false,
      );
      
      // Hatırlatıcıyı ekle
      final result = await _reminderService.addEmployeeReminder(reminder);
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test hatırlatıcısı oluşturuldu! ${reminderDate.hour}:${reminderDate.minute} için')),
        );
        // Zamanlanmış bildirimleri yenile
        _loadPendingNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hatırlatıcı oluşturulamadı!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Test Ekranı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İzin durumu kartı
                  if (Platform.isAndroid)
                    Card(
                      color: _hasNotificationPermission && _hasBatteryOptimizationDisabled
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _hasNotificationPermission && _hasBatteryOptimizationDisabled
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  color: _hasNotificationPermission && _hasBatteryOptimizationDisabled
                                      ? Colors.green.shade900
                                      : Colors.orange.shade900,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hasNotificationPermission && _hasBatteryOptimizationDisabled
                                      ? 'Tüm İzinler Verilmiş'
                                      : 'İzin Sorunu Tespit Edildi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _hasNotificationPermission && _hasBatteryOptimizationDisabled
                                        ? Colors.green.shade900
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _hasNotificationPermission
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _hasNotificationPermission
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Bildirim İzni'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _hasBatteryOptimizationDisabled
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _hasBatteryOptimizationDisabled
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Pil Optimizasyonu Devre Dışı'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!_hasNotificationPermission || !_hasBatteryOptimizationDisabled)
                              ElevatedButton(
                                onPressed: _requestPermissions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('İzinleri Düzelt'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Test butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Anında Bildirim'),
                        onPressed: _sendImmediateTestNotification,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.timer),
                        label: const Text('10 sn Sonra'),
                        onPressed: _sendDelayedTestNotification,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Tüm Bildirimleri Temizle'),
                      onPressed: _clearAllNotifications,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bekleyen bildirimler
                  Text(
                    'Zamanlanmış Bildirimler (${_pendingNotifications.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (_pendingNotifications.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('Zamanlanmış bildirim bulunamadı'),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _pendingNotifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(notification.title ?? 'Başlıksız'),
                            subtitle: Text(notification.body ?? 'İçerik yok'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('ID: ${notification.id}'),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _cancelNotification(notification.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Bilgi kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Sorun Giderme Önerileri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Bildirim sorunları için telefonun "Ayarlar > Uygulamalar > Puantaj" menüsünden tüm izinleri kontrol edin.\n\n'
                            '2. Xiaomi, Huawei, Oppo ve Vivo gibi telefonlarda pil optimizasyonu bildirim sorunlarına yol açabilir. "Pil" ayarlarından "Pil optimizasyonu" veya "Otomatik başlatma" izinlerini verin.\n\n'
                            '3. Telefonunuzu yeniden başlatmayı deneyin.\n\n'
                            '4. Anında bildirimi görebiliyorsanız ancak zamanlanmış bildirimleri alamıyorsanız, üreticinin pil tasarruf modu sorunu olabilir.',
                          ),
                          Divider(height: 24),
                          Text(
                            'Xiaomi/MIUI Telefonlar İçin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. "Ayarlar > Uygulamalar > Uygulama Yönetimi > Puantaj > Pil" menüsüne gidin.\n\n'
                            '2. "Pil tasarrufu kısıtlamalarını kaldır" seçeneğini etkinleştirin.\n\n'
                            '3. "Otomatik başlatma" seçeneğini etkinleştirin.\n\n'
                            '4. "Ayarlar > Uygulamalar > Uygulama İzinleri > Otomatik Başlatma" menüsünden Puantaj uygulamasını etkinleştirin.\n\n'
                            '5. "Ayarlar > Uygulamalar > Uygulama İzinleri > Diğer İzinler > Arka Planda Çalışabilir" seçeneğini etkinleştirin.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.timer),
                    label: const Text('2 Dakika Sonra Test Hatırlatıcısı Oluştur'),
                    onPressed: () => _createNearFutureReminder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
    );
  }
} 