import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SessionManager {
  static const String _lastActiveKey = 'last_active_time';
  static const String _sessionTimeoutKey = 'session_timeout_minutes';
  static const int _defaultTimeoutMinutes = 30;

  Timer? _timer;
  VoidCallback? onSessionTimeout;

  Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> setSessionTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionTimeoutKey, minutes);
  }

  Future<int> getSessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionTimeoutKey) ?? _defaultTimeoutMinutes;
  }

  void startSessionTimer(VoidCallback onTimeout) async {
    onSessionTimeout = onTimeout;
    _timer?.cancel();
    final timeout = await getSessionTimeout();
    _timer = Timer(Duration(minutes: timeout), () {
      onSessionTimeout?.call();
    });
  }

  void stopSessionTimer() {
    _timer?.cancel();
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_lastActiveKey);
    if (lastActive == null) return true;
    final timeout = await getSessionTimeout();
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - lastActive > timeout * 60 * 1000;
  }

  Future<void> resetSession() async {
    await updateLastActive();
    stopSessionTimer();
  }

  // Şifre sıfırlama için örnek fonksiyon (gerçek uygulamada backend ile entegre edilmeli)
  Future<bool> resetPassword(String email) async {
    // TODO: Backend API ile entegre et
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
