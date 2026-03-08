import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email gönderme işlemlerini yöneten sınıf
class EmailSender {
  final _supabase = Supabase.instance.client;

  /// Supabase Edge Function ile email gönderir
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {'to': to, 'subject': subject, 'html': html},
      );

      if (response.status == 200) {
        debugPrint('Email başarıyla gönderildi: $to');
        return true;
      } else {
        debugPrint('Email gönderme hatası: ${response.status}');
        debugPrint('Response: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('Email gönderme exception: $e');
      return false;
    }
  }
}
