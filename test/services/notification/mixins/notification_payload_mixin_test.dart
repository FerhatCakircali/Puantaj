import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puantaj/models/notification_payload.dart';
import 'package:puantaj/services/notification/mixins/notification_payload_mixin.dart';

// Test için NotificationPayloadMixin'i kullanan basit bir sınıf
class TestNotificationService with NotificationPayloadMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPayloadMixin', () {
    late TestNotificationService service;

    setUp(() {
      service = TestNotificationService();
      SharedPreferences.setMockInitialValues({});
    });

    group('handleNotificationTap', () {
      test('null payload ile çağrıldığında hata vermemeli', () async {
        // Arrange & Act & Assert
        await expectLater(service.handleNotificationTap(null), completes);
      });

      test('boş payload ile çağrıldığında hata vermemeli', () async {
        // Arrange & Act & Assert
        await expectLater(service.handleNotificationTap(''), completes);
      });

      test('geçersiz JSON ile çağrıldığında hata vermemeli', () async {
        // Arrange & Act & Assert
        await expectLater(
          service.handleNotificationTap('invalid json'),
          completes,
        );
      });

      test('geçerli yevmiye hatırlatıcısı payload\'ını işlemeli', () async {
        // Arrange
        final payload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 1,
          username: 'testuser',
          fullName: 'Test User',
        );

        // Act
        await service.handleNotificationTap(payload.toJson());

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notification_type'), 'attendanceReminder');
        expect(prefs.getInt('notification_user_id'), 1);
        expect(prefs.getBool('has_pending_notification'), true);
        expect(prefs.getInt('notification_reminder_id'), null);
      });

      test('geçerli çalışan hatırlatıcısı payload\'ını işlemeli', () async {
        // Arrange
        final payload = NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 2,
          username: 'testuser2',
          fullName: 'Test User 2',
          reminderId: 123,
        );

        // Act
        await service.handleNotificationTap(payload.toJson());

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notification_type'), 'employeeReminder');
        expect(prefs.getInt('notification_user_id'), 2);
        expect(prefs.getInt('notification_reminder_id'), 123);
        expect(prefs.getBool('has_pending_notification'), true);
      });

      test('geçersiz userId ile payload\'ı reddetmeli', () async {
        // Arrange
        final invalidPayload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 0, // Geçersiz
          username: 'testuser',
          fullName: 'Test User',
        );

        // Act
        await service.handleNotificationTap(invalidPayload.toJson());

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), null);
      });

      test('boş username ile payload\'ı reddetmeli', () async {
        // Arrange
        final invalidPayload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 1,
          username: '', // Geçersiz
          fullName: 'Test User',
        );

        // Act
        await service.handleNotificationTap(invalidPayload.toJson());

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), null);
      });

      test('boş fullName ile payload\'ı reddetmeli', () async {
        // Arrange
        final invalidPayload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 1,
          username: 'testuser',
          fullName: '   ', // Geçersiz (sadece boşluk)
        );

        // Act
        await service.handleNotificationTap(invalidPayload.toJson());

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), null);
      });

      test(
        'çalışan hatırlatıcısında reminderId olmadan payload\'ı reddetmeli',
        () async {
          // Arrange
          final invalidPayload = NotificationPayload(
            type: NotificationType.employeeReminder,
            userId: 1,
            username: 'testuser',
            fullName: 'Test User',
            // reminderId yok - geçersiz
          );

          // Act
          await service.handleNotificationTap(invalidPayload.toJson());

          // Assert
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('has_pending_notification'), null);
        },
      );
    });

    group('saveRoutingInfo', () {
      test('yevmiye hatırlatıcısı için routing bilgisini kaydetmeli', () async {
        // Arrange
        final payload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 1,
          username: 'testuser',
          fullName: 'Test User',
        );

        // Act
        await service.saveRoutingInfo(payload);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notification_type'), 'attendanceReminder');
        expect(prefs.getInt('notification_user_id'), 1);
        expect(prefs.getBool('has_pending_notification'), true);
        expect(prefs.getInt('notification_reminder_id'), null);
      });

      test('çalışan hatırlatıcısı için routing bilgisini kaydetmeli', () async {
        // Arrange
        final payload = NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 2,
          username: 'testuser2',
          fullName: 'Test User 2',
          reminderId: 456,
        );

        // Act
        await service.saveRoutingInfo(payload);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notification_type'), 'employeeReminder');
        expect(prefs.getInt('notification_user_id'), 2);
        expect(prefs.getInt('notification_reminder_id'), 456);
        expect(prefs.getBool('has_pending_notification'), true);
      });

      test('önceki reminder ID\'yi temizlemeli', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_id', 999);

        final payload = NotificationPayload(
          type: NotificationType.attendanceReminder,
          userId: 1,
          username: 'testuser',
          fullName: 'Test User',
        );

        // Act
        await service.saveRoutingInfo(payload);

        // Assert
        expect(prefs.getInt('notification_reminder_id'), null);
      });

      test('mevcut routing bilgisini üzerine yazmalı', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_type', 'attendanceReminder');
        await prefs.setInt('notification_user_id', 1);

        final newPayload = NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 2,
          username: 'testuser2',
          fullName: 'Test User 2',
          reminderId: 789,
        );

        // Act
        await service.saveRoutingInfo(newPayload);

        // Assert
        expect(prefs.getString('notification_type'), 'employeeReminder');
        expect(prefs.getInt('notification_user_id'), 2);
        expect(prefs.getInt('notification_reminder_id'), 789);
      });
    });
  });
}
