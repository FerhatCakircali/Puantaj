import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker.dart';
import '../models/employee.dart';
import 'auth_service.dart';

class WorkerService {
  final AuthService _authService = AuthService();

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  SupabaseClient get supabase => Supabase.instance.client;

  // Tüm çalışanları getir
  Future<List<Employee>> getEmployees() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .order('full_name');
      return (response as List)
          .map((map) => Employee.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }

  Future<List<Worker>> getWorkers() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final List<dynamic> data = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .order('full_name', ascending: true);

      return data.map((worker) => Worker.fromMap(worker)).toList();
    } catch (e) {
      return [];
    }
  }

  // ID'ye göre çalışan getir (Worker)
  Future<Worker?> getWorkerById(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final data = await supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .eq('user_id', userId)
          .single();

      return Worker.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Çalışan ekle (Worker)
  Future<Worker?> addWorker(Worker worker) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final map = worker.toMap();
      map['user_id'] = userId;

      final data = await supabase.from('workers').insert(map).select().single();

      return Worker.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Çalışan ekle (Employee - backward compatibility)
  Future<int> addEmployee(Employee employee) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return -1;

      final response = await supabase
          .from('workers')
          .insert({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'start_date': _formatDate(employee.startDate),
            'user_id': userId,
          })
          .select('id');
      return response.first['id'] as int;
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  Future<int> addEmployee_backup(Employee employee) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    final map = employee.toMap();
    map['user_id'] = userId;

    try {
      final result = await supabase
          .from('workers')
          .insert(map)
          .select('id')
          .single();

      return result['id'];
    } catch (e) {
      return -1;
    }
  }

  // Çalışan güncelle (Worker)
  Future<bool> updateWorker(Worker worker) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await supabase
          .from('workers')
          .update(worker.toMap())
          .eq('id', worker.id!)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Çalışan güncelle (Employee - backward compatibility)
  Future<int> updateEmployee(Employee employee) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await supabase
          .from('workers')
          .update({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'start_date': _formatDate(employee.startDate),
          })
          .eq('id', employee.id)
          .eq('user_id', userId);
      return employee.id;
    } catch (e) {
      print('Error updating employee: $e');
      rethrow;
    }
  }

  Future<int> updateEmployee_backup(Employee employee) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      await supabase
          .from('workers')
          .update(employee.toMap())
          .eq('id', employee.id)
          .eq('user_id', userId);

      return 1;
    } catch (e) {
      return -1;
    }
  }

  // Çalışan sil (Worker)
  Future<bool> deleteWorker(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await supabase
          .from('workers')
          .delete()
          .eq('id', workerId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Çalışan sil (Employee - backward compatibility)
  Future<int> deleteEmployee(int id) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      await supabase
          .from('workers')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      return 1;
    } catch (e) {
      return -1;
    }
  }

  // Tüm çalışanları sil (Employee - backward compatibility)
  Future<int> deleteAllEmployees() async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      // İlişkili kayıtları da sil (cascading delete yerine manuel silme)
      await supabase.from('paid_days').delete().eq('user_id', userId);

      await supabase.from('payments').delete().eq('user_id', userId);

      await supabase.from('attendance').delete().eq('user_id', userId);

      await supabase.from('workers').delete().eq('user_id', userId);

      return 1;
    } catch (e) {
      return -1;
    }
  }

  // İsme göre çalışan ara (Worker)
  Future<List<Worker>> searchWorkers(String query) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final List<dynamic> data = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .ilike('full_name', '%$query%')
          .order('full_name', ascending: true);

      return data.map((worker) => Worker.fromMap(worker)).toList();
    } catch (e) {
      return [];
    }
  }

  // Belirlenen tarihten öncesinde herhangi bir devam kaydı veya ödeme kaydı var mı
  Future<bool> hasRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    final formattedDate = _formatDate(date);

    try {
      // Devam kayıtlarını kontrol et
      final attendanceResults = await supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      if (attendanceResults.isNotEmpty) {
        return true;
      }

      // Ödeme kayıtlarını kontrol et
      final paymentResults = await supabase
          .from('paid_days')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      return paymentResults.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Belirlenen tarihten önce olan tüm kayıtları sil
  Future<void> deleteRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final formattedDate = _formatDate(date);

    try {
      // 1. Önce devam kayıtlarını sil
      await supabase
          .from('attendance')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      // 2. Ödemesi yapılmış günleri sil
      await supabase
          .from('paid_days')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      // 3. Belirli tarihten önceki ödeme kayıtlarını sil
      await supabase
          .from('payments')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('payment_date', formattedDate);

      // 4. Sahipsiz ödeme kayıtlarını sil
      await _deleteOrphanedPayments(userId, workerId);

      // 5. Kalan ödemeleri güncelle
      await _updateRemainingPayments(userId, workerId);
    } catch (e) {
      // ignore
    }
  }

  // Sahipsiz ödeme kayıtlarını silen yardımcı metod
  Future<void> _deleteOrphanedPayments(int userId, int workerId) async {
    try {
      final orphanedPayments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      if (orphanedPayments.isEmpty) return;

      List<int> paymentIds = orphanedPayments
          .map<int>((p) => p['id'] as int)
          .toList();

      for (final paymentId in paymentIds) {
        final paidDays = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .limit(1);

        if (paidDays.isEmpty) {
          await supabase.from('payments').delete().eq('id', paymentId);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  // Kalan ödemelerin gün sayılarını güncelleyen yardımcı metod
  Future<void> _updateRemainingPayments(int userId, int workerId) async {
    try {
      final payments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        final fullDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'fullDay');

        final fullDays = fullDaysResult.length;

        final halfDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'halfDay');

        final halfDays = halfDaysResult.length;

        await supabase
            .from('payments')
            .update({'full_days': fullDays, 'half_days': halfDays})
            .eq('id', paymentId);
      }
    } catch (e) {
      // ignore
    }
  }
}
