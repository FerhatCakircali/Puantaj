import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/local_storage_service.dart';
import '../../../../data/services/password_hasher.dart';
import '../../../../core/app_globals.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/fcm_service.dart';
import '../../../../core/error_logger.dart';

/// Login authentication mixin
//// Handles admin and worker login logic
mixin LoginAuthMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isWorkerLoading = false;
  String? _errorMessage;
  String? _workerErrorMessage;

  bool get isLoading => _isLoading;
  bool get isWorkerLoading => _isWorkerLoading;
  String? get errorMessage => _errorMessage;
  String? get workerErrorMessage => _workerErrorMessage;

  /// Admin login
  Future<void> signIn({
    required String username,
    required String password,
    required VoidCallback onSuccess,
    required Function(String) onError,
    bool isFromAccountSwitch = false,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      onError('Lütfen tüm alanları doldurunuz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _authService.signIn(username, password);

      if (error != null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
        onError(error);
      } else {
        // Call success callback
        onSuccess();

        if (mounted) {
          setState(() => _isLoading = false);
        }

                ref.read(authStateProvider.notifier).login();

        // Handle navigation
        if (mounted) {
          if (isFromAccountSwitch) {
            // Account switch mode
            final userData = await _authService.currentUser;
            if (userData == null) {
              throw Exception('Kullanıcı bilgileri alınamadı');
            }

            if (!mounted) return;
            Navigator.of(context).pop();

            Future.delayed(const Duration(milliseconds: 300), () {
              if (!context.mounted) return;
              try {
                final username = userData['username'] as String? ?? '';
                final firstName = userData['first_name'] as String? ?? '';
                final lastName = userData['last_name'] as String? ?? '';
                showGlobalSnackbar(
                  '$firstName $lastName ($username) hesabına giriş yapıldı',
                  backgroundColor: Colors.green,
                );
              } catch (e) {
                debugPrint('SnackBar gösterilirken hata: $e');
              }
            });
          } else {
            // Normal login - router otomatik yönlendirecek
            debugPrint('Login başarılı, router otomatik yönlendirme yapacak');
          }
        }
      }
    } catch (e) {
      debugPrint('Giriş hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Giriş yapılırken bir hata oluştu: $e';
          _isLoading = false;
        });
        onError('Giriş yapılırken bir hata oluştu: $e');
      }
    }
  }

  /// Worker login
  Future<void> workerSignIn({
    required String username,
    required String password,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      onError('Lütfen tüm alanları doldurunuz');
      return;
    }

    setState(() {
      _isWorkerLoading = true;
      _workerErrorMessage = null;
    });

    try {
      // Worker'ı username ile bul
      final response = await _authService.supabase
          .from('workers')
          .select('id, username, full_name, user_id, is_active, password_hash')
          .eq('username', username)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;
        setState(() {
          _workerErrorMessage = 'Kullanıcı adı veya şifre hatalı';
          _isWorkerLoading = false;
        });
        onError('Kullanıcı adı veya şifre hatalı');
        return;
      }

      // Şifre hash kontrolü
      final passwordHasher = PasswordHasher.instance;
      final storedHash = response['password_hash'] as String;
      final isPasswordValid = await passwordHasher.verifyPassword(
        password,
        storedHash,
      );

      if (!isPasswordValid) {
        if (!mounted) return;
        setState(() {
          _workerErrorMessage = 'Kullanıcı adı veya şifre hatalı';
          _isWorkerLoading = false;
        });
        onError('Kullanıcı adı veya şifre hatalı');
        return;
      }

      // Check if worker is active
      final isActive = response['is_active'] as bool? ?? true;
      if (!isActive) {
        if (!mounted) return;
        setState(() {
          _workerErrorMessage = 'Hesabınız devre dışı bırakılmış';
          _isWorkerLoading = false;
        });
        onError('Hesabınız devre dışı bırakılmış');
        return;
      }

      // Çalışan girişi yapılırken kullanıcı oturumunu temizle
      debugPrint('🧹 Çalışan girişi - Kullanıcı oturumu temizleniyor...');
      try {
        await _authService.signOut();
                ref.read(authStateProvider.notifier).logout();
        debugPrint('Kullanıcı oturumu temizlendi');
      } catch (e, stackTrace) {
        ErrorLogger.instance.logError(
          'LoginAuthMixin.workerSignIn - signOut hatası',
          error: e,
          stackTrace: stackTrace,
        );
        debugPrint(
          '⚠️ Kullanıcı oturumu temizlenirken hata (devam ediliyor): $e',
        );
      }

      // Save worker session to local storage
      final localStorage = LocalStorageService.instance;
      await localStorage.saveWorkerSession(
        workerId: response['id'].toString(),
        username: response['username'] as String,
        fullName: response['full_name'] as String,
        userId: response['user_id']?.toString(),
      );

      // Update last login timestamp
      await _authService.supabase
          .from('workers')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', response['id']);

      // FCM token'ı kaydet (Worker için)
      try {
        final workerId = response['id'] as int;
        debugPrint('💾 FCM token kaydediliyor (Worker: $workerId)...');
        await FCMService.instance.saveTokenForWorker(workerId);
        debugPrint('FCM token kaydedildi');
      } catch (e) {
        debugPrint('FCM token kaydedilemedi (devam ediliyor): $e');
      }

      if (!mounted) return;
      setState(() => _isWorkerLoading = false);

      // Call success callback
      onSuccess();

      // Navigate to worker home
      if (mounted) {
        context.go('/worker/home');
      }
    } catch (e) {
      debugPrint('Worker login error: $e');
      if (!mounted) return;
      setState(() {
        _workerErrorMessage = 'Giriş yapılırken bir hata oluştu: $e';
        _isWorkerLoading = false;
      });
      if (mounted) {
        onError(_workerErrorMessage ?? 'Giriş yapılırken bir hata oluştu');
      }
    }
  }

  /// Check auto login for both admin and worker
  Future<void> checkAutoLogin() async {
    if (!mounted) return;

    try {
      // Hızlı kontrol için timeout ekle
      await Future.any([
        _performAutoLoginCheck(),
        Future.delayed(const Duration(seconds: 2), () {
          debugPrint('⏱ Auto login timeout, login ekranında kalınıyor');
        }),
      ]);
    } catch (e, stackTrace) {
      debugPrint('Otomatik giriş kontrolü hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _performAutoLoginCheck() async {
    if (!mounted) return;

    // 1. Admin session check
    final user = await _authService.currentUser;
    if (user != null && mounted) {
      debugPrint('✅ Yönetici session bulundu, /home\'a yönlendiriliyor');
            ref.read(authStateProvider.notifier).login();
      context.go('/home');
      return;
    }

    // 2. Worker session check
    final localStorage = LocalStorageService.instance;
    final workerSession = await localStorage.getWorkerSession();
    if (workerSession != null && mounted) {
      debugPrint('✅ Çalışan session bulundu, /worker/home\'a yönlendiriliyor');
      context.go('/worker/home');
      return;
    }

    debugPrint('ℹ Geçerli session bulunamadı, login ekranında kalınıyor');
  }
}
