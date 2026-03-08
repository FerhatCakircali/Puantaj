import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_repository_mixin.dart';

/// Supabase kullanan tüm repository'ler için base class
///
/// Supabase client'ı DI'dan alır ve ortak error handling sağlar
abstract class BaseSupabaseRepository with BaseRepositoryMixin {
  final SupabaseClient _supabase;

  BaseSupabaseRepository(this._supabase);

  /// Supabase client getter
  SupabaseClient get supabase => _supabase;
}
