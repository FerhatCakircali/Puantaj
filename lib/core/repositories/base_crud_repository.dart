import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_repository_mixin.dart';

/// Generic CRUD işlemleri için base repository
/// Single Responsibility: Tekrarlı CRUD kodlarını tek yerden yönetir
abstract class BaseCrudRepository<T> with BaseRepositoryMixin {
  SupabaseClient get supabase => Supabase.instance.client;

  /// Tablo adı (alt sınıflar override etmeli)
  String get tableName;

  /// Model'den Map'e dönüşüm (alt sınıflar override etmeli)
  Map<String, dynamic> toMap(T entity);

  /// Map'ten Model'e dönüşüm (alt sınıflar override etmeli)
  T fromMap(Map<String, dynamic> map);

  /// ID field adı (varsayılan: 'id')
  String get idField => 'id';

  /// User ID field adı (varsayılan: 'user_id')
  String get userIdField => 'user_id';

  /// Tüm kayıtları getirir
  Future<List<T>> getAll(
    int userId, {
    String? orderBy,
    bool ascending = true,
  }) async {
    return executeQuery(
      () async {
        var query = supabase.from(tableName).select().eq(userIdField, userId);

        if (orderBy != null) {
          final results = await query.order(orderBy, ascending: ascending);
          return results.map<T>((map) => fromMap(map)).toList();
        }

        final results = await query;
        return results.map<T>((map) => fromMap(map)).toList();
      },
      [],
      context: '$runtimeType.getAll',
    );
  }

  /// ID'ye göre kayıt getirir
  Future<T?> getById(int id) async {
    return executeQuery(
      () async {
        final data = await supabase
            .from(tableName)
            .select()
            .eq(idField, id)
            .maybeSingle();

        return data != null ? fromMap(data) : null;
      },
      null,
      context: '$runtimeType.getById',
    );
  }

  /// Yeni kayıt ekler
  Future<int> add(T entity, int userId) async {
    return executeQuery(
      () async {
        final map = toMap(entity);
        map[userIdField] = userId;

        final result = await supabase
            .from(tableName)
            .insert(map)
            .select(idField)
            .single();

        return result[idField] as int;
      },
      -1,
      context: '$runtimeType.add',
    );
  }

  /// Kayıt günceller
  Future<bool> update(T entity, int? id, int userId) async {
    return executeQuery(
      () async {
        if (id == null) return false;

        await supabase
            .from(tableName)
            .update(toMap(entity))
            .eq(idField, id)
            .eq(userIdField, userId);

        return true;
      },
      false,
      context: '$runtimeType.update',
    );
  }

  /// Kayıt siler
  Future<bool> delete(int id, int userId) async {
    return executeQuery(
      () async {
        await supabase
            .from(tableName)
            .delete()
            .eq(idField, id)
            .eq(userIdField, userId);

        return true;
      },
      false,
      context: '$runtimeType.delete',
    );
  }

  /// Kullanıcıya ait tüm kayıtları siler
  Future<bool> deleteAll(int userId) async {
    return executeQuery(
      () async {
        await supabase.from(tableName).delete().eq(userIdField, userId);
        return true;
      },
      false,
      context: '$runtimeType.deleteAll',
    );
  }
}
