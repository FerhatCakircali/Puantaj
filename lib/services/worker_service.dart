import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/worker.dart';
import 'auth_service.dart';

class WorkerService {
  final AuthService _authService = AuthService();

  // Tüm çalışanları getir
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
      debugPrint('Çalışanlar alınırken hata: $e');
      return [];
    }
  }
  
  // ID'ye göre çalışan getir
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
      debugPrint('Çalışan alınırken hata: $e');
      return null;
    }
  }
  
  // Çalışan ekle
  Future<Worker?> addWorker(Worker worker) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Çalışanı veritabanına ekle
      final data = await supabase
          .from('workers')
          .insert(worker.toMap())
          .select()
          .single();
      
      return Worker.fromMap(data);
    } catch (e) {
      debugPrint('Çalışan eklenirken hata: $e');
      return null;
    }
  }
  
  // Çalışan güncelle
  Future<bool> updateWorker(Worker worker) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Çalışanı veritabanında güncelle
      await supabase
          .from('workers')
          .update(worker.toMap())
          .eq('id', worker.id!)
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Çalışan güncellenirken hata: $e');
      return false;
    }
  }
  
  // Çalışan sil
  Future<bool> deleteWorker(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Çalışanı veritabanından sil
      await supabase
          .from('workers')
          .delete()
          .eq('id', workerId)
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Çalışan silinirken hata: $e');
      return false;
    }
  }
  
  // İsme göre çalışan ara
  Future<List<Worker>> searchWorkers(String query) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Çalışanları isimlerine göre ara
      final List<dynamic> data = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .ilike('full_name', '%$query%')
          .order('full_name', ascending: true);
      
      return data.map((worker) => Worker.fromMap(worker)).toList();
    } catch (e) {
      debugPrint('Çalışanlar aranırken hata: $e');
      return [];
    }
  }
} 