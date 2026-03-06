import 'package:flutter_test/flutter_test.dart';
import 'package:puantaj/models/worker.dart';
import 'package:puantaj/utils/date_formatter.dart';

/// WorkerService entegrasyon testi
/// DateFormatter'ın Worker modeli ile uyumlu çalıştığını doğrular
void main() {
  group('WorkerService Integration - DateFormatter', () {
    test('Worker startDate ISO 8601 formatında saklanmalı', () {
      // Arrange
      final worker = Worker(
        id: 1,
        userId: 1,
        username: 'test_worker',
        fullName: 'Test Çalışan',
        startDate: '2024-01-15',
      );

      // Act
      final parsedDate = DateFormatter.fromIso8601Date(worker.startDate);

      // Assert
      expect(parsedDate.year, 2024);
      expect(parsedDate.month, 1);
      expect(parsedDate.day, 15);
    });

    test('Worker startDate display formatına dönüştürülebilmeli', () {
      // Arrange
      final worker = Worker(
        id: 1,
        userId: 1,
        username: 'test_worker',
        fullName: 'Test Çalışan',
        startDate: '2024-03-15',
      );

      // Act
      final parsedDate = DateFormatter.fromIso8601Date(worker.startDate);
      final displayDate = DateFormatter.toDisplayDate(parsedDate);

      // Assert
      expect(displayDate, '15.03.2024');
    });

    test('Worker listesi startDate\'e göre sıralanabilmeli', () {
      // Arrange
      final workers = [
        Worker(
          id: 1,
          userId: 1,
          username: 'worker1',
          fullName: 'Çalışan 1',
          startDate: '2024-03-15',
        ),
        Worker(
          id: 2,
          userId: 1,
          username: 'worker2',
          fullName: 'Çalışan 2',
          startDate: '2024-01-10',
        ),
        Worker(
          id: 3,
          userId: 1,
          username: 'worker3',
          fullName: 'Çalışan 3',
          startDate: '2024-02-20',
        ),
      ];

      // Act - Tarihe göre sırala (en eski en üstte)
      workers.sort((a, b) {
        final dateA = DateFormatter.fromIso8601Date(a.startDate);
        final dateB = DateFormatter.fromIso8601Date(b.startDate);
        return dateA.compareTo(dateB);
      });

      // Assert
      expect(workers[0].id, 2); // 2024-01-10
      expect(workers[1].id, 3); // 2024-02-20
      expect(workers[2].id, 1); // 2024-03-15
    });

    test('Worker toMap ve fromMap DateFormatter ile tutarlı olmalı', () {
      // Arrange
      final originalWorker = Worker(
        id: 1,
        userId: 1,
        username: 'test_worker',
        fullName: 'Test Çalışan',
        phone: '5551234567',
        startDate: '2024-01-15',
      );

      // Act
      final workerMap = originalWorker.toMap();
      final reconstructedWorker = Worker.fromMap(workerMap);

      // Assert
      expect(reconstructedWorker.startDate, originalWorker.startDate);
      expect(reconstructedWorker.fullName, originalWorker.fullName);
      expect(reconstructedWorker.phone, originalWorker.phone);
    });

    test('Çalışma süresi hesaplama DateFormatter ile doğru çalışmalı', () {
      // Arrange - 1 yıl önce işe alınan çalışan
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      final startDateStr = DateFormatter.toIso8601Date(oneYearAgo);

      final worker = Worker(
        id: 1,
        userId: 1,
        username: 'senior_worker',
        fullName: 'Kıdemli Çalışan',
        startDate: startDateStr,
      );

      // Act
      final startDate = DateFormatter.fromIso8601Date(worker.startDate);
      final workDuration = DateTime.now().difference(startDate);
      final workDays = workDuration.inDays;

      // Assert
      expect(workDays, greaterThanOrEqualTo(365));
    });

    test('Bugün işe alınan çalışan için tarih formatı doğru olmalı', () {
      // Arrange
      final today = DateTime.now();
      final todayStr = DateFormatter.toIso8601Date(today);

      final worker = Worker(
        id: 1,
        userId: 1,
        username: 'new_worker',
        fullName: 'Yeni Çalışan',
        startDate: todayStr,
      );

      // Act
      final parsedDate = DateFormatter.fromIso8601Date(worker.startDate);
      final displayDate = DateFormatter.toDisplayDate(parsedDate);

      // Assert
      expect(worker.startDate, matches(r'^\d{4}-\d{2}-\d{2}$'));
      expect(displayDate, matches(r'^\d{2}\.\d{2}\.\d{4}$'));
    });

    test('Format dönüşümleri tutarlı olmalı', () {
      // Arrange
      final originalDate = DateTime(2024, 3, 5);
      final isoDate = DateFormatter.toIso8601Date(originalDate);

      final worker = Worker(
        id: 1,
        userId: 1,
        username: 'test_worker',
        fullName: 'Test Çalışan',
        startDate: isoDate,
      );

      // Act
      final parsedDate = DateFormatter.fromIso8601Date(worker.startDate);
      final displayDate = DateFormatter.toDisplayDate(parsedDate);
      final shortDate = DateFormatter.toShortDate(parsedDate);

      // Assert
      expect(worker.startDate, '2024-03-05');
      expect(displayDate, '05.03.2024');
      expect(shortDate, '05.03.24');
    });
  });
}
