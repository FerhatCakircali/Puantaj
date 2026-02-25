import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/services/mixins/auth_login_mixin.dart';
import '../features/auth/services/mixins/auth_register_mixin.dart';
import '../features/auth/services/mixins/auth_token_mixin.dart';

class AuthService with AuthLoginMixin, AuthRegisterMixin, AuthTokenMixin {
  // Supabase client getter
  SupabaseClient get supabase => Supabase.instance.client;

  // currentUser getter - AuthLoginMixin'den loadCurrentUser kullanır
  Future<Map<String, dynamic>?> get currentUser async => loadCurrentUser();

  // ValueNotifier for auth state
  ValueNotifier<bool> get authStateNotifier => ValueNotifier<bool>(false);

  // Error logging
  void logError(String message, dynamic error, StackTrace? stackTrace) {
    debugPrint('Error: $message');
    debugPrint('Details: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
