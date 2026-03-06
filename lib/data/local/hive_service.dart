import 'package:hive_flutter/hive_flutter.dart';
import '../../models/attendance.dart';
import '../../models/employee.dart';
import '../../models/payment.dart';
import '../../models/worker.dart';
import 'hive_adapters/attendance_adapter.dart';
import 'hive_adapters/employee_adapter.dart';
import 'hive_adapters/payment_adapter.dart';
import 'hive_adapters/worker_adapter.dart';

/// Hive yerel veritabanı servisi
///
/// Offline-first mimari için tüm Hive işlemlerini yönetir.
/// Box isimleri, adapter kayıtları ve initialization işlemlerini içerir.
class HiveService {
  // Singleton pattern
  HiveService._();
  static final HiveService instance = HiveService._();

  // Box isimleri
  static const String workersBox = 'workers';
  static const String employeesBox = 'employees';
  static const String attendanceBox = 'attendance';
  static const String paymentsBox = 'payments';
  static const String pendingSyncBox = 'pending_sync';
  static const String metadataBox = 'metadata';

  bool _isInitialized = false;

  /// Hive'ı başlat ve adapter'ları kaydet
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Hive'ı Flutter ile başlat
      await Hive.initFlutter();

      // TypeAdapter'ları kaydet
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(AttendanceAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(WorkerAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PaymentAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(EmployeeAdapter());
      }

      // Box'ları aç
      await Future.wait([
        Hive.openBox<Worker>(workersBox),
        Hive.openBox<Employee>(employeesBox),
        Hive.openBox<Attendance>(attendanceBox),
        Hive.openBox<Payment>(paymentsBox),
        Hive.openBox<Map>(pendingSyncBox),
        Hive.openBox<dynamic>(metadataBox),
      ]);

      _isInitialized = true;
      print('✅ Hive başarıyla başlatıldı');
    } catch (e, stackTrace) {
      print('❌ Hive başlatma hatası: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Worker box'ını al
  Box<Worker> get workers => Hive.box<Worker>(workersBox);

  /// Employee box'ını al
  Box<Employee> get employees => Hive.box<Employee>(employeesBox);

  /// Attendance box'ını al
  Box<Attendance> get attendance => Hive.box<Attendance>(attendanceBox);

  /// Payment box'ını al
  Box<Payment> get payments => Hive.box<Payment>(paymentsBox);

  /// Pending sync box'ını al (senkronize edilmeyi bekleyen veriler)
  Box<Map> get pendingSync => Hive.box<Map>(pendingSyncBox);

  /// Metadata box'ını al (son sync zamanı, vb.)
  Box<dynamic> get metadata => Hive.box<dynamic>(metadataBox);

  /// Tüm box'ları temizle (logout için)
  Future<void> clearAll() async {
    await Future.wait([
      workers.clear(),
      employees.clear(),
      attendance.clear(),
      payments.clear(),
      pendingSync.clear(),
      metadata.clear(),
    ]);
    print('🗑️ Tüm Hive boxları temizlendi');
  }

  /// Belirli bir box'ı temizle
  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
    print('🗑️ $boxName boxi temizlendi');
  }

  /// Hive'ı kapat
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
    print('🔒 Hive kapatıldı');
  }
}
