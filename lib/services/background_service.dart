import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  
  final MethodChannel _channel = const MethodChannel('com.example.puantaj/background_service');
  final NotificationService _notificationService = NotificationService();
  
  BackgroundService._internal();
  
  // Arka plan servisini başlat
  Future<void> startBackgroundService() async {
    try {
      if (Platform.isAndroid) {
        final String? result = await _channel.invokeMethod('startBackgroundService');
        print('Arka plan servisi başlatıldı: $result');
      }
      
      // Bildirimleri yeniden zamanla
      await _notificationService.checkAndRescheduleNotifications();
      
    } catch (e) {
      print('Arka plan servisi başlatılırken hata: $e');
    }
  }
  
  // Uygulama açıldığında bildirimleri kontrol et
  Future<void> checkNotificationsOnAppStart() async {
    try {
      await _notificationService.checkAndRescheduleNotifications();
    } catch (e) {
      print('Bildirimler kontrol edilirken hata: $e');
    }
  }
  
  // Uygulama kapatıldığında bildirimleri koru
  Future<void> preserveNotificationsOnAppClose() async {
    try {
      // Mevcut zamanlanmış bildirimleri kontrol et
      final pendingNotifications = await _notificationService.getPendingNotifications();
      print('Uygulama kapatılırken mevcut bildirim sayısı: ${pendingNotifications.length}');
      
      // Burada bildirimlerin korunması için gerekli işlemler yapılabilir
      
    } catch (e) {
      print('Bildirimler korunurken hata: $e');
    }
  }
} 