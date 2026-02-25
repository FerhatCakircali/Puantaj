import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../services/pdf_service.dart';

/// Bildirim işlemleri mixin'i
mixin ReportControllerNotificationMixin<T extends StatefulWidget> on State<T> {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  final PdfService pdfService = PdfService();

  /// Bildirim göster
  Future<void> showReportNotification(File file, String title) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pdf_report_channel',
          'PDF Raporları',
          channelDescription: 'Oluşturulan PDF raporları için bildirimler',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      id: 0,
      title: title,
      body: 'Rapor hazır! Açmak için tıklayın.',
      notificationDetails: platformDetails,
      payload: file.path,
    );

    debugPrint('✅ ReportControllerMixin: Bildirim gösterildi');
  }

  /// Bildirimleri başlat
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          await pdfService.openPdf(File(payload));
        }
      },
    );

    debugPrint('✅ ReportControllerMixin: Bildirimler başlatıldı');
  }
}
