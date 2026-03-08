import 'package:flutter/foundation.dart';

/// Kullanıcı verilerini tutan global notifier
final ValueNotifier<Map<String, dynamic>?> userDataNotifier =
    ValueNotifier<Map<String, dynamic>?>(null);
