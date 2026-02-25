import 'package:flutter/material.dart';
import '../../../../services/notification/notification_helpers.dart';
import '../mixins/index.dart';
import '../widgets/index.dart';
import '../../attendance/screens/worker_attendance_screen.dart';
import '../../dashboard/screens/worker_dashboard_screen.dart';
import '../../notifications/screens/worker_notifications_screen.dart';
import '../../profile/screens/worker_profile_screen.dart';
import '../../reminders/screens/worker_reminders_screen.dart';

/// Çalışan ana ekranı - Modern tasarım
class WorkerHomeScreen extends StatefulWidget {
  final int? initialTab;

  const WorkerHomeScreen({super.key, this.initialTab});

  @override
  State<WorkerHomeScreen> createState() => WorkerHomeScreenState();
}

class WorkerHomeScreenState extends State<WorkerHomeScreen>
    with
        SingleTickerProviderStateMixin,
        WorkerHomeLifecycleMixin,
        WorkerHomeLogicMixin {
  final GlobalKey _themeIconKey = GlobalKey();

  final List<Widget> _screens = [
    const WorkerDashboardScreen(),
    const WorkerAttendanceScreen(),
    const WorkerNotificationsScreen(),
    const WorkerRemindersScreen(),
    const WorkerProfileScreen(),
  ];

  final List<String> _screenTitles = const [
    'Anasayfa',
    'Geçmiş',
    'Bildirimler',
    'Hatırlatıcılar',
    'Profil',
  ];

  /// Dashboard'dan hatırlatıcılar sayfasına yönlendirme
  void navigateToReminders() {
    setState(() => selectedIndex = 3);
    saveSelectedIndex(3);
  }

  @override
  void initState() {
    super.initState();
    loadSelectedIndex(widget.initialTab, _screens.length);
    initializeLifecycle(
      context,
      () => handlePendingNotification(context, (index) {
        setState(() => selectedIndex = index);
        saveSelectedIndex(index);
      }),
    );

    // Bildirim tıklama stream'ini dinle
    notificationClickSubscription = notificationClickStream.stream.listen((
      payload,
    ) {
      debugPrint(
        '🔔 WorkerHomeScreen: Bildirim tıklama eventi alındı: $payload',
      );
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            handlePendingNotification(context, (index) {
              setState(() => selectedIndex = index);
              saveSelectedIndex(index);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    cleanupLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 700.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _screenTitles[selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _screens[selectedIndex],
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            WorkerHomeScreenDrawerHeader(
              workerName: workerName,
              workerUsername: workerUsername,
            ),
            WorkerHomeScreenDrawerContent(
              selectedIndex: selectedIndex,
              onItemTap: (index) =>
                  onItemTapped(context, index, _screens.length),
              onThemeToggle: () =>
                  toggleThemeWithAnimation(context, _themeIconKey),
              onLogout: () => handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
