import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../core/error_logger.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../services/attendance_service.dart';
import '../../services/payment_service.dart';
import 'hive_service.dart';

/// Offline-first senkronizasyon yöneticisi
/// 
/// İnternet bağlantısı geldiğinde bekleyen verileri Supabase'e gönderir.
/// Connectivity_plus ile internet durumunu dinler.
class SyncManager {
  // Singleton pattern
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final _hiveService = HiveService.instance;
  final _connectivity = Connectivity();
  final _attendanceService = AttendanceService();
  final _paymentService = PaymentService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isOnline = false;

  /// Sync manager'ı başlat ve connectivity dinlemeye başla
  Future<void> initialize() async {
    // İlk bağlantı durumunu kontrol et
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = !connectivityResult.contains(ConnectivityResult.none);

    // Connectivity değişikliklerini dinle
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        ErrorLogger.logError(
          'SyncManager connectivity error',
          error: error,
        );
      },
    );

    print('🔄 SyncManager başlatıldı - Online: $_isOnline');

    // Eğer online ise bekleyen verileri senkronize et
    if (_isOnline) {
      await syncPendingData();
    }
  }

  /// Connectivity değişikliği olduğunda çağrılır
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    print('📡 Bağlantı durumu değişti: $_isOnline');

    // Offline'dan online'a geçiş yapıldıysa sync başlat
    if (!wasOnline && _isOnline) {
      print('✅ İnternet bağlantısı geldi, senkronizasyon başlatılıyor...');
      syncPendingData();
    }
  }

  /// Online durumunu kontrol et
  bool get isOnline => _isOnline;

  /// Bekleyen verileri senkronize et
  Future<void> syncPendingData() async {
    if (_isSyncing) {
      print('⏳ Senkronizasyon zaten devam ediyor...');
      return;
    }

    if (!_isOnline) {
      print('📵 Offline modda, senkronizasyon atlandı');
      return;
    }

    _isSyncing = true;

    try {
      final pendingBox = _hiveService.pendingSync;
      final pendingItems = pendingBox.values.toList();

      if (pendingItems.isEmpty) {
        print('✅ Senkronize edilecek veri yok');
        _isSyncing = false;
        return;
      }

      print('🔄 ${pendingItems.length} bekleyen veri senkronize ediliyor...');

      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < pendingItems.length; i++) {
        final item = pendingItems[i] as Map;
        final key = pendingBox.keyAt(i);

        try {
          final type = item['type'] as String;
          final data = item['data'] as Map<String, dynamic>;
          final operation = item['operation'] as String; // 'create', 'update', 'delete'

          bool success = false;

          switch (type) {
            case 'attendance':
              success = await _syncAttendance(data, operation);
              break;
            case 'payment':
              success = await _syncPayment(data, operation);
              break;
            default:
              print('⚠️ Bilinmeyen veri tipi: $type');
          }

          if (success) {
            await pendingBox.delete(key);
            successCount++;
            print('✅ Senkronize edildi: $type ($operation)');
          } else {
            failCount++;
            print('❌ Senkronizasyon başarısız: $type ($operation)');
          }
        } catch (e, stackTrace) {
          failCount++;
          ErrorLogger.logError(
            'Sync item error',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      print('🎉 Senkronizasyon tamamlandı: $successCount başarılı, $failCount başarısız');

      // Son sync zamanını kaydet
      await _hiveService.metadata.put('last_sync', DateTime.now().toIso8601String());
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'SyncManager syncPendingData error',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Attendance verisini senkronize et
  Future<bool> _syncAttendance(Map<String, dynamic> data, String operation) async {
    try {
      switch (operation) {
        case 'create':
        case 'update':
          final attendance = Attendance.fromMap(data);
          await _attendanceService.saveAttendance(
            attendance.workerId,
            attendance.date,
            attendance.status,
          );
          return true;
        case 'delete':
          // Delete işlemi için gerekirse implement et
          return true;
        default:
          return false;
      }
    } catch (e) {
      ErrorLogger.logError('Attendance sync error', error: e);
      return false;
    }
  }

  /// Payment verisini senkronize et
  Future<bool> _syncPayment(Map<String, dynamic> data, String operation) async {
    try {
      switch (operation) {
        case 'create':
          final payment = Payment.fromMap(data);
          await _paymentService.createPayment(payment);
          return true;
        case 'update':
        case 'delete':
          // Update/delete işlemleri için gerekirse implement et
          return true;
        default:
          return false;
      }
    } catch (e) {
      ErrorLogger.logError('Payment sync error', error: e);
      return false;
    }
  }

  /// Pending sync'e yeni veri ekle
  Future<void> addPendingSync({
    required String type,
    required Map<String, dynamic> data,
    required String operation,
  }) async {
    try {
      final pendingBox = _hiveService.pendingSync;
      final key = '${type}_${operation}_${DateTime.now().millisecondsSinceEpoch}';

      await pendingBox.put(key, {
        'type': type,
        'data': data,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('📝 Pending sync\'e eklendi: $type ($operation)');

      // Eğer online ise hemen sync dene
      if (_isOnline) {
        syncPendingData();
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Add pending sync error',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Son sync zamanını al
  DateTime? get lastSyncTime {
    final lastSyncStr = _hiveService.metadata.get('last_sync') as String?;
    if (lastSyncStr != null) {
      return DateTime.parse(lastSyncStr);
    }
    return null;
  }

  /// Bekleyen sync sayısını al
  int get pendingSyncCount => _hiveService.pendingSync.length;

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    print('🔒 SyncManager kapatıldı');
  }
}
