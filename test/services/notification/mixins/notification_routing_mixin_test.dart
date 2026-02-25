import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puantaj/services/notification/mixins/notification_routing_mixin.dart';

// Test için NotificationRoutingMixin'i kullanan sınıf
class TestNotificationService with NotificationRoutingMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationRoutingMixin', () {
    late TestNotificationService service;

    setUp(() {
      service = TestNotificationService();
      SharedPreferences.setMockInitialValues({});
    });

    group('clearRoutingInfo', () {
      test('tüm yönlendirme bilgilerini temizlemeli', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'notification_type': 'attendanceReminder',
          'notification_user_id': 1,
          'notification_reminder_id': 123,
          'has_pending_notification': true,
        });

        // Act
        await service.clearRoutingInfo();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('notification_type'), isNull);
        expect(prefs.getInt('notification_user_id'), isNull);
        expect(prefs.getInt('notification_reminder_id'), isNull);
        expect(prefs.getBool('has_pending_notification'), isFalse);
      });

      test('hata durumunda exception fırlatmamalı', () async {
        // Act & Assert - Hata fırlatmamalı
        await expectLater(service.clearRoutingInfo(), completes);
      });
    });

    group('checkAndHandlePendingNotification', () {
      testWidgets('bekleyen yönlendirme yoksa hiçbir şey yapmamalı', (
        WidgetTester tester,
      ) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': false,
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.checkAndHandlePendingNotification(context);
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        // Assert - Yönlendirme yapılmamalı
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('bildirim tipi yoksa bilgileri temizlemeli', (
        WidgetTester tester,
      ) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          // notification_type yok
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.checkAndHandlePendingNotification(context);
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        // Assert - Bilgiler temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), isFalse);
      });

      testWidgets('yevmiye hatırlatıcısı için yönlendirme yapmalı', (
        WidgetTester tester,
      ) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          'notification_type': 'attendanceReminder',
          'notification_user_id': 1,
        });

        bool routeCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.checkAndHandlePendingNotification(context);
                  },
                  child: const Text('Test'),
                );
              },
            ),
            routes: {
              '/attendance': (context) {
                routeCalled = true;
                return const Scaffold(body: Text('Attendance'));
              },
            },
          ),
        );

        // Act
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        // Assert
        expect(routeCalled, isTrue);
        expect(find.text('Attendance'), findsOneWidget);

        // Bilgiler temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), isFalse);
      });

      testWidgets('çalışan hatırlatıcısı için yönlendirme yapmalı', (
        WidgetTester tester,
      ) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          'notification_type': 'employeeReminder',
          'notification_user_id': 1,
          'notification_reminder_id': 123,
        });

        int? receivedReminderId;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.checkAndHandlePendingNotification(context);
                  },
                  child: const Text('Test'),
                );
              },
            ),
            onGenerateRoute: (settings) {
              if (settings.name == '/employee-reminder-detail') {
                receivedReminderId = settings.arguments as int?;
                return MaterialPageRoute(
                  builder: (context) =>
                      const Scaffold(body: Text('Employee Reminder')),
                );
              }
              return null;
            },
          ),
        );

        // Act
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        // Assert
        expect(receivedReminderId, equals(123));
        expect(find.text('Employee Reminder'), findsOneWidget);

        // Bilgiler temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), isFalse);
      });

      testWidgets(
        'çalışan hatırlatıcısı için reminder ID yoksa yönlendirme yapmamalı',
        (WidgetTester tester) async {
          // Arrange
          SharedPreferences.setMockInitialValues({
            'has_pending_notification': true,
            'notification_type': 'employeeReminder',
            'notification_user_id': 1,
            // notification_reminder_id yok
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await service.checkAndHandlePendingNotification(context);
                    },
                    child: const Text('Test'),
                  );
                },
              ),
              onGenerateRoute: (settings) {
                if (settings.name == '/employee-reminder-detail') {
                  return MaterialPageRoute(
                    builder: (context) =>
                        const Scaffold(body: Text('Employee Reminder')),
                  );
                }
                return null;
              },
            ),
          );

          // Act
          await tester.tap(find.text('Test'));
          await tester.pumpAndSettle();

          // Assert - Yönlendirme yapılmamalı
          expect(find.text('Employee Reminder'), findsNothing);

          // Bilgiler yine de temizlenmeli
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('has_pending_notification'), isFalse);
        },
      );

      testWidgets('hata durumunda bilgileri temizlemeli', (
        WidgetTester tester,
      ) async {
        // Arrange - Geçersiz bildirim tipi
        SharedPreferences.setMockInitialValues({
          'has_pending_notification': true,
          'notification_type': 'invalidType',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await service.checkAndHandlePendingNotification(context);
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        // Assert - Bilgiler temizlenmeli
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_pending_notification'), isFalse);
      });
    });
  });
}
