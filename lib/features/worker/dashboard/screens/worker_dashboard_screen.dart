import 'package:flutter/material.dart';
import '../controllers/worker_dashboard_controller.dart';
import '../widgets/worker_month_card.dart';
import '../widgets/worker_total_card.dart';
import '../widgets/pending_requests_card.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/payment_history_card.dart';
import '../widgets/attendance_trend_card.dart';
import '../widgets/recent_activities_card.dart';
import '../widgets/reminders_card.dart';
import '../../home/screens/worker_home_screen.dart';

/// Çalışan anasayfa - Modüler tasarım
class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _controller = WorkerDashboardController();

  bool _isLoading = true;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAndClearAttendanceNotification();
  }

  /// Bugün için yevmiye yapılmışsa bildirimi temizle
  Future<void> _checkAndClearAttendanceNotification() async {
    try {
      final session = await _controller.getWorkerSession();
      if (session == null) return;

      final workerId = int.parse(session['workerId']!);

      // Bugün için yevmiye yapılmış mı kontrol et
      final hasAttendance = await _controller.hasAttendanceToday(workerId);

      if (hasAttendance) {
        debugPrint('Bugün için yevmiye yapılmış, bildirim temizleniyor...');

        // Çalışan hatırlatıcısını iptal et
        final notificationId = 1000 + workerId;
        await _controller.cancelNotification(notificationId);

        debugPrint('Çalışan hatırlatıcısı temizlendi');
      }
    } catch (e) {
      debugPrint('Bildirim temizleme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _controller.loadDashboardData();

      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard yükleme hatası: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _navigateToReminders() {
    // Parent WorkerHomeScreen'den navigasyon fonksiyonunu çağır
    final homeScreenState = context
        .findAncestorStateOfType<WorkerHomeScreenState>();
    if (homeScreenState != null) {
      homeScreenState.navigateToReminders();
    } else {
      debugPrint('WorkerHomeScreenState bulunamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardData == null) {
      return const Center(child: Text('Veri yüklenemedi'));
    }

    final attendanceRate = _controller.calculateAttendanceRate(
      _dashboardData!.monthlyStats,
    );

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, h * 0.1),
        children: [
          // Bekleyen talepler
          PendingRequestsCard(
            pendingCount: _dashboardData!.pendingCount,
            onTap: _navigateToReminders,
          ),
          SizedBox(height: h * 0.02),
          // Hızlı istatistikler
          QuickStatsCard(
            unreadNotifications: _dashboardData!.unreadNotifications,
            weeklyDays: _dashboardData!.weeklyDays,
            totalDays: _dashboardData!.totalDays,
          ),
          SizedBox(height: h * 0.02),
          // Bu ay
          WorkerMonthCard(
            monthlyStats: _dashboardData!.monthlyStats,
            attendanceRate: attendanceRate,
          ),
          SizedBox(height: h * 0.02),
          // Son 3 ay trendi
          if (_dashboardData!.monthlyTrend.isNotEmpty)
            AttendanceTrendCard(monthlyData: _dashboardData!.monthlyTrend),
          if (_dashboardData!.monthlyTrend.isNotEmpty)
            SizedBox(height: h * 0.02),
          // Ödeme geçmişi
          PaymentHistoryCard(
            recentPayments: _dashboardData!.recentPayments,
            monthlyAverage: _dashboardData!.monthlyAverage,
          ),
          SizedBox(height: h * 0.02),
          // Toplam kazanç
          WorkerTotalCard(totalPayments: _dashboardData!.totalPayments),
          SizedBox(height: h * 0.02),
          // Son aktiviteler
          RecentActivitiesCard(
            lastAttendance: _dashboardData!.lastAttendance,
            lastApproved: _dashboardData!.lastApproved,
            lastPayment: _dashboardData!.lastPayment,
          ),
          SizedBox(height: h * 0.02),
          // Yaklaşan hatırlatıcılar
          RemindersCard(reminders: _dashboardData!.reminders),
        ],
      ),
    );
  }
}
