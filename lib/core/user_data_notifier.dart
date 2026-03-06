import 'package:flutter/foundation.dart';

/// ⚠️ DEPRECATED: Bu ValueNotifier artık kullanılmamalı
///
/// Service katmanı (auth_login_mixin, app_bootstrap) hala bu notifier'ı kullanıyor
/// ancak UI katmanı UserDataProvider (Riverpod) kullanmalı.
///
/// main.dart'ta otomatik senkronizasyon yapılıyor:
/// userDataNotifier → userDataProvider
///
/// **Gelecek:** Service katmanı da Riverpod'a geçirildiğinde bu dosya silinecek.
@Deprecated('Use UserDataProvider instead')
final ValueNotifier<Map<String, dynamic>?> userDataNotifier =
    ValueNotifier<Map<String, dynamic>?>(null);
