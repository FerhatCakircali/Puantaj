# Bildirim Sistemi Dokümantasyonu

## Genel Bakış

Bu bildirim sistemi, Flutter Local Notifications kullanarak yevmiye hatırlatıcıları ve çalışan hatırlatıcıları için güvenilir, modüler ve bakımı kolay bir altyapı sağlar.

## Mimari

Sistem, **Mixin-based Architecture** kullanarak Single Responsibility prensibine uygun şekilde tasarlanmıştır. Her mixin tek bir sorumluluğa sahiptir ve bağımsız olarak test edilebilir.

### Bileşenler

```
lib/services/notification/
├── notification_service.dart          # Ana orchestrator servis
├── notification_payload.dart          # Payload model sınıfı
├── notification_constants.dart        # Sabitler (ID'ler, kanallar)
├── index.dart                         # Barrel export dosyası
├── mixins/
│   ├── notification_channel_mixin.dart      # Kanal yönetimi
│   ├── notification_permission_mixin.dart   # İzin yönetimi
│   ├── notification_scheduling_mixin.dart   # Zamanlama işlemleri
│   ├── notification_payload_mixin.dart      # Payload işleme
│   ├── notification_routing_mixin.dart      # Yönlendirme işlemleri
│   ├── notification_display_mixin.dart      # Bildirim gösterimi
│   ├── notification_helper_mixin.dart       # Yardımcı metodlar
│   └── notification_settings_mixin.dart     # Ayarlar yönetimi
└── helpers/
    └── timezone_helper.dart           # Timezone dönüşüm helper'ı
```

## Kullanım

### 1. Servis Başlatma

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Notification service'i başlat
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(MyApp());
}
```

### 2. Yevmiye Hatırlatıcısı Zamanlama

```dart
final notificationService = NotificationService();

// Kullanıcı bilgilerini al
final userId = await authService.getUserId();
final username = await authService.getUsername();
final fullName = await authService.getFullName();

// Hatırlatıcıyı zamanla (her gün saat 17:00)
await notificationService.scheduleAttendanceReminder(
  userId: userId!,
  username: username!,
  fullName: fullName!,
  time: const TimeOfDay(hour: 17, minute: 0),
);
```

### 3. Çalışan Hatırlatıcısı Zamanlama

```dart
final notificationService = NotificationService();

// Hatırlatıcıyı zamanla
await notificationService.scheduleEmployeeReminder(
  reminderId: 123,
  userId: userId,
  username: username,
  fullName: fullName,
  workerName: 'Ahmet Yılmaz',
  message: 'Ahmet Yılmaz\'ın doğum günü',
  reminderDate: DateTime(2024, 12, 25, 9, 0),
);
```

### 4. Bildirim İptal Etme

```dart
// Tek bir bildirimi iptal et
await notificationService.cancelNotification(notificationId);

// Tüm bildirimleri iptal et
await notificationService.cancelAllNotifications();
```

### 5. Bildirim Yönlendirmesi

```dart
// Uygulama açıldığında bekleyen bildirimleri kontrol et
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _checkPendingNotifications();
  }
  
  Future<void> _checkPendingNotifications() async {
    final notificationService = NotificationService();
    await notificationService.checkAndHandlePendingNotification(context);
  }
}
```

## Timezone Yönetimi

Sistem, timezone-aware bildirimler için `TimezoneHelper` sınıfını kullanır.

### Temel Kullanım

```dart
final timezoneHelper = TimezoneHelper();

// Şu anki zaman (Istanbul timezone)
final now = timezoneHelper.nowInIstanbul();

// Bugün saat 17:00
final reminderTime = timezoneHelper.todayAt(17, 0);

// Yarın saat 09:00
final tomorrowMorning = timezoneHelper.tomorrowAt(9, 0);

// DateTime'ı TZDateTime'a çevir
final tzDateTime = timezoneHelper.toTZDateTime(DateTime.now());

// Geçmiş tarih kontrolü
if (timezoneHelper.isPast(someDateTime)) {
  print('Bu tarih geçmişte');
}

// Gelecek tarih kontrolü
if (timezoneHelper.isFuture(someDateTime)) {
  print('Bu tarih gelecekte');
}
```

### İleri Seviye Kullanım

```dart
// Özel timezone ile çalışma
final londonTime = timezoneHelper.toTZDateTimeWithTimezone(
  DateTime.now(),
  'Europe/London',
);

// Günün başlangıcı ve sonu
final startOfDay = timezoneHelper.startOfDay();
final endOfDay = timezoneHelper.endOfDay();

// İki tarih arasındaki fark
final difference = timezoneHelper.difference(start, end);
print('${difference.inHours} saat fark var');

// Formatlanmış string
final formatted = timezoneHelper.format(tzDateTime);
// Çıktı: "2024-01-15 14:30:00 Europe/Istanbul"
```

## Hata Yönetimi

Sistem, merkezi hata yönetimi için `ErrorHandler` sınıfını kullanır.

### Hata Loglama

```dart
try {
  // Riskli işlem
  await someOperation();
} catch (e, stack) {
  ErrorHandler.logError('OperationName', e, stack, {
    'userId': userId,
    'additionalInfo': 'some value',
  });
}
```

### Bilgi ve Uyarı Loglama

```dart
// Bilgi loglama
ErrorHandler.logInfo('ServiceName', 'İşlem başarılı', {
  'recordCount': 10,
});

// Uyarı loglama
ErrorHandler.logWarning('ServiceName', 'Dikkat edilmesi gereken durum');

// Başarı loglama
ErrorHandler.logSuccess('ServiceName', 'İşlem tamamlandı');

// Debug loglama (sadece debug modda)
ErrorHandler.logDebug('ServiceName', 'Debug bilgisi', {
  'variable': value,
});
```

### Güvenli İşlem Yürütme

```dart
// Senkron işlem
final result = ErrorHandler.safeExecute(
  () => riskyOperation(),
  fallbackValue,
  'OperationContext',
);

// Asenkron işlem
final result = await ErrorHandler.safeExecuteAsync(
  () async => await riskyAsyncOperation(),
  fallbackValue,
  'OperationContext',
);
```

### Kullanıcı Dostu Hata Mesajları

```dart
try {
  await someOperation();
} catch (e) {
  final userMessage = ErrorHandler.getUserFriendlyMessage(e);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Hata'),
      content: Text(userMessage),
    ),
  );
}
```

## Payload Yapısı

### NotificationPayload Model

```dart
class NotificationPayload {
  final NotificationType type;
  final int userId;
  final String username;
  final String fullName;
  final int? reminderId;  // Sadece çalışan hatırlatıcıları için
  
  // JSON'a çevirme
  String toJson();
  
  // JSON'dan oluşturma
  static NotificationPayload? fromJson(String jsonString);
}
```

### Bildirim Tipleri

```dart
enum NotificationType {
  attendanceReminder,   // Yevmiye hatırlatıcısı
  employeeReminder,     // Çalışan hatırlatıcısı
}
```

### Örnek Payload

```json
{
  "type": "employeeReminder",
  "userId": 1,
  "username": "john_doe",
  "fullName": "John Doe",
  "reminderId": 123
}
```

## Bildirim Kanalları (Android)

### Kanal Tipleri

1. **attendance_reminder**: Yevmiye hatırlatıcıları
   - Önem: Maksimum
   - Ses: Etkin
   - Titreşim: Etkin

2. **employee_reminders**: Çalışan hatırlatıcıları
   - Önem: Maksimum
   - Ses: Etkin
   - Titreşim: Etkin

3. **xiaomi_high_importance_channel**: Xiaomi cihazlar için özel kanal
   - Önem: Maksimum
   - Işık: Etkin
   - Ses: Etkin
   - Titreşim: Etkin

## İzinler

### Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### iOS

```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### İzin Kontrolü

```dart
final notificationService = NotificationService();

// İzinleri kontrol et ve gerekirse iste
final hasPermission = await notificationService.checkAndRequestPermissions();

if (!hasPermission) {
  // Kullanıcıya bilgi ver
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('İzin Gerekli'),
      content: Text('Bildirimler için izin vermeniz gerekiyor.'),
    ),
  );
}
```

## Test

### Unit Test Örneği

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:puantaj/models/notification_payload.dart';

void main() {
  group('NotificationPayload', () {
    test('toJson() doğru JSON üretmeli', () {
      final payload = NotificationPayload(
        type: NotificationType.attendanceReminder,
        userId: 1,
        username: 'test',
        fullName: 'Test User',
      );
      
      final json = payload.toJson();
      expect(json, contains('attendanceReminder'));
      expect(json, contains('test'));
    });
  });
}
```

### Integration Test Örneği

```dart
testWidgets('Bildirim yönlendirmesi çalışmalı', (tester) async {
  // Arrange
  SharedPreferences.setMockInitialValues({
    'has_pending_notification': true,
    'notification_type': 'attendanceReminder',
  });
  
  // Act
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Yevmiye'), findsOneWidget);
});
```

## Sorun Giderme

### Bildirimler Gösterilmiyor

1. **İzinleri kontrol edin**
   ```dart
   final hasPermission = await notificationService.checkAndRequestPermissions();
   ```

2. **Kanal ayarlarını kontrol edin** (Android)
   - Ayarlar > Uygulamalar > Puantaj > Bildirimler
   - Tüm kanalların etkin olduğundan emin olun

3. **Timezone ayarlarını kontrol edin**
   ```dart
   final now = timezoneHelper.nowInIstanbul();
   print('Şu anki zaman: ${timezoneHelper.format(now)}');
   ```

### Bildirimler Geç Gösteriliyor

1. **Batarya optimizasyonunu kapatın** (Android)
   - Ayarlar > Batarya > Batarya optimizasyonu
   - Puantaj uygulamasını "Optimize edilmeyen" listesine ekleyin

2. **Xiaomi cihazlarda ek ayarlar**
   - Ayarlar > Uygulamalar > Puantaj
   - "Otomatik başlatma" etkinleştirin
   - "Arka planda çalışma" etkinleştirin

### Yönlendirme Çalışmıyor

1. **Routing bilgisini kontrol edin**
   ```dart
   final prefs = await SharedPreferences.getInstance();
   final hasPending = prefs.getBool('has_pending_notification');
   print('Bekleyen bildirim: $hasPending');
   ```

2. **Route tanımlarını kontrol edin**
   ```dart
   // Router'da route tanımlı mı?
   '/attendance': (context) => AttendanceScreen(),
   '/employee-reminder-detail': (context) => ReminderDetailScreen(),
   ```

## En İyi Uygulamalar

### 1. Timezone Kullanımı

✅ **Doğru:**
```dart
final tzDateTime = timezoneHelper.toTZDateTime(dateTime);
await notificationService.scheduleNotification(tzDateTime);
```

❌ **Yanlış:**
```dart
// DateTime kullanmayın, TZDateTime kullanın
await notificationService.scheduleNotification(DateTime.now());
```

### 2. Hata Yönetimi

✅ **Doğru:**
```dart
try {
  await notificationService.scheduleNotification(...);
} catch (e, stack) {
  ErrorHandler.logError('ScheduleNotification', e, stack);
  // Kullanıcıya bilgi ver
}
```

❌ **Yanlış:**
```dart
// Hataları yakalamadan bırakmayın
await notificationService.scheduleNotification(...);
```

### 3. Context Kontrolü

✅ **Doğru:**
```dart
if (context.mounted) {
  await notificationService.checkAndHandlePendingNotification(context);
}
```

❌ **Yanlış:**
```dart
// Context kontrolü yapmadan kullanmayın
await notificationService.checkAndHandlePendingNotification(context);
```

### 4. Bildirim İptali

✅ **Doğru:**
```dart
// Kullanıcı işlemi tamamladığında bildirimi iptal et
await notificationService.cancelNotification(notificationId);
```

❌ **Yanlış:**
```dart
// Bildirimleri iptal etmeyi unutmayın
// Gereksiz bildirimler kullanıcı deneyimini bozar
```

## Performans İpuçları

1. **Lazy Initialization**: Servisleri sadece gerektiğinde başlatın
2. **Batch Operations**: Çoklu bildirimleri toplu olarak zamanlayın
3. **Caching**: Kullanıcı bilgilerini cache'leyin
4. **Debouncing**: Hızlı ardışık işlemleri engelleyin

## Güvenlik

1. **Payload Validation**: Tüm payload'ları doğrulayın
2. **User Context**: Sadece ilgili kullanıcının bildirimlerini gösterin
3. **Permission Checks**: Her işlemde izinleri kontrol edin
4. **Error Handling**: Hassas bilgileri loglarda göstermeyin

## Katkıda Bulunma

Yeni özellik eklerken:

1. Mixin-based mimariyi koruyun
2. Single Responsibility prensibine uyun
3. Kapsamlı testler yazın
4. Dokümantasyonu güncelleyin
5. ErrorHandler kullanarak hata yönetimi yapın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
