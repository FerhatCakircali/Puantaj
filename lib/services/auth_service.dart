import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/user_data_notifier.dart';

class AuthService {
  static const String userKey = 'logged_in_user_id';

  // Hesap güncelleme bildirimleri için notifier
  static final ValueNotifier<bool> accountsUpdateNotifier = ValueNotifier<bool>(
    false,
  );

  Future<Map<String, dynamic>?> get currentUser async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        userDataNotifier.value = null;
        return null;
      }

      try {
        final result = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        // .single() başarılı dönerse sonuç null olmaz; hata durumunda exception fırlatır.
        userDataNotifier.value = result;
        return result;
      } catch (e) {
        debugPrint('Kullanıcı bilgileri alınırken hata: $e');
        userDataNotifier.value = null;
        return null;
      }
    } catch (e) {
      debugPrint('currentUser erişiminde hata: $e');
      return null;
    }
  }

  Future<String?> register(
    String username,
    String password,
    String firstName,
    String lastName,
    String jobTitle, {
    bool isAdmin = false,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final usernameError = _validateUsername(lowercaseUsername);
      if (usernameError != null) {
        return usernameError;
      }

      // Kullanıcı adı kullanılabilirlik kontrolü
      final usernameAvailability = await checkUsernameAvailability(
        lowercaseUsername,
      );
      if (usernameAvailability != null) {
        return usernameAvailability;
      }

      await supabase
          .from('users')
          .insert({
            'username': lowercaseUsername,
            'password': password,
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
            'is_admin': isAdmin ? 1 : 0,
            'is_blocked': true,
          })
          .select('id')
          .single();

      // Kayıt sonrası dönen id şu an burada kullanılmıyor.
      // response['id']
      return null;
    } catch (e) {
      debugPrint('Kayıt sırasında hata: $e');
      return 'Bir hata oluştu';
    }
  }

  Future<String?> signIn(String username, String password) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final result = await supabase
          .from('users')
          .select('*, is_blocked')
          .eq('username', lowercaseUsername)
          .eq('password', password)
          .maybeSingle();

      if (result == null) {
        userDataNotifier.value = null;
        return 'Kullanıcı adı veya şifre yanlış.';
      }

      // Kullanıcının bloklu olup olmadığını kontrol et
      final isBlocked = result['is_blocked'] as bool;
      if (isBlocked) {
        userDataNotifier.value = null;
        return 'Hesabınız yönetici tarafından onaylanana kadar giriş yapamazsınız.';
      }

      final userId = result['id'] as int;
      await _setLoggedInUserId(userId);
      await currentUser;
      return null;
    } catch (e) {
      debugPrint('Giriş sırasında hata: $e');

      if (e is SocketException || e is http.ClientException) {
        // Ağ bağlantı hatası (internet yok, sunucuya erişilemiyor vb.)
        userDataNotifier.value = null;
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      } else if (e is PostgrestException) {
        print(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );
        if (e.code == '42P01') {
          // Tablo bulunamadı
          return 'Veritabanı tabloları oluşturulmamış. Lütfen yöneticinize başvurun.';
        }
        return 'Veritabanı hatası: ${e.message}';
      }

      userDataNotifier.value = null;
      return 'Giriş sırasında bir hata oluştu: ${e.toString()}';
    }
  }

  Future<bool> signOut({bool keepSavedAccounts = true}) async {
    try {
      // Önce mevcut kullanıcı bilgilerini alalım
      final currentUserData = userDataNotifier.value;
      if (currentUserData == null) {
        print('Çıkış yapılacak kullanıcı bilgisi bulunamadı');
        return false;
      }

      final currentUserId = currentUserData['id'] as int;
      print('Çıkış yapılacak kullanıcı ID: $currentUserId');

      // Kaydedilmiş hesapları alalım
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];

      // Mevcut kullanıcıyı hesap listesinden çıkaralım
      List<String> updatedAccounts = [];
      int currentAccountIndex = -1;

      // Mevcut kullanıcının listedeki konumunu belirleyelim
      for (int i = 0; i < savedAccountsJson.length; i++) {
        try {
          final accountData =
              jsonDecode(savedAccountsJson[i]) as Map<String, dynamic>;
          final userId =
              accountData['user_id'] as int? ?? accountData['id'] as int?;

          if (userId == currentUserId) {
            // Mevcut kullanıcının indeksini kaydedelim
            currentAccountIndex = i;
            // Ve bu hesabı yeni listeye eklemeyelim (listeden çıkaralım)
            continue;
          }

          // Diğer hesapları yeni listeye ekleyelim
          updatedAccounts.add(savedAccountsJson[i]);
        } catch (e) {
          print('Hesap verisi ayrıştırılırken hata: $e');
          // Hatalı veriyi atlayıp devam et
        }
      }

      // Güncellenmiş listeyi kaydedelim
      await prefs.setStringList('saved_accounts', updatedAccounts);
      print(
        'Mevcut kullanıcı hesap listesinden çıkarıldı. Kalan hesap sayısı: ${updatedAccounts.length}',
      );

      // Sonraki hesaba geçiş için indeks hesaplayalım
      int nextAccountIndex = -1;
      if (updatedAccounts.isNotEmpty) {
        // Eğer çıkış yapılan hesap listenin son elemanı değilse, aynı indeksteki hesaba geç
        // Son elemansa, ilk hesaba geç
        if (currentAccountIndex >= updatedAccounts.length) {
          nextAccountIndex = 0; // Listenin ilk hesabına geç
        } else {
          nextAccountIndex =
              currentAccountIndex; // Aynı indeksteki hesaba geç (şimdi farklı bir hesap)
        }
        print('Geçiş yapılacak hesap indeksi: $nextAccountIndex');

        // Çıkış yapmadan önce bir sonraki hesaba geçiş için bilgileri hazırlayalım
        try {
          // Bir sonraki hesabın bilgilerini al
          final nextAccountJson = updatedAccounts[nextAccountIndex];
          final nextAccountData =
              jsonDecode(nextAccountJson) as Map<String, dynamic>;
          final nextUserId =
              nextAccountData['user_id'] as int? ??
              nextAccountData['id'] as int?;
          final nextUsername = nextAccountData['username'] as String;

          print(
            'Çıkış sonrası geçilecek hesap: $nextUsername (ID: $nextUserId)',
          );

          // Hesap değiştirme modunu aktifleştir (çıkış sonrası login ekranına yönlendirmeyi engeller)
          isSwitchingAccounts = true;
        } catch (e) {
          print('Sonraki hesap bilgileri hazırlanırken hata: $e');
          isSwitchingAccounts = false;
        }
      }

      // Kullanıcı verilerini temizle
      userDataNotifier.value = null;

      // Çıkış yap
      await supabase.auth.signOut();

      // Yerel depolamadaki oturum bilgilerini temizle
      await _clearSessionData();

      // Oturum durumunu güncelle
      authStateNotifier.value = false;

      print('Kullanıcı başarıyla çıkış yaptı');

      // Kaydedilmiş hesaplar varsa ve nextAccountIndex geçerliyse, bir sonraki hesaba otomatik geçiş yap
      if (updatedAccounts.isNotEmpty &&
          nextAccountIndex >= 0 &&
          nextAccountIndex < updatedAccounts.length) {
        try {
          // Bir sonraki hesabın bilgilerini al
          final nextAccountJson = updatedAccounts[nextAccountIndex];
          final nextAccountData =
              jsonDecode(nextAccountJson) as Map<String, dynamic>;
          final nextUserId =
              nextAccountData['user_id'] as int? ??
              nextAccountData['id'] as int?;
          final nextUsername = nextAccountData['username'] as String;

          // Sonraki hesaba geçiş yap
          print(
            'Çıkış sonrası sonraki hesaba otomatik geçiş yapılıyor: $nextUsername (ID: $nextUserId)',
          );

          // Otomatik giriş işlemini başlat (ama login ekranına yönlendirmeyi engelle)
          Future.delayed(Duration(milliseconds: 100), () async {
            final success = await loginWithSavedCredentials(
              userId: nextUserId!,
              username: nextUsername,
            );

            // Hesap değiştirme modunu kapat
            isSwitchingAccounts = false;

            print('Otomatik hesap geçişi sonucu: $success');

            // Hesap listesini yenilemek için bildirim gönder
            if (success) {
              // Hesap değişikliği bildirimini gönder
              // Bu bildirimi UserAccountsScreen dinleyecek
              Future.delayed(Duration(milliseconds: 300), () {
                try {
                  // UserAccountsScreen'i yenilemek için bildirim
                  AuthService.accountsUpdateNotifier.value =
                      !AuthService.accountsUpdateNotifier.value;
                  print('Hesaplar listesi yenileme bildirimi gönderildi');
                } catch (e) {
                  print(
                    'Hesaplar listesi yenileme bildirimi gönderilirken hata: $e',
                  );
                }
              });
            }
          });

          return true;
        } catch (e) {
          print('Sonraki hesaba geçiş sırasında hata: $e');
          isSwitchingAccounts = false;
          return updatedAccounts.isNotEmpty;
        }
      }

      // Kaydedilmiş hesaplar varsa, otomatik giriş için true döndür
      return updatedAccounts.isNotEmpty;
    } catch (e, stack) {
      print('Çıkış yapma hatası: $e');
      logError('Çıkış yapma hatası', e, stack);
      isSwitchingAccounts = false;
      return false;
    }
  }

  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Önce yeni formatta saklanan JSON verisini kontrol et
      final userJson = prefs.getString(userKey);
      if (userJson != null) {
        try {
          // JSON formatında kaydedilmiş veriyi çözümle
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          // user_id veya id alanını bul
          if (userData.containsKey('user_id')) {
            return userData['user_id'] as int;
          } else if (userData.containsKey('id')) {
            return userData['id'] as int;
          }
        } catch (e) {
          print('JSON ayrıştırma hatası: $e');
          // JSON ayrıştırma hatası, eski formatta olabilir
        }
      }

      // Eski formatta saklanan int değerini kontrol et
      return prefs.getInt(userKey);
    } catch (e) {
      print('getUserId hatası: $e');
      return null;
    }
  }

  Future<void> _setLoggedInUserId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kullanıcı kimlik bilgilerini JSON formatında kaydet
      final userData = {
        'user_id': id,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // JSON formatında kaydet
      await prefs.setString(userKey, jsonEncode(userData));
      print('Kullanıcı ID kaydedildi: $id');
    } catch (e) {
      print('Kullanıcı ID kaydedilirken hata: $e');
    }
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      final result = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .eq('password', currentPassword)
          .maybeSingle();

      if (result == null) {
        return 'Mevcut şifre yanlış.';
      }

      await supabase
          .from('users')
          .update({'password': newPassword})
          .eq('id', userId);

      return null;
    } catch (e) {
      return 'Şifre değiştirilirken bir hata oluştu.';
    }
  }

  Future<String?> updateProfile(
    String firstName,
    String lastName,
    String jobTitle,
  ) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      await supabase
          .from('users')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
          })
          .eq('id', userId);

      await currentUser;
      return null;
    } catch (e) {
      return 'Profil güncellenirken bir hata oluştu.';
    }
  }

  Future<String?> updateUsername(String newUsername) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    final lowercaseUsername = newUsername.toLowerCase();

    final usernameError = _validateUsername(lowercaseUsername);
    if (usernameError != null) {
      return usernameError;
    }

    try {
      // Kullanıcı adı kullanılabilirlik kontrolü
      final usernameAvailability = await checkUsernameAvailability(
        lowercaseUsername,
      );
      if (usernameAvailability != null) {
        return usernameAvailability;
      }

      await supabase
          .from('users')
          .update({'username': lowercaseUsername})
          .eq('id', userId);

      await currentUser;
      return null;
    } catch (e) {
      if (e is PostgrestException && e.code == 'P0001') {
        // PostgreSQL özel hata kodu
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      }
      return 'Kullanıcı adı güncellenirken bir hata oluştu.';
    }
  }

  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz.';
    }

    if (username.length > 30) {
      return 'Kullanıcı adı en fazla 30 karakter olabilir.';
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(username)) {
      return 'Kullanıcı adı sadece İngilizce harfler (A-Z) ve sayılardan (0-9) oluşmalıdır.';
    }

    return null;
  }

  Future<String?> checkUsernameAvailability(String username) async {
    try {
      final result = await supabase
          .from('users')
          .select('id')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (result != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }
      return null;
    } catch (e) {
      return 'Kullanıcı adı kontrolü sırasında bir hata oluştu';
    }
  }

  Future<bool> isAdmin() async {
    try {
      final user = await currentUser;
      if (user == null) {
        print('isAdmin: Kullanıcı bilgisi bulunamadı');
        return false;
      }

      print('isAdmin: Kullanıcı verileri: ${user.toString()}');

      // is_admin değerini kontrol et
      final dynamic isAdminValue = user['is_admin'];
      final String username = (user['username'] as String).toLowerCase();

      print(
        'isAdmin: is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})',
      );
      print('isAdmin: username değeri: $username');

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

      print('isAdmin: Sonuç: $isAdmin');
      return isAdmin;
    } catch (e) {
      print('isAdmin: Hata: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final result = await supabase
        .from('users')
        .select()
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<String?> deleteUser(int userId) async {
    try {
      await supabase.from('users').delete().eq('id', userId);
      return null;
    } catch (e) {
      return 'Kullanıcı silinirken bir hata oluştu';
    }
  }

  Future<void> createAdminIfNotExists() async {
    try {
      print('Admin kullanıcı kontrolü başlatılıyor...');

      final result = await supabase
          .from('users')
          .select()
          .eq('username', 'admin')
          .maybeSingle();

      if (result == null) {
        print('Admin kullanıcısı bulunamadı, oluşturuluyor...');
        try {
          await supabase.from('users').insert({
            'username': 'admin',
            'password': 'a',
            'first_name': 'Ferhat',
            'last_name': 'Çakırcalı',
            'job_title': 'Admin',
            'is_admin': 1,
          });
          print('Admin kullanıcısı başarıyla oluşturuldu');
        } catch (e, stack) {
          logError('Admin kullanıcısı oluşturulurken hata', e, stack);
          if (e is PostgrestException) {
            print(
              'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
            );
            if (e.code == '42P01') {
              // Tablo bulunamadı hatası
              print(
                'HATA: users tablosu bulunamadı. Veritabanı tabloları oluşturulmamış olabilir.',
              );
            }
          }
          rethrow; // Hatayı yukarı fırlat
        }
      } else {
        print('Admin kullanıcısı zaten var, ID: ${result['id']}');
      }
    } catch (e, stack) {
      logError('Admin kontrolü sırasında bir hata oluştu', e, stack);
      print('HATA DETAYI: ${e.toString()}');
      if (e is PostgrestException) {
        print(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );
      }
      // İlk başlatma hatası olabilir, tabloların oluşturulması gerekebilir
      print(
        'Veritabanı tabloları oluşturulmamış olabilir veya bağlantı sorunu olabilir',
      );
      rethrow; // Hatayı yukarı fırlat
    }
  }

  Future<String?> updateUser({
    required int userId,
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      // Kullanıcı adı kontrolü (kendi kullanıcı adı hariç)
      final existingUsers = await supabase
          .from('users')
          .select('id')
          .eq('username', lowercaseUsername)
          .neq('id', userId)
          .maybeSingle();

      if (existingUsers != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      await supabase
          .from('users')
          .update({
            'username': lowercaseUsername,
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
            'is_admin': isAdmin ? 1 : 0,
          })
          .eq('id', userId);

      return null;
    } catch (e) {
      return 'Kullanıcı güncellenirken bir hata oluştu';
    }
  }

  Future<String?> updateUserBlockedStatus(int userId, bool isBlocked) async {
    try {
      await supabase
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', userId);
      await currentUser; // Kullanıcının kendi durumu değişmiş olabilir
      return null;
    } catch (e, stack) {
      logError('Kullanıcı blok durumu güncellenirken hata', e, stack);
      return 'Kullanıcı blok durumu güncellenirken bir hata oluştu.';
    }
  }

  /// Mevcut kullanıcıyı kaydedilmiş hesaplar listesine ekler
  Future<bool> saveCurrentUserToSavedAccounts() async {
    try {
      final userData = userDataNotifier.value;
      if (userData == null) {
        print('Kaydedilecek kullanıcı bilgisi bulunamadı');
        return false;
      }

      // user_id olarak kullanıcının id'sini kaydedelim
      Map<String, dynamic> userDataWithId = Map<String, dynamic>.from(userData);
      userDataWithId['user_id'] = userData['id'];

      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];

      // Kullanıcı bilgilerini JSON formatında sakla
      final userJson = jsonEncode(userDataWithId);

      // Eğer bu hesap zaten kaydedilmişse güncelle
      bool accountExists = false;
      List<String> updatedAccounts = [];

      for (String accountJson in savedAccountsJson) {
        try {
          final Map<String, dynamic> accountData =
              jsonDecode(accountJson) as Map<String, dynamic>;

          if (accountData['user_id'] == userData['id']) {
            // Hesap zaten var, güncelle
            updatedAccounts.add(userJson);
            accountExists = true;
          } else {
            // Diğer hesapları olduğu gibi ekle
            updatedAccounts.add(accountJson);
          }
        } catch (e) {
          print('Hesap verisi ayrıştırılırken hata: $e');
          // Hatalı veriyi atlayıp devam et
        }
      }

      // Eğer hesap listede yoksa ekle
      if (!accountExists) {
        updatedAccounts.add(userJson);
      }

      // Güncellenmiş listeyi kaydet
      await prefs.setStringList('saved_accounts', updatedAccounts);
      print(
        'Kullanıcı kaydedilmiş hesaplara eklendi/güncellendi: ${userData['username']}',
      );

      return true;
    } catch (e) {
      print('Kullanıcı kaydedilirken hata: $e');
      return false;
    }
  }

  /// Kaydedilmiş hesapları kontrol eder
  Future<bool> _checkForSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];

      // Kaydedilmiş hesap yoksa false döndür
      if (savedAccountsJson.isEmpty) {
        print('Kaydedilmiş hesap bulunamadı, login ekranına yönlendirilecek');
        return false;
      }

      print('${savedAccountsJson.length} adet kaydedilmiş hesap bulundu');
      return true;
    } catch (e) {
      print('Kaydedilmiş hesapları kontrol ederken hata: $e');
      return false;
    }
  }

  /// Kaydedilmiş ilk hesapla otomatik giriş yapar
  Future<bool> autoLoginWithFirstSavedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsJson = prefs.getStringList('saved_accounts') ?? [];

      if (savedAccountsJson.isEmpty) {
        print('Otomatik giriş yapılacak hesap bulunamadı');
        return false;
      }

      try {
        // İlk kaydedilmiş hesabın bilgilerini al
        final accountData =
            jsonDecode(savedAccountsJson.first) as Map<String, dynamic>;

        // Gerekli alanlar mevcut mu kontrol et
        if (!accountData.containsKey('user_id') ||
            !accountData.containsKey('username')) {
          print('Hesap verisinde gerekli alanlar eksik');
          return false;
        }

        final userId = accountData['user_id'] as int;
        final username = accountData['username'] as String;

        print(
          'İlk kaydedilmiş hesaba otomatik giriş yapılıyor: $username (ID: $userId)',
        );

        // Hesap geçişi yap (login ekranını atla)
        return await switchToSavedAccount(userId: userId, username: username);
      } catch (e) {
        print('Hesap verisi ayrıştırılırken hata: $e');
        return false;
      }
    } catch (e) {
      print('Otomatik giriş sırasında hata: $e');
      return false;
    }
  }

  /// Kaydedilmiş hesaplardan birini kullanarak giriş yapar
  Future<bool> loginWithSavedCredentials({
    required int userId,
    required String username,
  }) async {
    try {
      print('Kaydedilmiş hesapla giriş yapılıyor: $username (ID: $userId)');

      // Kullanıcı bilgilerini al
      final data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .eq('username', username)
          .single();

      if (data == null) {
        print('Kullanıcı bulunamadı: $username');
        return false;
      }

      // Kullanıcı bilgilerini güncelle
      userDataNotifier.value = data;
      authStateNotifier.value = true;

      // Oturum bilgilerini kaydet
      await _saveSessionData(userId, username);

      print('Kaydedilmiş hesaba giriş başarılı: $username');
      return true;
    } catch (e, stack) {
      print('Kaydedilmiş hesaba giriş hatası: $e');
      logError('Kaydedilmiş hesaba giriş hatası', e, stack);
      return false;
    }
  }

  /// Kaydedilmiş tüm hesapları temizler
  Future<void> clearSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_accounts');
      print('Tüm kaydedilmiş hesaplar temizlendi');
    } catch (e) {
      print('Kaydedilmiş hesaplar temizlenirken hata: $e');
    }
  }

  /// Oturum bilgilerini yerel depolamaya kaydet
  Future<void> _saveSessionData(int userId, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kullanıcı bilgilerini kaydet
      final userData = {
        'user_id': userId,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(userKey, jsonEncode(userData));
      print('Oturum bilgileri kaydedildi: $username');
    } catch (e) {
      print('Oturum bilgileri kaydedilirken hata: $e');
    }
  }

  /// Oturum bilgilerini yerel depolamadan temizle
  Future<void> _clearSessionData() async {
    try {
      print('Oturum bilgileri temizleniyor...');

      // Önce yevmiye durumunu temizle
      try {
        // Doğrudan AttendanceCheck sınıfını import etmek yerine,
        // SharedPreferences üzerinden temizleme yapalım
        final prefs = await SharedPreferences.getInstance();
        final userId = await getUserId();

        if (userId != null) {
          final attendanceKey = 'attendance_date_user_$userId';
          await prefs.remove(attendanceKey);
          print('Kullanıcıya ait yevmiye durumu temizlendi');
        }
      } catch (e) {
        print('Yevmiye durumu temizlenirken hata: $e');
      }

      // Kullanıcı oturum bilgisini temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userKey);

      // Bildirim ve navigasyon durum değişkenlerini temizle
      await prefs.setBool('launched_from_notification', false);
      await prefs.setBool('notification_needs_handling', false);
      await prefs.setBool('flutter.notification_needs_handling', false);
      await prefs.remove('last_notification_payload');

      // Bildirim ayarları için de temizlik yap
      final today = DateTime.now();
      final todayKey =
          'notification_sent_${today.year}_${today.month}_${today.day}';
      await prefs.remove(todayKey);

      print('Oturum bilgileri başarıyla temizlendi');
    } catch (e) {
      print('Oturum bilgileri temizlenirken hata: $e');
    }
  }

  /// Kaydedilmiş hesaplar arasında direkt geçiş yapar (çıkış yapmadan)
  Future<bool> switchToSavedAccount({
    required int userId,
    required String username,
  }) async {
    try {
      print('Hesap değiştiriliyor: $username (ID: $userId)');

      // Hesap değiştirme modunu başlangıçta aktifleştir (login ekranına yönlendirmeyi engeller)
      isSwitchingAccounts = true;

      // Önce mevcut kullanıcı ve hedef kullanıcının admin durumunu kontrol et
      bool isCurrentAdmin = false;
      bool isTargetAdmin = false;

      try {
        // Mevcut kullanıcının admin durumunu al
        final currentUser = await this.currentUser;
        if (currentUser != null) {
          final dynamic currentAdminValue = currentUser['is_admin'];
          final String currentUsername = (currentUser['username'] as String)
              .toLowerCase();

          if (currentAdminValue is int) {
            isCurrentAdmin = currentAdminValue == 1;
          } else if (currentAdminValue is bool) {
            isCurrentAdmin = currentAdminValue;
          }

          if (currentUsername == 'admin') {
            isCurrentAdmin = true;
          }
        }

        // Hedef kullanıcının admin durumunu al
        final targetData = await supabase
            .from('users')
            .select('is_admin, username')
            .eq('id', userId)
            .single();

        if (targetData != null) {
          final dynamic targetAdminValue = targetData['is_admin'];
          final String targetUsername = (targetData['username'] as String)
              .toLowerCase();

          if (targetAdminValue is int) {
            isTargetAdmin = targetAdminValue == 1;
          } else if (targetAdminValue is bool) {
            isTargetAdmin = targetAdminValue;
          }

          if (targetUsername == 'admin') {
            isTargetAdmin = true;
          }
        }
      } catch (e) {
        print('Admin durumu kontrolünde hata: $e');
        // Hata durumunda varsayılan değerleri kullan (false)
      }

      // Mevcut kullanıcıyı kaydet
      await saveCurrentUserToSavedAccounts();

      // Doğrudan yeni kullanıcı bilgilerini al (çıkış yapmadan)
      final data = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .eq('username', username)
          .single();

      if (data == null) {
        print('Kullanıcı bulunamadı: $username');
        isSwitchingAccounts = false; // Hata durumunda bayrağı kapat
        return false;
      }

      // Kullanıcı verilerini göster
      print('Kullanıcı verileri: ${data.toString()}');

      // is_admin değerini kontrol et
      final dynamic isAdminValue = data['is_admin'];
      final String usernameValue = (data['username'] as String).toLowerCase();

      print('is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})');
      print('username değeri: $usernameValue');

      bool isAdmin = false;

      // is_admin türüne göre kontrol et
      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      // Kullanıcı adı 'admin' ise her zaman admin kabul et
      if (usernameValue == 'admin') {
        isAdmin = true;
      }

      print('Admin hesabı mı: $isAdmin');
      print(
        'Mevcut kullanıcı admin mi: $isCurrentAdmin, Hedef kullanıcı admin mi: $isTargetAdmin',
      );

      // Aynı tür hesaplar arası geçiş mi? (admin->admin veya normal->normal)
      final bool isSameAccountType = isCurrentAdmin == isTargetAdmin;
      print('Aynı tür hesaplar arası geçiş mi: $isSameAccountType');

      // Önce oturum bilgilerini kaydet, kullanıcı bilgilerini sonra güncelle
      // Bu sıralama daha pürüzsüz geçiş sağlar

      // 1. Oturum bilgilerini kaydet (SharedPreferences)
      await _saveSessionData(userId, username);

      // 2. Auth durumu değişikliği öncesi kısa gecikme
      // Aynı tür hesap değişiminde gecikmeyi azalt
      if (isSameAccountType) {
        await Future.delayed(const Duration(milliseconds: 10));
      } else {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 3. Kullanıcı bilgilerini güncelle (notifier'ı update et)
      userDataNotifier.value = data;

      // 4. Auth durumunu güncelle (router yönlendirmesi için)
      print(
        isAdmin
            ? 'Admin hesabına geçiş hazırlanıyor...'
            : 'Normal kullanıcı hesabına geçiş hazırlanıyor...',
      );

      // Aynı tür hesaplar arası geçişte auth durumu değişikliğini atla
      if (!isSameAccountType) {
        // Farklı tür hesaplar arasında geçişte auth durumunu güncelle
        authStateNotifier.value = true;
      }

      print('Hesap değiştirme başarılı: $username (ID: $userId)');
      print('Kullanıcı admin mi: $isAdmin');

      return true;
    } catch (e, stack) {
      // Hata durumunda normal duruma dön
      isSwitchingAccounts = false;

      print('Hesap değiştirme hatası: $e');
      logError('Hesap değiştirme hatası', e, stack);
      return false;
    }
  }

  /// Kullanıcının bloklu olup olmadığını kontrol eder
  Future<bool> isUserBlocked() async {
    try {
      final userId = await getUserId();
      if (userId == null) return false;

      final result = await supabase
          .from('users')
          .select('is_blocked')
          .eq('id', userId)
          .single();

      if (result != null && result['is_blocked'] == true) {
        print('Kullanıcı bloklanmış: $userId');
        return true;
      }

      return false;
    } catch (e, stack) {
      logError('Kullanıcı blok durumu kontrol edilirken hata', e, stack);
      return false;
    }
  }

  SupabaseClient get supabase => Supabase.instance.client;

  ValueNotifier<bool> get authStateNotifier => ValueNotifier<bool>(false);

  void logError(String message, dynamic error, StackTrace? stackTrace) {
    print('Error: $message');
    print('Details: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  bool _isSwitchingAccounts = false;

  bool get isSwitchingAccounts => _isSwitchingAccounts;

  set isSwitchingAccounts(bool value) {
    _isSwitchingAccounts = value;
  }
}
