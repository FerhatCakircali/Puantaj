import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'dart:developer';

/// AppDatabase sınıfı, veritabanı işlemlerini Supabase üzerinden yönetir.
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  final SupabaseClient _supabase = supabase;

  /// Supabase istemcisine erişim için getter
  SupabaseClient get database => _supabase;

  /// Supabase istemcisine erişim için alternatif metot
  Future<SupabaseClient> get client async => _supabase;

  /// Kullanıcı tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getUsers({
    String? whereField,
    dynamic whereValue,
    String? orderBy,
    bool descending = false,
  }) async {
    final query = _supabase.from('users').select();

    if (whereField != null && whereValue != null) {
      final filtered = query.eq(whereField, whereValue);

      if (orderBy != null) {
        final data = await filtered.order(orderBy, ascending: !descending);
        return List<Map<String, dynamic>>.from(data);
      }

      final data = await filtered;
      return List<Map<String, dynamic>>.from(data);
    }

    if (orderBy != null) {
      final data = await query.order(orderBy, ascending: !descending);
      return List<Map<String, dynamic>>.from(data);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Çalışan tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getWorkers({
    int? userId,
    int? workerId,
    String? orderBy,
    bool descending = false,
  }) async {
    final query = _supabase.from('workers').select();
    var filtered = query;

    if (userId != null) {
      filtered = filtered.eq('user_id', userId);
    }

    if (workerId != null) {
      filtered = filtered.eq('id', workerId);
    }

    if (orderBy != null) {
      final data = await filtered.order(orderBy, ascending: !descending);
      return List<Map<String, dynamic>>.from(data);
    } else {
      final data = await filtered.order('full_name');
      return List<Map<String, dynamic>>.from(data);
    }
  }

  /// Devam durumu tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getAttendance({
    int? userId,
    int? workerId,
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final query = _supabase.from('attendance').select();
    var filtered = query;

    if (userId != null) {
      filtered = filtered.eq('user_id', userId);
    }

    if (workerId != null) {
      filtered = filtered.eq('worker_id', workerId);
    }

    if (date != null) {
      filtered = filtered.like('date', '$date%');
    }

    if (startDate != null && endDate != null) {
      filtered = filtered.gte('date', startDate).lte('date', endDate);
    }

    final data = await filtered;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Ödeme tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getPayments({
    int? userId,
    int? workerId,
    String? paymentDate,
    String? beforeDate,
    String? afterDate,
    bool descending = true,
  }) async {
    final query = _supabase.from('payments').select();
    var filtered = query;

    if (userId != null) {
      filtered = filtered.eq('user_id', userId);
    }

    if (workerId != null) {
      filtered = filtered.eq('worker_id', workerId);
    }

    if (paymentDate != null) {
      filtered = filtered.eq('payment_date', paymentDate);
    }

    if (beforeDate != null) {
      filtered = filtered.lt('payment_date', beforeDate);
    }

    if (afterDate != null) {
      filtered = filtered.gt('payment_date', afterDate);
    }

    final data = await filtered.order('payment_date', ascending: !descending);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Ödenen günler tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getPaidDays({
    int? userId,
    int? workerId,
    int? paymentId,
  }) async {
    final query = _supabase.from('paid_days').select();
    var filtered = query;

    if (userId != null) {
      filtered = filtered.eq('user_id', userId);
    }

    if (workerId != null) {
      filtered = filtered.eq('worker_id', workerId);
    }

    if (paymentId != null) {
      filtered = filtered.eq('payment_id', paymentId);
    }

    final data = await filtered;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Bildirim ayarları tablosundan sorgu yapar
  Future<List<Map<String, dynamic>>> getNotificationSettings(int userId) async {
    final data = await _supabase
        .from('notification_settings')
        .select()
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Veri ekler
  Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      print('Tablo: $table - Veri ekleniyor: $values');
      final response =
          await _supabase.from(table).insert(values).select('id').single();

      final id = response['id'] as int;
      print('Veri başarıyla eklendi, ID: $id');
      return id;
    } catch (e, stack) {
      logError('Veri eklenirken hata oluştu', e, stack);

      if (e is PostgrestException) {
        print(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );

        if (e.code == '42P01') {
          // Tablo bulunamadı
          print('HATA: $table tablosu bulunamadı');
        } else if (e.code == '23505') {
          // Unique constraint violation
          print('HATA: Benzersizlik kısıtlaması ihlali');
        }
      }

      // 2xx kodu dönen fakat response body boş olan durumlar için
      // ID'yi alamadığımız durumlarda -1 döndürüyoruz
      return -1;
    }
  }

  /// Veri günceller
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String idField,
    required dynamic idValue,
    String? additionalField,
    dynamic additionalValue,
  }) async {
    try {
      print('Tablo: $table - Veri güncelleniyor: $values, $idField=$idValue');
      final query = _supabase.from(table).update(values);
      var filtered = query.eq(idField, idValue);

      if (additionalField != null && additionalValue != null) {
        filtered = filtered.eq(additionalField, additionalValue);
      }

      await filtered;
      print('Veri başarıyla güncellendi');
      return 1; // Supabase affected rows döndürmediği için varsayılan 1
    } catch (e, stack) {
      logError('Veri güncellenirken hata oluştu', e, stack);

      if (e is PostgrestException) {
        print(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );
      }

      return 0;
    }
  }

  /// Veri siler
  Future<int> delete(
    String table, {
    required String idField,
    required dynamic idValue,
    String? additionalField,
    dynamic additionalValue,
  }) async {
    try {
      print('Tablo: $table - Veri siliniyor: $idField=$idValue');
      final query = _supabase.from(table).delete();
      var filtered = query.eq(idField, idValue);

      if (additionalField != null && additionalValue != null) {
        filtered = filtered.eq(additionalField, additionalValue);
      }

      await filtered;
      print('Veri başarıyla silindi');
      return 1; // Supabase affected rows döndürmediği için varsayılan 1
    } catch (e, stack) {
      logError('Veri silinirken hata oluştu', e, stack);

      if (e is PostgrestException) {
        print(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );
      }

      return 0;
    }
  }

  /// Bir tablodaki tüm kayıtların sayısını döndürür
  Future<int> getCount(
    String table, {
    String? whereField,
    dynamic whereValue,
  }) async {
    final result = await _supabase.rpc(
      'count_records',
      params: {
        'table_name': table,
        'where_field': whereField,
        'where_value': whereValue,
      },
    );

    return result ?? 0;
  }

  /// Birden fazla koşulla sayım yapar (PostgreSQL stored procedure kullanır)
  Future<int> getCountWithMultipleConditions(
    String table,
    Map<String, dynamic> conditions,
  ) async {
    final result = await _supabase.rpc(
      'count_records_multiple',
      params: {'table_name': table, 'conditions': conditions},
    );

    return result ?? 0;
  }

  /// Compatibility - SQLite bağlantısını kapat
  Future<void> close() async {
    // Supabase client'ı kapatmak gerekmez
  }

  /// Compatibility - SQLite bağlantısını yeniden aç
  Future<void> reopen() async {
    // Supabase client'ı yeniden açmak gerekmez
  }
}
