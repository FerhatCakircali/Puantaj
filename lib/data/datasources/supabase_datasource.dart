import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';

/// Supabase data source interface
///
/// Defines contract for Supabase database operations.
abstract class SupabaseDataSource {
  /// Query single record from table
  Future<Map<String, dynamic>?> query(
    String table,
    Map<String, dynamic> filters,
  );

  /// Query multiple records from table
  Future<List<Map<String, dynamic>>> queryList(
    String table, {
    Map<String, dynamic>? filters,
  });

  /// Insert record into table
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data);

  /// Update record in table
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  );

  /// Delete record from table
  Future<void> delete(String table, String id);

  /// Get Supabase client for complex queries
  SupabaseClient get client;
}

/// Supabase data source implementation
///
/// Wraps SupabaseService to provide data source abstraction.
class SupabaseDataSourceImpl implements SupabaseDataSource {
  final SupabaseService _supabaseService;

  SupabaseDataSourceImpl(this._supabaseService);

  @override
  SupabaseClient get client => _supabaseService.client;

  @override
  Future<Map<String, dynamic>?> query(
    String table,
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = client.from(table).select();

      // Apply filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Query failed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryList(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = client.from(table).select();

      // Apply filters if provided
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Query list failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Insert failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}
