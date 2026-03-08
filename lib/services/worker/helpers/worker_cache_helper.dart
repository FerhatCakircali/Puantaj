import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/employee.dart';
import '../../../data/local/hive_service.dart';
import '../constants/worker_constants.dart';

/// Çalışan verilerini cache'leyen helper sınıfı
class WorkerCacheHelper {
  final _hiveService = HiveService.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Cache'den kullanıcıya ait çalışanları getirir
  ///
  /// [userId] Kullanıcı ID'si
  /// Returns: Cache'deki çalışan listesi
  List<Employee> getCachedEmployees(int userId) {
    return _hiveService.employees.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Supabase'den çalışanları çeker ve cache'e kaydeder
  ///
  /// [userId] Kullanıcı ID'si
  Future<void> fetchAndCacheEmployees(int userId) async {
    try {
      final response = await _supabase
          .from(WorkerConstants.tableName)
          .select('*, username')
          .eq(WorkerConstants.userIdColumn, userId)
          .order(WorkerConstants.fullNameColumn);

      final employees = (response as List)
          .map((map) => Employee.fromMap(map as Map<String, dynamic>))
          .toList();

      for (var employee in employees) {
        await _hiveService.employees.put(employee.id, employee);
      }

      debugPrint('Cache güncellendi: ${employees.length} çalışan');
    } catch (e) {
      debugPrint('Cache güncelleme başarısız: $e');
    }
  }

  /// Supabase'den çalışanları çeker ve cache'e kaydeder, sonucu döndürür
  ///
  /// [userId] Kullanıcı ID'si
  /// Returns: Çekilen çalışan listesi
  Future<List<Employee>> fetchEmployees(int userId) async {
    final response = await _supabase
        .from(WorkerConstants.tableName)
        .select('*, username')
        .eq(WorkerConstants.userIdColumn, userId)
        .order(WorkerConstants.fullNameColumn);

    final employees = (response as List)
        .map((map) => Employee.fromMap(map as Map<String, dynamic>))
        .toList();

    for (var employee in employees) {
      await _hiveService.employees.put(employee.id, employee);
    }

    return employees;
  }

  /// Tüm cache'i döndürür
  ///
  /// Returns: Cache'deki tüm çalışanlar
  List<Employee> getAllCachedEmployees() {
    return _hiveService.employees.values.toList();
  }
}
