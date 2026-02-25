class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int blockedUsers;
  final int adminUsers;
  final int todayRegistrations;
  final int weeklyRegistrations;
  final int monthlyRegistrations;
  final DateTime lastUpdated;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.blockedUsers,
    required this.adminUsers,
    required this.todayRegistrations,
    required this.weeklyRegistrations,
    required this.monthlyRegistrations,
    required this.lastUpdated,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      blockedUsers: json['blocked_users'] ?? 0,
      adminUsers: json['admin_users'] ?? 0,
      todayRegistrations: json['today_registrations'] ?? 0,
      weeklyRegistrations: json['weekly_registrations'] ?? 0,
      monthlyRegistrations: json['monthly_registrations'] ?? 0,
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'blocked_users': blockedUsers,
      'admin_users': adminUsers,
      'today_registrations': todayRegistrations,
      'weekly_registrations': weeklyRegistrations,
      'monthly_registrations': monthlyRegistrations,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
