/// Dashboard veri modeli
///
/// Çalışan dashboard'unda gösterilecek tüm verileri içerir.
class DashboardData {
  final int workerId;
  final Map<String, dynamic> monthlyStats;
  final double totalPayments;
  final int pendingCount;
  final int unreadNotifications;
  final int weeklyDays;
  final int totalDays;
  final List<Map<String, dynamic>> recentPayments;
  final double monthlyAverage;
  final List<Map<String, dynamic>> monthlyTrend;
  final DateTime? lastAttendance;
  final DateTime? lastApproved;
  final DateTime? lastPayment;
  final List<Map<String, dynamic>> reminders;

  DashboardData({
    required this.workerId,
    required this.monthlyStats,
    required this.totalPayments,
    required this.pendingCount,
    required this.unreadNotifications,
    required this.weeklyDays,
    required this.totalDays,
    required this.recentPayments,
    required this.monthlyAverage,
    required this.monthlyTrend,
    this.lastAttendance,
    this.lastApproved,
    this.lastPayment,
    required this.reminders,
  });
}
