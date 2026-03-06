import 'package:credential_manager/credential_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Login credential management mixin
/// Handles remember me, credential saving, and auto-fill
mixin LoginCredentialMixin<T extends StatefulWidget> on State<T> {
  // Credential Manager (not supported on web)
  CredentialManager? _credentialManager;

  // Remember me states
  bool _rememberMe = false;
  bool _workerRememberMe = false;

  bool get rememberMe => _rememberMe;
  bool get workerRememberMe => _workerRememberMe;

  // Storage keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';
  static const String _workerRememberMeKey = 'worker_remember_me';
  static const String _workerSavedUsernameKey = 'worker_saved_username';
  static const String _workerSavedPasswordKey = 'worker_saved_password';

  /// Initialize credential manager
  Future<void> initializeCredentialManager() async {
    if (kIsWeb) return;

    _credentialManager = CredentialManager();
    if (_credentialManager?.isSupportedPlatform == true) {
      await _credentialManager!.init(
        preferImmediatelyAvailableCredentials: true,
      );
    }
  }

  /// Load saved credentials for both admin and worker
  Future<void> loadSavedCredentials({
    required TextEditingController adminUsernameController,
    required TextEditingController adminPasswordController,
    required TextEditingController workerUsernameController,
    required TextEditingController workerPasswordController,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Admin credentials
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (rememberMe) {
      final savedUsername = prefs.getString(_savedUsernameKey) ?? '';
      final savedPassword = prefs.getString(_savedPasswordKey) ?? '';
      adminUsernameController.text = savedUsername;
      adminPasswordController.text = savedPassword;
    }

    // Worker credentials
    final workerRememberMe = prefs.getBool(_workerRememberMeKey) ?? false;
    if (workerRememberMe) {
      final savedUsername = prefs.getString(_workerSavedUsernameKey) ?? '';
      final savedPassword = prefs.getString(_workerSavedPasswordKey) ?? '';
      workerUsernameController.text = savedUsername;
      workerPasswordController.text = savedPassword;
    }

    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        _workerRememberMe = workerRememberMe;
      });
    }
  }

  /// Save admin credentials
  Future<void> saveAdminCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_savedUsernameKey, username);
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedUsernameKey);
      await prefs.remove(_savedPasswordKey);
    }
    await prefs.setBool(_rememberMeKey, _rememberMe);

    // Save to credential manager (if supported)
    try {
      if (!kIsWeb && _credentialManager?.isSupportedPlatform == true) {
        final passwordCredential = PasswordCredential(
          username: username,
          password: password,
        );
        await _credentialManager!.savePasswordCredentials(passwordCredential);
      }
    } catch (e) {
      debugPrint('CredentialManager ile şifre kaydetme hatası: $e');
    }
  }

  /// Save worker credentials
  Future<void> saveWorkerCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_workerRememberMe) {
      await prefs.setString(_workerSavedUsernameKey, username);
      await prefs.setString(_workerSavedPasswordKey, password);
    } else {
      await prefs.remove(_workerSavedUsernameKey);
      await prefs.remove(_workerSavedPasswordKey);
    }
    await prefs.setBool(_workerRememberMeKey, _workerRememberMe);
  }

  /// Toggle admin remember me
  void toggleAdminRememberMe() {
    if (mounted) {
      setState(() => _rememberMe = !_rememberMe);
    }
  }

  /// Toggle worker remember me
  void toggleWorkerRememberMe() {
    if (mounted) {
      setState(() => _workerRememberMe = !_workerRememberMe);
    }
  }
}
