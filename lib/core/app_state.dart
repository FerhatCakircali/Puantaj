import 'package:flutter/material.dart';

/// Uygulama durumunu tutan sınıf
///
/// Theme mode ve authentication durumunu birleştirir.
/// Bu sayede iç içe ValueListenableBuilder kullanımı önlenir.
class AppState {
  final ThemeMode themeMode;
  final bool isAuthenticated;

  const AppState({required this.themeMode, required this.isAuthenticated});

  AppState copyWith({ThemeMode? themeMode, bool? isAuthenticated}) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.themeMode == themeMode &&
        other.isAuthenticated == isAuthenticated;
  }

  @override
  int get hashCode => Object.hash(themeMode, isAuthenticated);
}
