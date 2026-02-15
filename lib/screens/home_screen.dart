import 'package:flutter/material.dart';
import 'employee_screen.dart';
import 'attendance_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart'; // themeModeNotifier ve authStateNotifier için import
import 'payment_screen.dart';
import '../core/session_manager.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/theme_toggle_animation.dart'; // Yeni animasyon widget'ı
import '../core/user_data_notifier.dart'; // userDataNotifier için import
import 'admin_panel_screen.dart';
import 'notification_settings_screen.dart'; // Bildirim ayarları ekranını import ediyoruz
import 'user_accounts_screen.dart'; // Kullanıcı hesapları ekranını import ediyoruz
import 'package:go_router/go_router.dart';

// GoRouter global referansı
final GoRouter _appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, _) => const HomeScreen()),
    GoRoute(
      path: '/admin_accounts',
      builder: (context, _) => const AdminPanelScreen(initialTabIndex: 1),
    ),
  ],
);

final ValueNotifier<int>? globalSelectedIndexNotifier = ValueNotifier<int>(0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  ValueNotifier<int>? _selectedIndexNotifier;
  Timer? _backgroundTimer;
  Timer? _blockCheckTimer;
  static const int backgroundTimeoutMinutes = 5; // 5 dakika

  // AuthService örneği eklendi
  final _authService = AuthService();

  final List<Widget> _screens = [
    const EmployeeScreen(),
    const AttendanceScreen(),
    const PaymentScreen(),
    const ReportScreen(),
    const AdminPanelScreen(),
    const ProfileScreen(),
    const NotificationSettingsScreen(), // Bildirim ayarları ekranını ekliyoruz
    const UserAccountsScreen(), // Kullanıcı hesapları ekranını ekliyoruz
  ];

  // Ekran başlıkları listesi (Drawer sırasıyla aynı olmalı)
  final List<String> _screenTitles = const [
    'Çalışanlar',
    'Yevmiye',
    'Ödeme',
    'Raporlar',
    'Admin Panel',
    'Profil',
    'Bildirim Ayarları', // Bildirim ayarları başlığını ekliyoruz
    'Kullanıcı Hesapları', // Kullanıcı hesapları başlığını ekliyoruz
  ];

  // Kullanıcı bilgileri için state değişkenleri (userDataNotifier dinleneceği için artık gerek yok)
  // String _firstName = '';
  // String _lastName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndexNotifier = globalSelectedIndexNotifier;
    _loadSelectedIndex();
    // _loadUserData(); // Kullanıcı bilgisini artık notifier üzerinden alacağız

    // userDataNotifier dinleyicisini ekle
    userDataNotifier.addListener(_updateDrawerHeader);
    // Uygulama ilk açıldığında kullanıcı verisini AuthService üzerinden yükle (notifier'ı tetikleyecek)
    _authService.currentUser;

    // Kullanıcının blok durumunu kontrol et (başlangıçta ve her 60 saniyede bir)
    _checkUserBlockStatus();
    _blockCheckTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkUserBlockStatus(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _blockCheckTimer?.cancel(); // Blok kontrolü Timer'ını temizle
    // userDataNotifier dinleyicisini kaldır
    userDataNotifier.removeListener(_updateDrawerHeader);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTimer = Timer(
        const Duration(minutes: backgroundTimeoutMinutes),
        _onSessionTimeout,
      );
    } else if (state == AppLifecycleState.resumed) {
      _backgroundTimer?.cancel();

      // Uygulama ön plana geldiğinde kullanıcının blok durumunu kontrol et
      _checkUserBlockStatus();
    }
  }

  void _onSessionTimeout() {
    _signOut();
    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum süresi doldu, tekrar giriş yapınız.'),
          ),
        );
      });
    }
  }

  void _signOut() async {
    // Çıkış yapmadan önce mevcut context'i saklayalım
    final BuildContext localContext = context;

    // Çıkış yap (hesapları kaydet ve kayıtlı hesap olup olmadığını kontrol et)
    final hasSavedAccounts = await AuthService().signOut();

    authStateNotifier.value =
        false; // AuthService signOut metodu userDataNotifier'ı da null yapacak

    if (!mounted) return;

    print('Çıkış yapıldı, kaydedilmiş hesap var mı: $hasSavedAccounts');

    // Kayıtlı hesap varsa ilk hesaba otomatik giriş yap
    if (hasSavedAccounts) {
      print('Kaydedilmiş hesap bulundu, otomatik giriş yapılıyor...');
      final success = await AuthService().autoLoginWithFirstSavedAccount();

      if (!mounted) return;

      print('Otomatik giriş sonucu: $success');

      if (success) {
        // Otomatik giriş başarılı, yeni bir yönlendirme yapılacak
        // Kullanıcı verilerini güncelle
        final userData = await AuthService().currentUser;
        // Admin kontrolü yap
        final isAdmin = await AuthService().isAdmin();

        if (!mounted) return;

        try {
          // Admin hesabına veya normal kullanıcı hesabına yönlendir
          if (isAdmin) {
            print(
              'Admin hesabına giriş yapıldı, admin paneline yönlendiriliyor',
            );
            GoRouter.of(localContext).go('/admin_accounts');
          } else {
            print(
              'Normal kullanıcı hesabına giriş yapıldı, ana sayfaya yönlendiriliyor',
            );
            GoRouter.of(localContext).go('/home');
          }

          // Başarılı mesajı göster
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text(
                '${userData?['first_name']} ${userData?['last_name']} hesabına geçiş yapıldı',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Yönlendirme hatası: $e');
          // Hata durumunda alternatif yönlendirme
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      } else {
        print('Otomatik giriş başarısız oldu, login ekranına yönlendiriliyor');
      }
    } else {
      print('Kaydedilmiş hesap bulunamadı, login ekranına yönlendiriliyor');
    }

    // Kayıtlı hesap yoksa veya otomatik giriş başarısız olduysa login sayfasına yönlendir
    if (!mounted) return;

    try {
      GoRouter.of(localContext).go('/login');
    } catch (e) {
      print('Login yönlendirme hatası: $e');
      // Alternatif yönlendirme
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('selected_tab_index') ?? 0;
    _selectedIndexNotifier?.value = idx;
  }

  Future<void> _saveSelectedIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_tab_index', idx);
  }

  // Kullanıcı verileri yüklendiğinde veya değiştiğinde Drawer başlığını güncelle
  void _updateDrawerHeader() {
    // userDataNotifier değiştiğinde setState çağırarak widget'ı yeniden çiz
    if (mounted) {
      setState(() {});
    }
  }

  // Tema değiştirme fonksiyonu
  void _toggleTheme() async {
    final currentMode = themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // Önce tema değişimini uygula, animasyon sonunda sadece drawer'ı kapat
    void onAnimationComplete() {
      // Drawer'ı kapat
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    // Önce tema değişimini uygula
    themeModeNotifier.value = newMode;
    _saveThemeMode(newMode);

    // Sonra animasyonu göster
    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
    );
  }

  // Tema tercihini kaydet
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString('theme_mode', 'light');
        break;
      case ThemeMode.system:
        await prefs.setString('theme_mode', 'system');
        break;
    }
  }

  // Çıkış yap dialogunu gösterme fonksiyonu (ProfileScreen'den taşındı)
  void _showLogoutDialog() {
    // Şu anki context'i sakla
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Dialog context'ini kullan
              Navigator.pop(dialogContext);
              // Drawer'ı kapatmak için
              if (Navigator.canPop(currentContext)) {
                Navigator.pop(currentContext);
              }

              // Çıkış yap (hesapları kaydet ve kayıtlı hesap olup olmadığını kontrol et)
              final hasSavedAccounts = await _authService.signOut();

              authStateNotifier.value =
                  false; // AuthService signOut metodu userDataNotifier'ı da null yapacak

              // Widget hala bağlı mı kontrol et
              if (!mounted) return;

              print(
                'Çıkış yapıldı, kaydedilmiş hesap var mı: $hasSavedAccounts',
              );

              // Kayıtlı hesap varsa ilk hesaba otomatik giriş yap
              if (hasSavedAccounts) {
                print('Kaydedilmiş hesap bulundu, otomatik giriş yapılıyor...');
                final success = await _authService
                    .autoLoginWithFirstSavedAccount();

                // Widget hala bağlı mı kontrol et
                if (!mounted) return;

                print('Otomatik giriş sonucu: $success');

                if (success) {
                  // Otomatik giriş başarılı, yeni bir yönlendirme yapılacak
                  // Kullanıcı verilerini güncelle
                  final userData = await _authService.currentUser;
                  // Admin kontrolü yap
                  final isAdmin = await _authService.isAdmin();

                  // Widget hala bağlı mı kontrol et
                  if (!mounted) return;

                  try {
                    // Admin hesabına veya normal kullanıcı hesabına yönlendir
                    if (isAdmin) {
                      // GoRouter ile yönlendirme
                      print(
                        'Admin hesabına giriş yapıldı, admin paneline yönlendiriliyor',
                      );
                      GoRouter.of(currentContext).go('/admin_accounts');
                    } else {
                      // GoRouter ile yönlendirme
                      print(
                        'Normal kullanıcı hesabına giriş yapıldı, ana sayfaya yönlendiriliyor',
                      );
                      GoRouter.of(currentContext).go('/home');
                    }

                    // Başarılı mesajı göster
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${userData?['first_name']} ${userData?['last_name']} hesabına geçiş yapıldı',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Yönlendirme hatası: $e');
                    // Hata durumunda GoRouter yönlendirmesi yerine Navigator kullan
                    _appRouter.go('/login');
                  }
                  return;
                } else {
                  print(
                    'Otomatik giriş başarısız oldu, login ekranına yönlendiriliyor',
                  );
                }
              } else {
                print(
                  'Kaydedilmiş hesap bulunamadı, login ekranına yönlendiriliyor',
                );
              }

              // Kayıtlı hesap yoksa veya otomatik giriş başarısız olduysa login sayfasına yönlendir
              try {
                // Router referansını doğrudan Navigator üzerinden al
                GoRouter.of(currentContext).go('/login');
              } catch (e) {
                print('Yönlendirme hatası: $e');
                // Hata durumunda GoRouter üzerinden global router'ı kullan
                _appRouter.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(
                dialogContext,
              ).colorScheme.error, // Hata rengi kullanıldı
              foregroundColor: Theme.of(
                dialogContext,
              ).colorScheme.onError, // Hata rengi üzerine yazı rengi
            ),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 700.0 : double.infinity;
    if (_selectedIndexNotifier == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // userDataNotifier dinleyerek güncel kullanıcı bilgisini al
    final currentUser = userDataNotifier.value;
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';

    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndexNotifier!,
      builder: (context, selectedIndex, _) {
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer, // AppBar ikon rengi tema ile uyumlu
              ),
            ),
            title: Text(
              _screenTitles[selectedIndex],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ), // Başlık rengi tema ile uyumlu
            ),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primaryContainer, // AppBar arka plan rengi
            elevation: 4.0, // Hafif gölge
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
            width:
                MediaQuery.of(context).size.width *
                0.75, // Çekmece genişliği ekranın %75'i olarak ayarlandı
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30), // Yuvarlak köşeler
                bottomRight: Radius.circular(30),
              ),
            ),
            elevation: 16.0, // Daha belirgin gölge
            child: Column(
              children: <Widget>[
                // Güncellenmiş Başlık Alanı (Refined)
                Container(
                  height:
                      200, // Başlık yüksekliği artırıldı (daha fazla boşluk ve büyük yazı için)
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLowest, // Daha açık bir tema rengi denemesi
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0, // Dikey boşluk artırıldı
                  ),
                  child: Row(
                    // Başlık ikon ve yazıyı yan yana al
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Dikeyde hizala
                    children: [
                      // Uygulama simgesi
                      Image.asset(
                        'assets/icons/icon.png', // Uygulama simgesinin yolu
                        width: 60, // İkon boyutunu artırdım
                        height: 60, // İkon boyutunu artırdım
                      ),
                      const SizedBox(
                        width: 20,
                      ), // İkon ile yazı arası boşluk artırıldı
                      Expanded(
                        child: Column(
                          // Yazıları alt alta al
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Merkeze hizala
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puantaj', // İlk kelime
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface, // Tema onSurface rengiyle uyumlu
                                fontSize: 28, // Font boyutu artırıldı
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Takip', // İkinci kelime
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withOpacity(0.8), // Hafif soluk
                                fontSize: 22, // Font boyutu artırıldı
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Kullanıcı adı ve soyadı
                            if (firstName.isNotEmpty ||
                                lastName
                                    .isNotEmpty) // İsim soyisim varsa göster
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '$firstName $lastName', // Ad Soyad
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6), // Daha soluk
                                    fontSize: 16, // Font boyutu artırıldı
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      _buildDrawerItem(
                        icon: Icons.people_alt_outlined, // Alternatif ikon
                        text: 'Çalışanlar',
                        index: 0,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(0),
                      ),
                      _buildDrawerItem(
                        icon: Icons.calendar_month_outlined, // Alternatif ikon
                        text: 'Yevmiye',
                        index: 1,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(1),
                      ),
                      _buildDrawerItem(
                        icon: Icons.payment_outlined,
                        text: 'Ödeme',
                        index: 2,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(2),
                      ),
                      _buildDrawerItem(
                        icon: Icons.bar_chart_outlined,
                        text: 'Raporlar',
                        index: 3,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(3),
                      ),
                      // Admin kullanıcısıysa Admin Paneli öğesini göster
                      if (currentUser?['is_admin'] == true)
                        _buildDrawerItem(
                          icon: Icons
                              .admin_panel_settings_outlined, // Daha uygun bir ikon
                          text: 'Admin Panel',
                          index: 4,
                          selectedIndex: selectedIndex,
                          onTap: () => _onDrawerItemTap(4),
                        ),
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        text: 'Profil',
                        index: 5,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(5),
                      ),
                      _buildDrawerItem(
                        icon: Icons.notifications_outlined,
                        text: 'Bildirim Ayarları',
                        index: 6,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(6),
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_circle_outlined,
                        text: 'Kullanıcı Hesapları',
                        index: 7,
                        selectedIndex: selectedIndex,
                        onTap: () => _onDrawerItemTap(7),
                      ),
                      const Divider(
                        // Ayırıcı çizgi
                        height: 32,
                        thickness: 0.5,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey,
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeModeNotifier,
                        builder: (context, mode, child) {
                          final isDark = mode == ThemeMode.dark;
                          return _buildDrawerItem(
                            icon: isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            text: isDark ? 'Açık Tema' : 'Koyu Tema',
                            index: -1,
                            selectedIndex: selectedIndex,
                            onTap: _toggleTheme,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Çıkış Yap öğesi - Alt kısma sabitlenmiş (Refined)
                const Divider(
                  // Ayırıcı çizgi
                  height: 16,
                  thickness: 0.5,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Material(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(10),
                      hoverColor: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.1),
                      splashColor: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Çıkış Yap',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8.0),
              ],
            ),
          ),
        );
      },
    );
  }

  // Drawer öğeleri için yardımcı fonksiyon (Refined)
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    required int selectedIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 5),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: theme.colorScheme.primary.withOpacity(0.08),
          splashColor: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDrawerItemTap(int index) {
    _selectedIndexNotifier!.value = index;
    _saveSelectedIndex(index);
    Navigator.pop(context);
  }

  // Kullanıcının bloklu olup olmadığını kontrol eder
  Future<void> _checkUserBlockStatus() async {
    try {
      final isBlocked = await _authService.isUserBlocked();
      if (isBlocked && mounted) {
        // Bloklanmış kullanıcıya bildirim göster ve 10 saniye sonra çıkış yap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu hesap yönetici tarafından engellenmiştir. Lütfen iletişime geçin: ferhatcakircali@gmail.com',
            ),
            duration: Duration(seconds: 10),
            backgroundColor: Colors.red,
          ),
        );

        // 10 saniye sonra otomatik çıkış yap
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            _signOut();
          }
        });
      }
    } catch (e) {
      print('Kullanıcı blok durumu kontrolünde hata: $e');
    }
  }
}
