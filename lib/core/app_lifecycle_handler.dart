import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'error_handler.dart';

/// Uygulama yaşam döngüsü olaylarını izlemek için yardımcı sınıf
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? resumeCallBack;
  final Future<void> Function()? suspendingCallBack;

  LifecycleEventHandler({this.resumeCallBack, this.suspendingCallBack});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack!();
        }
        // Uygulama ön plana geldiğinde bozuk durumları temizle
        try {
          final notificationService = NotificationService();
          await notificationService.clearPendingNotification();
          ErrorHandler.logSuccess(
            'LifecycleEventHandler',
            'Pending notification temizlendi',
          );
        } catch (e, stack) {
          ErrorHandler.logError('LifecycleEventHandler.resumed', e, stack);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (suspendingCallBack != null) {
          await suspendingCallBack!();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (suspendingCallBack != null) {
          await suspendingCallBack!();
        }
        break;
    }
  }
}
