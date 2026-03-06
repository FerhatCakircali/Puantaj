import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../controllers/auth/auth_controller.dart';
import '../controllers/home/home_controller.dart';
import '../controllers/employee/employee_controller.dart';
import '../controllers/attendance/attendance_controller.dart';

/// Provider tanımlamaları
/// Controller'lar için provider factory metodları.
/// DI container'dan instance'ları alır.

/// Auth controller provider
class AuthControllerProvider {
  static AuthController get instance {
    return InjectionContainer.instance.get<AuthController>();
  }
}

/// Home controller provider
class HomeControllerProvider {
  static HomeController get instance {
    return InjectionContainer.instance.get<HomeController>();
  }
}

/// Employee controller provider
class EmployeeControllerProvider {
  static EmployeeController get instance {
    return InjectionContainer.instance.get<EmployeeController>();
  }
}

/// Attendance controller provider
class AttendanceControllerProvider {
  static AttendanceController get instance {
    return InjectionContainer.instance.get<AttendanceController>();
  }
}

/// Provider helper - ChangeNotifierProvider benzeri kullanım için
class ControllerProvider<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const ControllerProvider({
    super.key,
    required T notifier,
    required super.child,
  }) : super(notifier: notifier);

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ControllerProvider<T>>();
    assert(provider != null, 'ControllerProvider<$T> not found in context');
    return provider!.notifier!;
  }
}
