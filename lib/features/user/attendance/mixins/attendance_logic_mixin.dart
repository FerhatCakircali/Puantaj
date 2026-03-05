import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../../../../services/attendance_service.dart';
import '../../../../services/employee_service.dart';
import '../../../../services/payment_service.dart';
import '../widgets/attendance_helpers.dart';
import '../widgets/attendance_notification_handler.dart';

/// Yevmiye ekranı business logic mixin'i
mixin AttendanceLogicMixin<T extends StatefulWidget> on State<T> {
  DateTime selectedDate = DateTime.now();
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  Map<int, attendance.Attendance> attendanceMap = {};
  final Map<int, attendance.AttendanceStatus> pendingChanges = {};
  bool isLoading = true;
  final PaymentService paymentService = PaymentService();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    AttendanceNotificationHandler.checkAndClearAttendanceNotification();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    debugPrint('🔄 [Attendance] loadData başladı');
    setState(() => isLoading = true);
    try {
      // Tüm çalışanları al
      final allEmployees = await EmployeeService().getEmployees();

      // Seçili tarihe ait devam kayıtlarını al
      final allAttendance = await AttendanceService().getAttendanceByDate(
        selectedDate,
      );

      debugPrint(
        '📥 [Attendance] Veritabanından ${allAttendance.length} kayıt geldi',
      );
      for (var record in allAttendance) {
        debugPrint('  • Worker ${record.workerId}: ${record.status}');
      }

      // Çalışanları isme göre A'dan Z'ye sırala
      allEmployees.sort(
        (a, b) => AttendanceHelpers.collateTurkish(a.name, b.name),
      );

      // Sadece seçili tarihte veya daha önce işe başlamış olanları filtrele
      final filteredEmps = allEmployees
          .where((e) => !e.startDate.isAfter(selectedDate))
          .toList();

      if (mounted) {
        setState(() {
          employees = filteredEmps;
          filteredEmployees = filteredEmps;
          attendanceMap = {
            for (var record in allAttendance) record.workerId: record,
          };
          pendingChanges.clear();
          isLoading = false;
        });
      }

      debugPrint('✅ [Attendance] State güncellendi');
      debugPrint('Tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}');
      debugPrint('Toplam çalışan sayısı: ${allEmployees.length}');
      debugPrint(
        'İşe başlama tarihine göre filtrelenmiş çalışan sayısı: ${filteredEmps.length}',
      );
      debugPrint('Devam kaydı sayısı: ${allAttendance.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ [Attendance] Çalışan verileri yüklenirken hata oluştu: $e');
      debugPrint('Hata ayrıntıları: $stackTrace');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees
            .where(
              (employee) =>
                  employee.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        isLoading = true;
        pendingChanges.clear();
        searchController.clear();
      });
      await loadData();
    }
  }

  void onDateSelected(DateTime day) {
    debugPrint(
      '📅 [Attendance] Tarih seçildi: ${DateFormat('dd/MM/yyyy').format(day)}',
    );
    debugPrint(
      '📅 [Attendance] Mevcut tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
    );

    setState(() {
      selectedDate = day;
      isLoading = true;
      pendingChanges.clear();
      searchController.clear();
    });
    loadData();
  }

  Future<void> saveChanges() async {
    debugPrint('💾 [Attendance] saveChanges başladı');
    debugPrint('💾 [Attendance] Pending changes: $pendingChanges');

    // Seçilmemiş çalışanları bul (hiç kayıt yok ve pending change de yok)
    final unselectedEmployees = filteredEmployees.where((employee) {
      final hasPendingChange = pendingChanges.containsKey(employee.id);
      final hasAttendanceRecord = attendanceMap.containsKey(employee.id);
      return !hasPendingChange && !hasAttendanceRecord;
    }).toList();

    // Eğer seçilmemiş çalışan varsa, onay dialogu göster
    if (unselectedEmployees.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Dikkat'),
          content: Text(
            '${unselectedEmployees.length} çalışan için durum seçilmedi.\n\n'
            'Bu çalışanlar otomatik olarak "Gelmedi" olarak kaydedilecek.\n\n'
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        debugPrint('⚠️ [Attendance] Kullanıcı işlemi iptal etti');
        return;
      }

      // Seçilmemiş çalışanları "gelmedi" olarak pending changes'e ekle
      for (final employee in unselectedEmployees) {
        pendingChanges[employee.id] = attendance.AttendanceStatus.absent;
      }
      debugPrint(
        '✅ [Attendance] ${unselectedEmployees.length} çalışan "gelmedi" olarak eklendi',
      );
    }

    if (pendingChanges.isEmpty) {
      debugPrint('⚠️ [Attendance] Kaydedilecek değişiklik yok');
      return;
    }

    setState(() => isLoading = true);
    try {
      for (final entry in pendingChanges.entries) {
        debugPrint(
          '💾 [Attendance] Kaydediliyor: Worker ${entry.key} -> ${entry.value}',
        );
        await AttendanceService().markAttendance(
          workerId: entry.key,
          date: selectedDate,
          status: entry.value,
        );
        debugPrint('✅ [Attendance] Kaydedildi: Worker ${entry.key}');
      }

      // Bugün için yevmiye girişi yapıldığını işaretle
      final today = DateTime.now();
      final selectedToday = DateTime(today.year, today.month, today.day);
      final selectedDateNorm = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // Eğer bugünün yevmiye kaydı yapılıyorsa, bildirim durumunu güncelle
      if (selectedDateNorm.isAtSameMomentAs(selectedToday)) {
        debugPrint('📅 [Attendance] Bugünün yevmiye kaydı yapıldı');
        await AttendanceNotificationHandler.markTodayAttendanceDone();
        debugPrint('✅ [Attendance] Bildirim durumu güncellendi');
      }

      // Çalışanlara bildirim gönder (her zaman, hangi tarih olursa olsun)
      debugPrint('📢📢📢 [Attendance] Çalışanlara bildirim gönderiliyor...');
      debugPrint('📢 pendingChanges sayısı: ${pendingChanges.length}');
      debugPrint('📢 pendingChanges içeriği: $pendingChanges');

      try {
        await _sendAttendanceNotificationsToWorkers();
        debugPrint('✅✅✅ [Attendance] Bildirim gönderme tamamlandı');
      } catch (e, stackTrace) {
        debugPrint('❌❌❌ [Attendance] Bildirim gönderme HATASI: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      debugPrint('🔄 [Attendance] Veriler yeniden yükleniyor...');
      await loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unselectedEmployees.isEmpty
                  ? 'Yevmiye kayıtları başarıyla kaydedildi'
                  : 'Yevmiye kayıtları başarıyla kaydedildi (${unselectedEmployees.length} çalışan "gelmedi" olarak işaretlendi)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Attendance] Yevmiye kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yevmiye kaydetme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Çalışanlara yevmiye girişi yapıldı bildirimi gönder
  Future<void> _sendAttendanceNotificationsToWorkers() async {
    try {
      debugPrint('🔔🔔🔔 _sendAttendanceNotificationsToWorkers BAŞLADI');

      final now = DateTime.now();
      // Yevmiye girişi yapılan tarihi kullan (selectedDate)
      final formattedDate = DateFormat(
        'dd.MM.yyyy',
        'tr_TR',
      ).format(selectedDate);
      final formattedTime = DateFormat('HH:mm', 'tr_TR').format(now);

      debugPrint('📅 Tarih: $formattedDate, Saat: $formattedTime');
      debugPrint(
        '👥 Bildirim gönderilecek çalışan sayısı: ${pendingChanges.length}',
      );

      for (final entry in pendingChanges.entries) {
        final workerId = entry.key;
        final newStatus = entry.value;
        final employee = employees.firstWhere((e) => e.id == workerId);

        // Önceki durumu kontrol et
        final oldAttendance = attendanceMap[workerId];
        final isUpdate = oldAttendance != null;
        final oldStatus = oldAttendance?.status;

        debugPrint('');
        debugPrint(
          '📢📢📢 Bildirim gönderiliyor: ${employee.name} (ID: $workerId)',
        );
        debugPrint(
          '  Güncelleme: $isUpdate, Eski: $oldStatus, Yeni: $newStatus',
        );

        // Eğer durum değişmemişse bildirim gönderme
        if (isUpdate && oldStatus == newStatus) {
          debugPrint('  ⏭️ Durum değişmedi, bildirim gönderilmiyor');
          continue;
        }

        try {
          // Veritabanına bildirim kaydı ekle
          await AttendanceNotificationHandler.sendAttendanceEntryNotification(
            workerId: workerId,
            workerName: employee.name,
            date: formattedDate,
            time: formattedTime,
            isUpdate: isUpdate,
            oldStatus: oldStatus,
            newStatus: newStatus,
          );

          debugPrint('✅✅✅ Bildirim gönderildi: ${employee.name}');
        } catch (e, stackTrace) {
          debugPrint('❌❌❌ ${employee.name} için bildirim HATASI: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      debugPrint('');
      debugPrint('✅ [Attendance] Tüm bildirimler gönderildi');
    } catch (e, stackTrace) {
      debugPrint('❌ [Attendance] Bildirim gönderme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Yevmiye yapmamış çalışanlara hatırlatma gönder  /// Yevmiye yapmamış çalışanlara hatırlatma gönder
  Future<void> sendReminders() async {
    // Sadece bugün için hatırlatma gönderilmesine izin ver
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (!selectedDateNorm.isAtSameMomentAs(todayDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hatırlatma sadece bugün için gönderilebilir'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Bugün yevmiye girişi yapılmamış çalışanları bul
    final workersWithoutAttendance = employees.where((employee) {
      final hasPendingChange = pendingChanges.containsKey(employee.id);
      final hasAttendanceRecord = attendanceMap.containsKey(employee.id);
      return !hasPendingChange && !hasAttendanceRecord;
    }).toList();

    if (workersWithoutAttendance.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm çalışanlar yevmiye girişi yapmış'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatma Gönder'),
        content: Text(
          '${workersWithoutAttendance.length} çalışana yevmiye hatırlatması göndermek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    // Kullanıcı iptal ettiyse çık
    if (confirmed != true) return;

    // Hatırlatma gönder
    try {
      await AttendanceNotificationHandler.sendRemindersToWorkers(
        context,
        workersWithoutAttendance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${workersWithoutAttendance.length} çalışana hatırlatma gönderildi',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Hatırlatma gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hatırlatma gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> changeStatus(
    int workerId,
    attendance.AttendanceStatus value,
  ) async {
    // Çalışanı bul
    final employee = employees.firstWhere((e) => e.id == workerId);

    // İşe başlama tarihinden önceki tarihlerde değişiklik yapılmasını engelle
    if (selectedDate.isBefore(employee.startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name} işe başlama tarihinden (${DateFormat('dd/MM/yyyy').format(employee.startDate)}) önceki tarihlerde yevmiye girişi yapılamaz.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mevcut durumu al (null olabilir - hiç kayıt yoksa)
    final currentStatus =
        pendingChanges[workerId] ?? attendanceMap[workerId]?.status;

    // Eğer durum değişiyorsa ve mevcut durum ödenmişse, uyarı göster
    if (currentStatus != null && currentStatus != value) {
      final isPaid = await paymentService.isDayPaid(
        workerId,
        selectedDate,
        currentStatus,
      );

      if (isPaid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu gün için ödeme yapılmış, durum değiştirilemez!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Durum değişikliğini kaydet
    setState(() {
      pendingChanges[workerId] = value;
    });

    // Bugünün yevmiyesinin değiştiğini kontrol et
    final today = DateTime.now();
    final selectedToday = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Eğer bugünün yevmiye kaydı yapılıyorsa, hemen bildirim durumunu güncelle
    if (selectedDateNorm.isAtSameMomentAs(selectedToday)) {
      debugPrint(
        'Bugünün yevmiye durumu değiştirildi, bildirim durumunu hemen güncelliyorum',
      );

      try {
        await AttendanceNotificationHandler.markTodayAttendanceDone();
        debugPrint(
          'Bildirim durumu başarıyla güncellendi (çalışan durumu değiştirme)',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bugünün yevmiye girişi yapıldı olarak işaretlendi',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Bildirim durumu güncellenirken hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bildirim durumu güncellenirken hata: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Tüm çalışanların durumunu toplu olarak değiştir
  Future<void> bulkChangeStatus(attendance.AttendanceStatus status) async {
    // Ödeme yapılmış günleri kontrol et
    final List<String> paidEmployees = [];
    final List<String> notStartedEmployees = [];

    for (final employee in filteredEmployees) {
      // İşe başlama tarihinden önceki tarihlerde değişiklik yapılmasını engelle
      if (selectedDate.isBefore(employee.startDate)) {
        notStartedEmployees.add(employee.name);
        continue;
      }

      // Mevcut durumu al
      final currentStatus =
          pendingChanges[employee.id] ?? attendanceMap[employee.id]?.status;

      // Eğer durum değişiyorsa ve mevcut durum ödenmişse, listeye ekle
      if (currentStatus != null && currentStatus != status) {
        final isPaid = await paymentService.isDayPaid(
          employee.id,
          selectedDate,
          currentStatus,
        );

        if (isPaid) {
          paidEmployees.add(employee.name);
          continue; // Bu çalışanı atla
        }
      }

      // Durum değişikliğini kaydet
      pendingChanges[employee.id] = status;
    }

    setState(() {});

    if (mounted) {
      final statusText = status == attendance.AttendanceStatus.fullDay
          ? 'Tam Gün'
          : status == attendance.AttendanceStatus.halfDay
          ? 'Yarım Gün'
          : 'Gelmedi';

      // Ödeme yapılmış çalışanlar varsa uyarı göster
      if (paidEmployees.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ ${paidEmployees.length} çalışan için ödeme yapılmış, değiştirilemedi:\n${paidEmployees.take(3).join(", ")}${paidEmployees.length > 3 ? "..." : ""}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // İşe başlamamış çalışanlar varsa bilgi göster
      if (notStartedEmployees.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ℹ️ ${notStartedEmployees.length} çalışan henüz işe başlamamış:\n${notStartedEmployees.take(3).join(", ")}${notStartedEmployees.length > 3 ? "..." : ""}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Başarılı değişiklik varsa bilgi göster
      final changedCount =
          filteredEmployees.length -
          paidEmployees.length -
          notStartedEmployees.length;
      if (changedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $changedCount çalışan "$statusText" olarak işaretlendi',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
