import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../widgets/theme_toggle_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // ImageFilter için
import 'user_accounts_screen.dart'; // Kullanıcı hesapları ekranını ekle
import 'package:go_router/go_router.dart';

class AdminPanelScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminPanelScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _authService = AuthService();
  late int _selectedIndex;
  final GlobalKey _themeIconKey = GlobalKey(); // Tema ikonu için key

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

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

  void _toggleThemeWithAnimation() async {
    final currentMode = themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // Animasyon tamamlandığında yapılacak işlemler (gerekirse eklenebilir)
    void onAnimationComplete() {
      // Burada ek işlemler yapılabilir
    }

    // İkon pozisyonunu hesapla
    final RenderBox? renderBox =
        _themeIconKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? iconCenter;
    if (renderBox != null) {
      final iconPosition = renderBox.localToGlobal(Offset.zero);
      final iconSize = renderBox.size;
      iconCenter =
          iconPosition + Offset(iconSize.width / 2, iconSize.height / 2);
    }

    // Önce tema değişimini uygula
    themeModeNotifier.value = newMode;
    _saveThemeMode(newMode);

    // Sonra animasyonu göster
    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
      center: iconCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: child.key == const ValueKey('dark')
                      ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                      : Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: IconButton(
                  key: _themeIconKey,
                  tooltip: isDark ? 'Açık moda geç' : 'Koyu moda geç',
                  icon: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: _toggleThemeWithAnimation,
                ),
              ),
            );
          },
        ),
        title: Text(
          _selectedIndex == 0
              ? 'Kullanıcılar'
              : _selectedIndex == 1
              ? 'Kullanıcı Hesapları'
              : 'Profil',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Çıkış yapmadan önce mevcut context'i saklayalım
              final BuildContext localContext = context;

              // Çıkış yap (hesapları kaydet ve kayıtlı hesap olup olmadığını kontrol et)
              final hasSavedAccounts = await _authService.signOut();

              if (!mounted) return;

              // AuthStateNotifier'ı güncelle
              authStateNotifier.value = false;

              print(
                'Çıkış yapıldı, kaydedilmiş hesap var mı: $hasSavedAccounts',
              );

              // Kayıtlı hesap varsa ilk hesaba otomatik giriş yap
              if (hasSavedAccounts) {
                print('Kaydedilmiş hesap bulundu, otomatik giriş yapılıyor...');
                final success = await _authService
                    .autoLoginWithFirstSavedAccount();

                if (!mounted) return;

                print('Otomatik giriş sonucu: $success');

                if (success) {
                  // Otomatik giriş başarılı, yeni bir yönlendirme yapılacak
                  // Kullanıcı verilerini güncelle
                  final userData = await _authService.currentUser;
                  // Admin kontrolü yap
                  final isAdmin = await _authService.isAdmin();

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
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdminPanelScreen(initialTabIndex: 1),
                      ),
                      (route) => false,
                    );
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
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [UsersPage(), UserAccountsScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Kullanıcılar',
          ),
          NavigationDestination(
            icon: Icon(Icons.switch_account_outlined),
            selectedIcon: Icon(Icons.switch_account),
            label: 'Hesaplar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentFilter =
      'all'; // 'all', 'admin', 'blocked', 'unblocked' olabilir

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final users = await _authService.getAllUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _filterUsers(); // Kullanıcılar yüklendiğinde filtreleme ve sıralama uygula
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcılar yüklenirken bir hata oluştu'),
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;

      // İlk olarak filtreye göre kullanıcıları seç
      List<Map<String, dynamic>> filteredByStatus = _users.where((user) {
        final bool isBlocked = user['is_blocked'] as bool? ?? false;
        final bool isAdmin = user['is_admin'] == 1;

        switch (_currentFilter) {
          case 'all':
            return true; // Tümünü göster
          case 'admin':
            return isAdmin; // Sadece adminleri göster
          case 'blocked':
            return isBlocked &&
                !isAdmin; // Sadece bloklu normal kullanıcıları göster
          case 'unblocked':
            return !isBlocked &&
                !isAdmin; // Sadece bloksuz normal kullanıcıları göster
          default:
            return true; // Bilinmeyen filtre durumunda tümünü göster
        }
      }).toList();

      // Sonra arama sorgusuna göre filtrele (seçili durumdaki kullanıcılar üzerinde)
      List<Map<String, dynamic>> filteredBySearch = filteredByStatus.where((
        user,
      ) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        final firstName = user['first_name']?.toString().toLowerCase() ?? '';
        final lastName = user['last_name']?.toString().toLowerCase() ?? '';
        final jobTitle = user['job_title']?.toString().toLowerCase() ?? '';

        return username.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query) ||
            jobTitle.contains(query);
      }).toList();

      // Sıralama Mantığı:
      // 1. Ana Admin (username: 'admin')
      // 2. Diğer Admin hesapları (kendi aralarında ad+soyad'a göre)
      // 3. Bloklu normal kullanıcılar (kendi aralarında ad+soyad'a göre)
      // 4. Bloksuz normal kullanıcılar (kendi aralarında ad+soyad'a göre)
      filteredBySearch.sort((a, b) {
        final aIsAdmin = a['is_admin'] == 1;
        final bIsAdmin = b['is_admin'] == 1;
        final aIsMainAdmin = a['username']?.toString().toLowerCase() == 'admin';
        final bIsMainAdmin = b['username']?.toString().toLowerCase() == 'admin';
        final aIsBlocked =
            a['is_blocked'] as bool? ?? false; // null olabilir, false varsay
        final bIsBlocked =
            b['is_blocked'] as bool? ?? false; // null olabilir, false varsay

        // 1. Ana Admin önceliği
        if (aIsMainAdmin && !bIsMainAdmin)
          return -1; // a ana admin, b değilse a önde
        if (!aIsMainAdmin && bIsMainAdmin)
          return 1; // b ana admin, a değilse b önde

        // Admin önceliği (ana admin dışındaki diğer adminler)
        if (aIsAdmin && !bIsAdmin)
          return -1; // a admin (ana admin değilse), b değilse a önde
        if (!aIsAdmin && bIsAdmin)
          return 1; // b admin (ana admin değilse), a değilse b önde

        // Blok durumuna bak (sadece normal kullanıcılar için)
        if (!aIsAdmin && !bIsAdmin) {
          if (aIsBlocked && !bIsBlocked)
            return -1; // a bloklu, b bloksuzsa a önde
          if (!aIsBlocked && bIsBlocked)
            return 1; // b bloklu, a bloksuzsa b önde
        }

        // Aynı gruba aitlerse ad+soyad'a göre sırala
        final aFullName = '${a['first_name']} ${a['last_name']}'.toLowerCase();
        final bFullName = '${b['first_name']} ${b['last_name']}'.toLowerCase();
        return aFullName.compareTo(bFullName);
      });

      _filteredUsers = filteredBySearch; // Arama sonrası listeyi kullan
    });
  }

  Future<void> _deleteUser(int userId) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: const Text(
          'Bu kullanıcıyı silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await _authService.deleteUser(userId);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } else {
      if (!mounted) return;
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı başarıyla silindi')),
        );
      }
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final usernameController = TextEditingController(text: user['username']);
    final firstNameController = TextEditingController(text: user['first_name']);
    final lastNameController = TextEditingController(text: user['last_name']);
    final jobTitleController = TextEditingController(text: user['job_title']);
    bool isAdmin = user['is_admin'] == 1;
    bool isBlocked = user['is_blocked'] as bool;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jobTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Yapılan İş',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Admin Yetkisi'),
                  value: isAdmin,
                  onChanged: (value) {
                    setState(() {
                      isAdmin = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Kullanıcı Bloklu'),
                  value: isBlocked,
                  onChanged: (value) {
                    setState(() {
                      isBlocked = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;

                final updateError = await _authService.updateUser(
                  userId: user['id'] as int,
                  username: usernameController.text.trim(),
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  jobTitle: jobTitleController.text.trim(),
                  isAdmin: isAdmin,
                );

                if (!mounted) return;

                if (updateError != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(updateError)));
                  return;
                }

                final blockError = await _authService.updateUserBlockedStatus(
                  user['id'] as int,
                  isBlocked,
                );

                if (!mounted) return;

                if (blockError != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(blockError)));
                  return;
                }

                if (!mounted) return;
                await _loadUsers();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kullanıcı başarıyla güncellendi'),
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUsers,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Kullanıcı Ara',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ), // Arama kutusu ile Dropdown arasına boşluk
                      DropdownButton<String>(
                        value: _currentFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tümü')),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'blocked',
                            child: Text('Bloklu'),
                          ),
                          DropdownMenuItem(
                            value: 'unblocked',
                            child: Text('Bloksuz'),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _currentFilter = newValue;
                              _filterUsers(); // Filtre değişince listeyi yeniden filtrele ve sırala
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isAdmin = user['is_admin'] == 1;
                      final isMainAdmin =
                          user['username']?.toString().toLowerCase() == 'admin';
                      final isBlocked = user['is_blocked'] as bool? ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              isMainAdmin
                                  ? Icons
                                        .verified_user // Ana admin için farklı ikon
                                  : isAdmin
                                  ? Icons
                                        .admin_panel_settings // Diğer adminler için admin ikonu
                                  : Icons
                                        .person, // Normal kullanıcı için kişi ikonu
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            '${user['first_name']} ${user['last_name']}' +
                                (isMainAdmin
                                    ? ' (System Administrator)'
                                    : isAdmin
                                    ? ' (Admin)'
                                    : ''), // Admin durumunu belirt
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kullanıcı Adı: ${user['username']}'),
                              Text('Yapılan İş: ${user['job_title']}'),
                              Text(
                                'Durum: ${isBlocked ? 'Bloklu' : 'Aktif'}',
                              ), // Blok durumunu göster
                            ],
                          ),
                          trailing: isMainAdmin
                              ? const Icon(
                                  Icons.verified_user,
                                  color: Colors.green,
                                ) // Ana admin için farklı trailing ikon
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showEditUserDialog(user),
                                      tooltip: 'Düzenle',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteUser(user['id'] as int),
                                      tooltip: 'Sil',
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
