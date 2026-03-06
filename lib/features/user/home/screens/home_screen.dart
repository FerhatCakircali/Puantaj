import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../employees/screens/employee_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../reports/screens/report_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../payments/screens/payment_screen.dart';
import '../../../admin/panel/screens/admin_panel_screen.dart';
import '../../notification_settings/screens/notification_settings_screen.dart';
import '../../notifications/screens/user_notifications_screen.dart';
import '../../payment_history/screens/user_payment_history_screen.dart';
import '../../../../core/user_data_notifier.dart';
import '../mixins/index.dart';

final ValueNotifier<int?> globalSelectedIndexNotifier = ValueNotifier<int?>(
  null,
);

// ⚡ PHASE 3: ConsumerStatefulWidget'a geçiş
class HomeScreen extends ConsumerStatefulWidget {
  final int? initialTab;

  const HomeScreen({super.key, this.initialTab});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, HomeLifecycleMixin, HomeLogicMixin {
  ValueNotifier<int?>? _selectedIndexNotifier;

  @override
  ValueNotifier<int?>? get selectedIndexNotifier => _selectedIndexNotifier;

  @override
  int? get initialTab => widget.initialTab;

  // EmployeeScreen için GlobalKey
  final GlobalKey<EmployeeScreenState> _employeeScreenKey =
      GlobalKey<EmployeeScreenState>();

  late final List<Widget> _screens;

  final List<String> _screenTitles = const [
    'Çalışanlar',
    'Yevmiye',
    'Ödeme',
    'Raporlar',
    'Ödeme Geçmişi',
    'Admin Panel',
    'Profil',
    'Hatırlatıcılar',
    'Bildirimler',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndexNotifier = globalSelectedIndexNotifier;
    _screens = [
      EmployeeScreen(key: _employeeScreenKey),
      const AttendanceScreen(),
      const PaymentScreen(),
      const ReportScreen(),
      const UserPaymentHistoryScreen(),
      const AdminPanelScreen(),
      const ProfileScreen(),
      const NotificationSettingsScreen(),
      const UserNotificationsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 700.0 : double.infinity;

    if (_selectedIndexNotifier == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUser = userDataNotifier.value;
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';
    final isAdmin = currentUser?['is_admin'] == true;

    return ValueListenableBuilder<int?>(
      valueListenable: _selectedIndexNotifier!,
      builder: (context, selectedIndex, _) {
        final currentIndex = (selectedIndex ?? 0) % _screenTitles.length;
        final isEmployeeScreen = currentIndex == 0;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // iOS-style Collapsing AppBar
              SliverAppBar(
                expandedHeight: 70,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _screenTitles[currentIndex],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(left: 72, bottom: 12),
                  expandedTitleScale: 1.4,
                  centerTitle: false,
                ),
              ),
              // Content
              SliverFillRemaining(
                hasScrollBody: false,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _screens[currentIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Extended FAB for Employee Screen
          floatingActionButton: isEmployeeScreen
              ? FloatingActionButton.extended(
                  key: ValueKey('fab_${Theme.of(context).brightness}'),
                  onPressed: () {
                    debugPrint('🔴 HomeScreen FAB TIKLANDI!');
                    final employeeScreenState = _employeeScreenKey.currentState;
                    if (employeeScreenState != null) {
                      debugPrint('✅ showAddEmployeeDialog çağrılıyor...');
                      employeeScreenState.showAddEmployeeDialog();
                    } else {
                      debugPrint('❌ EmployeeScreenState bulunamadı!');
                    }
                  },
                  icon: const Icon(Icons.person_add, size: 22),
                  label: const Text('Yeni Çalışan'),
                  elevation: 8,
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          drawer: HomeDrawer(
            firstName: firstName,
            lastName: lastName,
            isAdmin: isAdmin,
            selectedIndex: selectedIndex,
            onItemTap: onDrawerItemTap,
            onThemeToggle: toggleTheme,
            onLogout: showLogoutDialog,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}
