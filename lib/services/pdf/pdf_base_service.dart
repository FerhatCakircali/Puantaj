import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../pdf/pdf_report_utils.dart';

class PdfBaseService {
  static final PdfBaseService _instance = PdfBaseService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  late pw.Font baseFont;
  late pw.Font boldFont;
  late pw.ThemeData pdfTheme;
  bool fontsLoaded = false;

  factory PdfBaseService() {
    return _instance;
  }

  PdfBaseService._internal();

  Future<void> loadFonts() async {
    if (fontsLoaded) return;
    try {
      baseFont = await pw.Font.ttf(
        await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
      );
      boldFont = await pw.Font.ttf(
        await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
      );
      pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
      PdfReportUtils.robotoFont = baseFont;
      PdfReportUtils.robotoBoldFont = boldFont;
      PdfReportUtils.robotoTheme = pdfTheme;
      fontsLoaded = true;
    } catch (e) {
      fontsLoaded = false;
    }
  }

  Future<void> initializeNotifications() async {
    if (_notificationsInitialized) return;
    try {
      final AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            openPdf(File(response.payload!));
          }
        },
      );
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      _notificationsInitialized = true;
    } catch (e) {
      _notificationsInitialized = false;
    }
  }

  Future<File> saveFileToDownloads(String filename, Uint8List data) async {
    try {
      final storagePermission = await _requestStoragePermission();
      if (!storagePermission) {
        throw Exception("Depolama izni verilmedi!");
      }
      String? downloadPath = await _findDownloadPath();
      if (downloadPath == null) {
        throw Exception("İndirilenler klasörü bulunamadı!");
      }
      final filePath = '$downloadPath/$filename';
      final file = File(filePath);
      await file.writeAsBytes(data);
      if (await file.exists()) {
        return file;
      } else {
        throw Exception("Dosya kaydedildi ancak doğrulanamadı!");
      }
    } catch (e) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(data);
      return file;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<String?> _findDownloadPath() async {
    if (Platform.isAndroid) {
      try {
        Directory? directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory.path;
        }
        directory = Directory('/sdcard/Download');
        if (await directory.exists()) {
          return directory.path;
        }
        directory = Directory('/storage/self/primary/Download');
        if (await directory.exists()) {
          return directory.path;
        }
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          String newPath = "";
          List<String> paths = directory.path.split("/");
          for (int i = 1; i < paths.length; i++) {
            String folder = paths[i];
            if (folder != "Android") {
              newPath += "/$folder";
            } else {
              break;
            }
          }
          newPath += "/Download";
          directory = Directory(newPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory.path;
        }
      } catch (e) {}
    }
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> showNotification(String title, String payload) async {
    if (!_notificationsInitialized) {
      await initializeNotifications();
    }
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pdf_channel',
          'PDF Bildirimleri',
          channelDescription: 'PDF oluşturma işlemleri hakkında bildirimler',
          importance: Importance.max,
          priority: Priority.high,
        );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      payload,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> openPdf(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {}
  }
}
