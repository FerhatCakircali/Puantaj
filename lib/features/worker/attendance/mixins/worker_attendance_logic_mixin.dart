import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../services/worker_attendance_service.dart';

/// Worker attendance ekranı iş mantığı
mixin WorkerAttendanceLogicMixin<T extends StatefulWidget>
    on State<T>, TickerProvider {
  final localStorage = LocalStorageService.instance;
  final attendanceService = WorkerAttendanceService();

  late TabController tabController;
  bool isLoading = true;
  bool isInitialized = false;
  int? workerId;

  List<Map<String, dynamic>> attendanceHistory = [];
  List<Map<String, dynamic>> paymentHistory = [];
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  /// Tab controller'ı başlat
  Future<void> initializeTab(int? initialTab) async {
    try {
      int initialTabIndex = initialTab ?? 0;

      final prefs = await SharedPreferences.getInstance();
      final notificationTab = prefs.getInt('worker_attendance_initial_tab');

      if (notificationTab != null) {
        debugPrint(
          '🔔 WorkerAttendanceScreen: Bildirimden gelen tab: $notificationTab',
        );
        initialTabIndex = notificationTab;
        await prefs.remove('worker_attendance_initial_tab');
        debugPrint('✅ WorkerAttendanceScreen: Tab bilgisi temizlendi');
      }

      tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: initialTabIndex,
      );
      tabController.addListener(onTabChanged);

      debugPrint(
        '✅ WorkerAttendanceScreen: Tab controller başlatıldı (index: $initialTabIndex)',
      );

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }

      loadData();
    } catch (e) {
      debugPrint('❌ WorkerAttendanceScreen: Tab başlatma hatası: $e');
      tabController = TabController(length: 2, vsync: this);
      tabController.addListener(onTabChanged);

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
      loadData();
    }
  }

  /// Tab değiştiğinde
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      loadData();
    }
  }

  /// Veri yükle
  Future<void> loadData() async {
    if (!mounted) return;

    if (!isInitialized) {
      debugPrint('⚠️ TabController henüz hazır değil, _loadData atlanıyor');
      return;
    }

    setState(() => isLoading = true);

    try {
      final session = await localStorage.getWorkerSession();
      if (session == null) return;

      workerId = int.parse(session['workerId']!);

      if (tabController.index == 0) {
        final history = await attendanceService.getAttendanceHistory(
          workerId: workerId!,
          startDate: startDate,
          endDate: endDate,
        );

        if (!mounted) return;
        setState(() {
          attendanceHistory = history;
          isLoading = false;
        });
      } else {
        final payments = await attendanceService.getPaymentHistory(
          workerId: workerId!,
          startDate: startDate,
          endDate: endDate,
        );

        debugPrint('✅ Ödeme geçmişi: ${payments.length} kayıt bulundu');
        for (final payment in payments) {
          debugPrint(
            '  - ID: ${payment['id']}, Tarih: ${payment['payment_date']}, Tutar: ₺${payment['amount']}, Notes: ${payment['notes']}',
          );
        }

        if (!mounted) return;
        setState(() {
          paymentHistory = payments;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Geçmiş yükleme hatası: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// Tarih aralığı seç
  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      loadData();
    }
  }

  /// Cleanup
  void cleanupTab() {
    tabController.removeListener(onTabChanged);
    tabController.dispose();
  }
}
