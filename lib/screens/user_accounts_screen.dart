import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/user_data_notifier.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Global navigatorKey tanımlama
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global değişken: bildirim mesajı gösterecek yardımcı fonksiyon
// Bu sayede widget unmount edilmiş olsa bile güvenli bildirim gösterebileceğiz
void showGlobalSnackbar(String message, {Color backgroundColor = Colors.blue}) {
  BuildContext? context = navigatorKey.currentContext;
  // Context yoksa ana uygulama scaffold mesajını kullan
  if (context == null) {
    context = appScaffoldMessengerKey.currentContext;
  }
  
  if (context == null) return;
  
  // Burada herhangi bir şekilde context'in valid olduğunu garantileyemiyoruz
  // Güvenli bir şekilde kullanabilmek için try-catch bloğuyla sarmalıyoruz
  try {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  } catch (e) {
    print('Bildirim gösterme hatası: $e');
  }
}

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({super.key});

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isProcessing = false; // İşlem yapılıyor mu takip eder
  List<Map<String, dynamic>> _savedAccounts = [];
  Map<String, dynamic>? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
    _loadCurrentUser();
    
    // Hesap listesi güncelleme bildirimini dinle
    accountsUpdateNotifier.addListener(_refreshAccountsList);
  }
  
  @override
  void dispose() {
    // Listener'ı temizle
    accountsUpdateNotifier.removeListener(_refreshAccountsList);
    super.dispose();
  }
  
  // Hesap listesini yenileme fonksiyonu
  void _refreshAccountsList() {
    print('Hesap listesi yenileme bildirimi alındı');
    if (mounted) {
      _loadSavedAccounts();
      _loadCurrentUser();
    }
  }

  // Bildirim gösterme yardımcı metodu
  void _showSnackbar(String message, {Color backgroundColor = Colors.blue}) {
    if (!mounted) return;
    
    // Global fonksiyonu çağır
    showGlobalSnackbar(message, backgroundColor: backgroundColor);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = userDataNotifier.value;
      setState(() {
        _currentUser = userData;
      });
      
      print('Mevcut kullanıcı bilgileri güncellendi: ${userData != null ? userData['username'] : 'null'}');
    } catch (e) {
      print('Mevcut kullanıcı bilgisi alınırken hata: $e');
    }
  }

  Future<void> _loadSavedAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];
      
      List<Map<String, dynamic>> accounts = [];
      for (String accountJson in savedAccountsJson) {
        try {
          // Kaydedilmiş hesap bilgilerini yükle
          final Map<String, dynamic> accountData = 
              jsonDecode(accountJson) as Map<String, dynamic>;
          
          // Eğer geçerli bir hesap verisi ise listeye ekle
          if (accountData.containsKey('user_id') && 
              accountData.containsKey('username') &&
              accountData.containsKey('first_name') &&
              accountData.containsKey('last_name')) {
            accounts.add(accountData);
          }
        } catch (e) {
          print('Hesap verisi ayrıştırılırken hata: $e');
        }
      }
      
      setState(() {
        _savedAccounts = accounts;
        _isLoading = false;
      });
      
      print('Kaydedilmiş hesap listesi güncellendi, toplam ${accounts.length} hesap bulundu');
    } catch (e) {
      print('Kaydedilmiş hesaplar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchAccount(Map<String, dynamic> account) async {
    // Eğer zaten bir işlem yapılıyorsa, yeni işlemi engelle
    if (_isProcessing) return;
    
    setState(() {
      _isLoading = true;
      _isProcessing = true; // İşlem başlıyor
    });

    try {
      // Kullanıcıya bilgi mesajı göster
      _showSnackbar(
        '${account['first_name']} ${account['last_name']} hesabına geçiş yapılıyor...',
        backgroundColor: Colors.blue,
      );
      
      // Seçilen hesapla doğrudan giriş yap (çıkış yapmadan)
      final userId = account['user_id'] as int;
      final username = account['username'] as String;
      
      // Context'i hesap değiştirme işlemi başlamadan önce saklayalım
      final localContext = context;
      
      // Admin kontrolü yap - önce hesaba geçiş yapmadan admin olup olmadığını kontrol edelim
      final isTargetAdmin = await _checkIfUserIsAdmin(userId);
      print('Hedef hesap admin mi: $isTargetAdmin');
      
      // Mevcut kullanıcının admin olup olmadığını kontrol et
      final isCurrentAdmin = await _authService.isAdmin();
      print('Mevcut kullanıcı admin mi: $isCurrentAdmin');
      
      // Aynı tür hesap arası geçiş mi yoksa farklı tür arası mı?
      final isSameAccountType = isCurrentAdmin == isTargetAdmin;
      print('Aynı tür hesaplar arası geçiş mi: $isSameAccountType');
      
      // Hesap değiştirme işlemi başarılı olacak, o yüzden mevcut sayfayı kaydet
      // İşlem bitince bu sayfaya geri dönebilmek için
      String returnPath = '/user_accounts';
      
      // Hesap değiştirme modunu aktifleştir - Login ekranına yönlendirmeyi engeller
      isSwitchingAccounts = true;
      
      // Yeni eklediğimiz metodu kullan
      final result = await _authService.switchToSavedAccount(
        userId: userId,
        username: username,
      );
      
      // İşlem ve yükleme durumunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false; // İşlem bitti
        });
      }
      
      if (result) {
        // Bildirim mesajını hazırlayalım
        final successMessage = '${account['first_name']} ${account['last_name']} hesabına geçiş yapıldı';
        
        // İşlem başarılıysa, hesapları yeniden yükle ve kullanıcı türüne göre doğru sayfaya yönlendir
        if (mounted) {
          // Hesap listesini yenile
          await _loadSavedAccounts();
          await _loadCurrentUser();
          
          // Kullanıcı türüne göre doğru sayfaya yönlendir
          try {
            // Önce bildirim göster
            showGlobalSnackbar(successMessage, backgroundColor: Colors.green);
            
            // Aynı tür hesaplar arasında geçiş yapılıyorsa, sayfayı yeniden yükleme
            if (isSameAccountType) {
              print('Aynı tür hesaplar arası geçiş, sayfa yeniden yüklenmeyecek');
              
              // Eğer kullanıcı aynı sayfada kalmak istiyorsa geçiş yapmadan hesap değiştirme modunu kapatıyoruz
              isSwitchingAccounts = false;
            } else {
              // Farklı tür hesaplar arasında geçiş yapılıyorsa, doğru sayfaya yönlendir
              if (isTargetAdmin) {
                // Admin paneli sayfasına git ve Kullanıcı Hesapları sekmesine yönlendir
                GoRouter.of(localContext).go('/admin_accounts');
                print('Admin hesabına geçiş tamamlandı, admin paneli hesaplar sekmesine yönlendirildi');
              } else {
                // Normal kullanıcı sayfasına git
                GoRouter.of(localContext).go('/home');
                print('Normal kullanıcı hesabına geçiş tamamlandı, ana sayfaya yönlendirildi');
              }
              
              // En son olarak hesap değiştirme modunu kapat
              // Yönlendirme tamamlandıktan sonra
              isSwitchingAccounts = false;
            }
          } catch (e) {
            // Hata durumunda bayrağı kapat
            isSwitchingAccounts = false;
            
            print('Yönlendirme sırasında hata: $e');
            showGlobalSnackbar('Yönlendirme sırasında hata oluştu: $e', backgroundColor: Colors.orange);
          }
        } else {
          // Widget unmounted durumunda hesap değiştirme modunu kapat
          isSwitchingAccounts = false;
        }
      } else {
        // Hesap değiştirme modunu kapat
        isSwitchingAccounts = false;
        
        // Başarısız giriş
        if (mounted) {
          _showSnackbar(
            'Hesaba geçiş yapılırken bir hata oluştu',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      // Hata durumunda hesap değiştirme modunu kapat
      isSwitchingAccounts = false;
      
      print('Hesap değiştirme hatası: $e');
      
      // Yükleme ve işlem durumunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false; // Hata durumunda da işlem biter
        });
        
        _showSnackbar(
          'Hesap değiştirme hatası: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }
  
  // Kullanıcının admin olup olmadığını kontrol et
  Future<bool> _checkIfUserIsAdmin(int userId) async {
    try {
      print('Admin kontrolü yapılıyor, userId: $userId');
      
      // Kullanıcı bilgilerini al - tüm alanları getir
      final data = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      if (data == null) {
        print('Admin kontrolü: Kullanıcı bulunamadı (userId: $userId)');
        return false;
      }
      
      // Debug için tüm veriyi göster
      print('Admin kontrolü: Alınan veri: ${data.toString()}');
      
      // is_admin değerini kontrol et
      final dynamic isAdminValue = data['is_admin'];
      final String username = (data['username'] as String).toLowerCase();
      
      // Tüm kontrol değerlerini ayrı ayrı göster
      print('Admin kontrolü: is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})');
      print('Admin kontrolü: username değeri: $username');
      
      // Admin kontrolü - is_admin = 1 (veya true) veya username = 'admin'
      bool isAdmin = false;
      
      // is_admin türüne göre kontrol et
      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }
      
      // Kullanıcı adı 'admin' ise her zaman admin kabul et
      if (username == 'admin') {
        isAdmin = true;
      }
      
      print('Admin kontrolü sonucu: $isAdmin');
      return isAdmin;
    } catch (e) {
      print('Admin kontrolü sırasında hata: $e');
      return false;
    }
  }

  Future<void> _addNewAccount() async {
    // Eğer zaten bir işlem yapılıyorsa, yeni işlemi engelle
    if (_isProcessing) return;
    
    setState(() {
      _isLoading = true;
      _isProcessing = true; // İşlem başlıyor
    });

    try {
      // Mevcut hesabı kaydet
      if (_currentUser != null) {
        await _authService.saveCurrentUserToSavedAccounts();
      }
      
      // Kullanıcıya bildirim göster
      _showSnackbar(
        'Yeni hesap eklemek için giriş sayfasına yönlendiriliyorsunuz...',
        backgroundColor: Colors.blue,
      );
      
      // Context'i işlem başlamadan önce saklayalım
      final localContext = context;
      
      // Hesap değiştirme modunu aktifleştir (login ekranına yönlendirmeyi engeller)
      isSwitchingAccounts = true;
      
      // Yükleme ve işlem durumunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false; // İşlem bitti
        });
      }
      
      // Login sayfasına "hesap ekle" modu ile git
      if (mounted) {
        try {
          // Login sayfasına hesap değiştirme moduyla git
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoginScreen(isFromAccountSwitch: true),
            ),
          ).then((_) {
            // Sayfa kapandığında hesapları yeniden yükle
            _loadSavedAccounts();
            _loadCurrentUser();
          });
        } catch (e) {
          print('Login sayfasına yönlendirme hatası: $e');
          // Hesap değiştirme modunu devre dışı bırak
          isSwitchingAccounts = false;
        }
      }
    } catch (e) {
      print('Yeni hesap ekleme hatası: $e');
      
      // Hesap değiştirme modunu devre dışı bırak
      isSwitchingAccounts = false;
      
      // Yükleme ve işlem durumunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false; // Hata durumunda da işlem biter
        });
        
        _showSnackbar(
          'Yeni hesap ekleme hatası: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _removeAccount(Map<String, dynamic> account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];
      
      // Hesabı listeden çıkar
      List<String> updatedAccounts = [];
      for (String accountJson in savedAccountsJson) {
        try {
          final Map<String, dynamic> accountData = 
              jsonDecode(accountJson) as Map<String, dynamic>;
          
          // Silinecek hesap haricindeki hesapları ekle
          if (accountData['user_id'] != account['user_id']) {
            updatedAccounts.add(accountJson);
          }
        } catch (e) {
          print('Hesap verisi ayrıştırılırken hata: $e');
        }
      }
      
      // Güncellenmiş listeyi kaydet
      await prefs.setStringList('saved_accounts', updatedAccounts);
      
      // Hesap listesini güncelle
      await _loadSavedAccounts();
      
      if (mounted) {
        _showSnackbar(
          '${account['first_name']} ${account['last_name']} hesabı kaldırıldı',
          backgroundColor: Colors.blue,
        );
      }
    } catch (e) {
      print('Hesap kaldırma hatası: $e');
      if (mounted) {
        _showSnackbar(
          'Hesap kaldırılırken hata: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  // Hesap kaldırma işlemi için onay diyaloğu göster
  Future<void> _confirmRemoveAccount(Map<String, dynamic> account) async {
    // Hesabı silmeden önce kullanıcıya sor
    final bool result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hesabı Kaldır'),
        content: Text('${account['first_name']} ${account['last_name']} hesabını kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Evet, Kaldır'),
          ),
        ],
      ),
    ) ?? false;

    // Kullanıcı onayladıysa hesabı kaldır
    if (result) {
      await _removeAccount(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif kullanıcıyı bul - güvenli şekilde user_id'yi alalım
    int? currentUserId;
    try {
      currentUserId = _currentUser != null ? 
          (_currentUser!['user_id'] ?? _currentUser!['id']) as int? : null;
    } catch (e) {
      print('Kullanıcı ID dönüştürme hatası: $e');
      currentUserId = null;
    }
    
    // Debuglog için yazdır
    print('Aktif kullanıcı ID: $currentUserId');
    print('Mevcut kullanıcı: ${_currentUser.toString()}');
    
    // Tüm hesapları ekranda görelim (doğru hesap ayrımı için)
    print('Kaydedilmiş hesaplar: ${_savedAccounts.map((a) => '${a['username']} (ID: ${a['user_id'] ?? a['id']})').join(', ')}');
    
    return Scaffold(
      appBar: AppBar(
        // Başlığı kaldır
        title: null,
        // Yeni hesap ekle butonu - ortalanmış
        centerTitle: true,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Kullanıcı Ekle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _addNewAccount,
            ),
          ),
        ),
        // Köşedeki ikonu kaldır
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Kullanıcı aşağı çektiğinde listeyi yenile
                await _loadSavedAccounts();
                await _loadCurrentUser();
              },
              child: ListView(
                children: [
                  // Her zaman mevcut kullanıcıyı en üstte göster
                  if (_currentUser != null)
                    _buildActiveUserCard(_currentUser!),
                  
                  // Diğer hesapları göster (mevcut kullanıcı hariç)
                  ..._savedAccounts
                      .where((account) {
                        // user_id veya id alanlarını kontrol et (her ikisi de olabilir)
                        int? accountId = account['user_id'] ?? account['id'];
                        return accountId != currentUserId; // Aktif kullanıcıyı hariç tut
                      })
                      .map((account) => _buildAccountCard(account))
                      .toList(),
                  
                  // Kaydedilmiş hesap yoksa
                  if (_savedAccounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_circle_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kaydedilmiş hesap bulunamadı',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Üst kısımdaki "Kullanıcı Ekle" butonunu kullanarak yeni hesap ekleyebilirsiniz',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Aktif kullanıcı kartı
  Widget _buildActiveUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          radius: 24,
          child: Text(
            user['first_name'][0],
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${user['first_name']} ${user['last_name']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            // Aktif hesap işareti - daha belirgin
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
        subtitle: Text(
          '@${user['username']}', // Kullanıcı adının başına @ ekle
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: const Text(
            'Aktif',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Aktif hesaba tıklanmasını engelle
        onTap: null,
      ),
    );
  }

  // Diğer hesaplar için kart
  Widget _buildAccountCard(Map<String, dynamic> account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          child: Text(
            account['first_name'][0],
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          '${account['first_name']} ${account['last_name']}',
        ),
        subtitle: Text(
          '@${account['username']}', // Kullanıcı adının başına @ ekle
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Hesabı kaldır',
          onPressed: () => _confirmRemoveAccount(account),
        ),
        onTap: () => _switchAccount(account),
      ),
    );
  }
} 