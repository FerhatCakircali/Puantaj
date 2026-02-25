import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puantaj/models/notification_payload.dart';
import 'package:puantaj/services/notification/mixins/notification_routing_mixin.dart';
import 'package:puantaj/services/notification/mixins/notification_payload_mixin.dart';

/// Test için mixin'leri kullanan servis sınıfı
class TestNotificationService
    with NotificationRoutingMixin, NotificationPayloadMixin {}

/// Çalışan hatırlatıcısı routing integration testi
///
/// Bu test, çalışan hatırlatıcısı bildirimlerinin
/// doğru sayfaya yönlendirme yapıp yapmadığını kontrol eder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee Reminder Routing Integration', () {
    late TestNotificationService notificationService;

    setUp(() {
      notificationService = TestNotificationService();
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Çalışan hatırlatıcısı payload\'ı doğru şekilde kaydedilmeli', (
      WidgetTester tester,
    ) async {
      // Arrange
      const reminderId = 456;
      const userId = 1;
      const username = 'testuser';
      const fullName = 'Test User';

      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: userId,
        username: username,
        fullName: fullName,
        reminderId: reminderId,
      );

      // Act
      await notificationService.handleNotificationTap(payload.toJson());

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_pending_notification'), isTrue);
      expect(prefs.getString('notification_type'), equals('employeeReminder'));
      expect(prefs.getInt('notification_user_id'), equals(userId));
      expect(prefs.getInt('notification_reminder_id'), equals(reminderId));
    });

    testWidgets(
      'Çalışan hatırlatıcısı yönlendirmesi doğru reminder ID ile yapılmalı',
      (WidgetTester tester) async {
        // Arrange
        const reminderId = 789;
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          'notification_type': 'employeeReminder',
          'notification_user_id': 1,
          'notification_reminder_id': reminderId,
        });

        int? capturedReminderId;
        bool routeNavigated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await notificationService
                          .checkAndHandlePendingNotification(context);
                    },
                    child: const Text('Check Notification'),
                  ),
                );
              },
            ),
            onGenerateRoute: (settings) {
              if (settings.name == '/employee-reminder-detail') {
                capturedReminderId = settings.arguments as int?;
                routeNavigated = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Reminder Detail')),
                    body: Center(
                      child: Text('Reminder ID: ${settings.arguments}'),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        );

        // Act
        await tester.tap(find.text('Check Notification'));
        await tester.pumpAndSettle();

        // Assert
        expect(routeNavigated, isTrue, reason: 'Route should be navigated');
        expect(
          capturedReminderId,
          equals(reminderId),
          reason: 'Reminder ID should match',
        );
        expect(
          find.text('Reminder ID: $reminderId'),
          findsOneWidget,
          reason: 'Reminder detail page should be displayed',
        );

        // Routing bilgisi temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool('has_pending_notification'),
          isFalse,
          reason: 'Pending notification flag should be cleared',
        );
      },
    );

    testWidgets(
      'Reminder ID olmadan çalışan hatırlatıcısı yönlendirmesi yapılmamalı',
      (WidgetTester tester) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          'notification_type': 'employeeReminder',
          'notification_user_id': 1,
          // notification_reminder_id yok
        });

        bool routeNavigated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await notificationService
                          .checkAndHandlePendingNotification(context);
                    },
                    child: const Text('Check Notification'),
                  ),
                );
              },
            ),
            onGenerateRoute: (settings) {
              if (settings.name == '/employee-reminder-detail') {
                routeNavigated = true;
                return MaterialPageRoute(
                  builder: (context) =>
                      const Scaffold(body: Text('Reminder Detail')),
                );
              }
              return null;
            },
          ),
        );

        // Act
        await tester.tap(find.text('Check Notification'));
        await tester.pumpAndSettle();

        // Assert
        expect(
          routeNavigated,
          isFalse,
          reason: 'Route should not be navigated without reminder ID',
        );
        expect(
          find.text('Reminder Detail'),
          findsNothing,
          reason: 'Reminder detail page should not be displayed',
        );

        // Routing bilgisi yine de temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool('has_pending_notification'),
          isFalse,
          reason: 'Pending notification flag should be cleared',
        );
      },
    );

    testWidgets('Çoklu çalışan hatırlatıcısı payload\'ları sırayla işlenmeli', (
      WidgetTester tester,
    ) async {
      // Arrange
      final payloads = [
        NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 1,
          username: 'user1',
          fullName: 'User One',
          reminderId: 100,
        ),
        NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 1,
          username: 'user1',
          fullName: 'User One',
          reminderId: 200,
        ),
        NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: 1,
          username: 'user1',
          fullName: 'User One',
          reminderId: 300,
        ),
      ];

      // Act & Assert
      for (final payload in payloads) {
        await notificationService.handleNotificationTap(payload.toJson());

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), isTrue);
        expect(
          prefs.getInt('notification_reminder_id'),
          equals(payload.reminderId),
        );

        // Temizle
        await notificationService.clearRoutingInfo();
      }
    });

    test('Geçersiz reminder ID ile payload oluşturulmamalı', () {
      // Arrange & Act
      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: 1,
        username: 'testuser',
        fullName: 'Test User',
        reminderId: null, // Geçersiz
      );

      // Assert
      expect(payload.reminderId, isNull, reason: 'Reminder ID should be null');

      // JSON'a çevrildiğinde reminderId olmamalı
      final json = payload.toJson();
      expect(
        json.contains('reminderId'),
        isFalse,
        reason: 'JSON should not contain reminderId field',
      );
    });

    testWidgets('Hatalı payload ile yönlendirme yapılmamalı', (
      WidgetTester tester,
    ) async {
      // Arrange
      const invalidPayload = '{"invalid": "data"}';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await notificationService.handleNotificationTap(
                      invalidPayload,
                    );
                    if (context.mounted) {
                      await notificationService
                          .checkAndHandlePendingNotification(context);
                    }
                  },
                  child: const Text('Check Notification'),
                ),
              );
            },
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/employee-reminder-detail') {
              return MaterialPageRoute(
                builder: (context) =>
                    const Scaffold(body: Text('Reminder Detail')),
              );
            }
            return null;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Check Notification'));
      await tester.pumpAndSettle();

      // Assert - Yönlendirme yapılmamalı
      expect(
        find.text('Reminder Detail'),
        findsNothing,
        reason: 'Should not navigate with invalid payload',
      );
    });
  });
}
