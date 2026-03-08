import 'package:flutter/material.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../services/notification_service.dart';
import '../../services/worker_attendance_service.dart';
import '../repositories/dashboard_attendance_repository.dart';
import '../repositories/dashboard_payment_repository.dart';
import '../repositories/dashboard_notification_repository.dart';
import '../calculators/attendance_rate_calculator.dart';
import '../models/dashboard_data.dart';
import '../../../../core/di/service_locator.dart';

/// Çalışan dashboard iş mantığı kontrolcüsü
///
/// Dashboard verilerini yükler ve koordine eder.
class WorkerDashboardController {
  final LocalStorageService _localStorage;
  final WorkerAttendanceService _attendanceService;
  final NotificationService _notificationService;

  WorkerDashboardController({
    LocalStorageService? localStorage,
    WorkerAttendanceService? attendanceService,
    NotificationService? notificationService,
  }) : _localStorage = localStorage ?? getIt<LocalStorageService>(),
       _attendanceService =
           attendanceService ?? getIt<WorkerAttendanceService>(),
       _notificationService =
           notificationService ?? getIt<NotificationService>();

  final _attendanceRepo = DashboardAttendanceRepository();
  final _paymentRepo = DashboardPaymentRepository();
  final _notificationRepo = DashboardNotificationRepository();

  /// Worker session bilgisini al
  Future<Map<String, String>?> getWorkerSession() async {
    return await _localStorage.getWorkerSession();
  }

  /// Bugün için yevmiye yapılmış mı kontrol et
  Future<bool> hasAttendanceToday(int workerId) async {
    return await _attendanceRepo.hasAttendanceToday(workerId);
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationService.cancelNotification(notificationId);
    } catch (e) {
      debugPrint('Bildirim iptal hatası: $e');
    }
  }

  /// Dashboard verilerini yükler
  ///
  /// Tüm verileri paralel olarak yükler ve DashboardData döndürür.
  Future<DashboardData> loadDashboardData() async {
    final session = await _localStorage.getWorkerSession();
    if (session == null) {
      throw Exception('Oturum bulunamadı');
    }

    final workerId = int.parse(session['workerId']!);
    final userId = int.parse(session['userId']!);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final results = await Future.wait([
      _attendanceService.getMonthlyStatsWithDates(
        workerId: workerId,
        monthStart: monthStart,
        monthEnd: monthEnd,
      ),
      _attendanceService.getTotalPayments(workerId),
      _attendanceRepo.getPendingRequestsCount(workerId),
      _notificationRepo.getUnreadNotificationsCount(workerId),
      _attendanceRepo.getWeeklyDays(workerId),
      _attendanceRepo.getTotalWorkDays(workerId),
      _paymentRepo.getRecentPayments(workerId, userId),
      _paymentRepo.getMonthlyAverage(workerId, userId),
      _attendanceRepo.getMonthlyTrend(workerId),
      _attendanceRepo.getLastAttendance(workerId),
      _attendanceRepo.getLastApproved(workerId),
      _paymentRepo.getLastPayment(workerId, userId),
      _attendanceRepo.getUpcomingReminders(workerId),
    ]);

    return DashboardData(
      workerId: workerId,
      monthlyStats: results[0] as Map<String, dynamic>,
      totalPayments: results[1] as double,
      pendingCount: results[2] as int,
      unreadNotifications: results[3] as int,
      weeklyDays: results[4] as int,
      totalDays: results[5] as int,
      recentPayments: results[6] as List<Map<String, dynamic>>,
      monthlyAverage: results[7] as double,
      monthlyTrend: results[8] as List<Map<String, dynamic>>,
      lastAttendance: results[9] as DateTime?,
      lastApproved: results[10] as DateTime?,
      lastPayment: results[11] as DateTime?,
      reminders: results[12] as List<Map<String, dynamic>>,
    );
  }

  /// Devam oranını hesaplar
  double calculateAttendanceRate(Map<String, dynamic> monthlyStats) {
    return AttendanceRateCalculator.calculate(monthlyStats);
  }
}
