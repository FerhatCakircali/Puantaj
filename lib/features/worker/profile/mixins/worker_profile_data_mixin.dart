import 'package:flutter/material.dart';

import '../../../../core/mixins/context_safety_mixin.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../models/worker.dart';
import '../../../../services/worker_service.dart';
import '../../../../core/di/service_locator.dart';

/// Çalışan profil veri yönetimi mixin'i
/// Profil bilgilerini yükleme, güncelleme ve session yönetimi
mixin WorkerProfileDataMixin<T extends StatefulWidget> on State<T> {
  ContextSafetyMixin get contextSafety => this as ContextSafetyMixin;

  late final WorkerService _workerService;
  late final LocalStorageService _localStorage;

  @override
  void initState() {
    super.initState();
    _workerService = getIt<WorkerService>();
    _localStorage = getIt<LocalStorageService>();
  }

  Worker? _worker;
  String? _username;
  String? _usernameError;
  bool _isLoading = true;

  Worker? get worker => _worker;
  String? get username => _username;
  String? get usernameError => _usernameError;
  bool get isLoading => _isLoading;

  /// Çalışan verilerini yükler
  Future<void> loadWorkerData({required VoidCallback onSessionExpired}) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('loadWorkerData: Başlıyor...');
      final session = await _localStorage.getWorkerSession();
      debugPrint('loadWorkerData: Session = $session');

      if (session == null) {
        debugPrint('loadWorkerData: Session null, oturum süresi dolmuş');
        if (mounted) {
          onSessionExpired();
        }
        return;
      }

      final workerId = int.parse(session['workerId']!);
      _username = session['username'];
      debugPrint('loadWorkerData: workerId=$workerId, username=$_username');

      final worker = await _workerService.getWorkerById(workerId);
      debugPrint('loadWorkerData: Worker = $worker');

      if (!mounted) return;

      if (worker != null) {
        debugPrint(
          '✅ loadWorkerData: Worker bulundu: ${worker.fullName}, email: ${worker.email}',
        );
        setState(() {
          _worker = worker;
          _isLoading = false;
        });
      } else {
        debugPrint('loadWorkerData: Worker null');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint('loadWorkerData: Hata: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        contextSafety.safeShowErrorSnackBar('Profil bilgileri yüklenemedi: $e');
      }
    }
  }

  /// Profil bilgilerini günceller
  Future<bool> updateWorkerProfile({
    required String username,
    required String fullName,
    String? title,
    String? phone,
    String? email,
  }) async {
    if (!mounted || _worker == null) return false;

    if (username.trim().isEmpty) {
      contextSafety.safeShowErrorSnackBar(
        'Lütfen kullanıcı adı alanını doldurunuz',
      );
      return false;
    }

    if (fullName.trim().isEmpty) {
      contextSafety.safeShowErrorSnackBar('Lütfen ad soyad alanını doldurunuz');
      return false;
    }

    try {
      final updatedWorker = Worker(
        id: _worker!.id,
        userId: _worker!.userId,
        username: username.trim(),
        fullName: fullName.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        startDate: _worker!.startDate,
        createdAt: _worker!.createdAt,
      );

      await _workerService.updateWorker(updatedWorker);

      if (!mounted) return false;

      setState(() {
        _worker = updatedWorker;
        _username = username.trim();
      });

      // Local storage'daki username ve fullName'i de güncelle
      final session = await _localStorage.getWorkerSession();
      if (session != null) {
        await _localStorage.saveWorkerSession(
          workerId: session['workerId']!,
          username: username.trim(),
          fullName: fullName.trim(),
          userId: session['userId'],
        );
      }

      contextSafety.safeShowSuccessSnackBar('Profil başarıyla güncellendi');
      return true;
    } catch (e) {
      if (mounted) {
        contextSafety.safeShowErrorSnackBar(
          'Profil güncellenirken hata oluştu: $e',
        );
      }
      return false;
    }
  }

  /// Kullanıcı adı doğrulaması
  void validateUsername(String value, String? originalUsername) {
    if (!mounted) return;

    if (value.isEmpty) {
      setState(() => _usernameError = 'Kullanıcı adı gerekli');
      return;
    }

    if (value.length < 3) {
      setState(() => _usernameError = 'Kullanıcı adı en az 3 karakter olmalı');
      return;
    }

    if (value.toLowerCase() == originalUsername?.toLowerCase()) {
      setState(() => _usernameError = null);
      return;
    }

    setState(() => _usernameError = null);
  }
}
