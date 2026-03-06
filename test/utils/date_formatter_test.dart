import 'package:flutter_test/flutter_test.dart';
import 'package:puantaj/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('toIso8601Date', () {
      test('standart tarihi ISO 8601 formatına dönüştürmeli', () {
        // Arrange
        final date = DateTime(2024, 3, 5);

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-03-05');
      });

      test('tek haneli ay için sıfır padding eklemeli', () {
        // Arrange
        final date = DateTime(2024, 1, 15);

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-01-15');
      });

      test('tek haneli gün için sıfır padding eklemeli', () {
        // Arrange
        final date = DateTime(2024, 12, 5);

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-12-05');
      });

      test(
        'hem tek haneli ay hem tek haneli gün için sıfır padding eklemeli',
        () {
          // Arrange
          final date = DateTime(2024, 1, 1);

          // Act
          final result = DateFormatter.toIso8601Date(date);

          // Assert
          expect(result, '2024-01-01');
        },
      );

      test('yılbaşı tarihini doğru formatlamalı', () {
        // Arrange
        final date = DateTime(2024, 1, 1);

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-01-01');
      });

      test('yılsonu tarihini doğru formatlamalı', () {
        // Arrange
        final date = DateTime(2024, 12, 31);

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-12-31');
      });

      test('şubat ayının son gününü doğru formatlamalı (artık yıl)', () {
        // Arrange
        final date = DateTime(2024, 2, 29); // 2024 artık yıl

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2024-02-29');
      });

      test('şubat ayının son gününü doğru formatlamalı (normal yıl)', () {
        // Arrange
        final date = DateTime(2023, 2, 28); // 2023 normal yıl

        // Act
        final result = DateFormatter.toIso8601Date(date);

        // Assert
        expect(result, '2023-02-28');
      });
    });

    group('fromIso8601Date', () {
      test('ISO 8601 formatındaki string\'i DateTime\'a dönüştürmeli', () {
        // Arrange
        const dateString = '2024-03-05';

        // Act
        final result = DateFormatter.fromIso8601Date(dateString);

        // Assert
        expect(result.year, 2024);
        expect(result.month, 3);
        expect(result.day, 5);
      });

      test('tek haneli ay ve gün içeren string\'i parse etmeli', () {
        // Arrange
        const dateString = '2024-01-01';

        // Act
        final result = DateFormatter.fromIso8601Date(dateString);

        // Assert
        expect(result.year, 2024);
        expect(result.month, 1);
        expect(result.day, 1);
      });

      test('geçersiz format için FormatException fırlatmalı', () {
        // Arrange
        const invalidDateString = '05-03-2024'; // Yanlış format

        // Act & Assert
        expect(
          () => DateFormatter.fromIso8601Date(invalidDateString),
          throwsFormatException,
        );
      });

      test('boş string için FormatException fırlatmalı', () {
        // Arrange
        const emptyString = '';

        // Act & Assert
        expect(
          () => DateFormatter.fromIso8601Date(emptyString),
          throwsFormatException,
        );
      });
    });

    group('toDisplayDate', () {
      test('tarihi Türk formatına (DD.MM.YYYY) dönüştürmeli', () {
        // Arrange
        final date = DateTime(2024, 3, 5);

        // Act
        final result = DateFormatter.toDisplayDate(date);

        // Assert
        expect(result, '05.03.2024');
      });

      test('tek haneli gün için sıfır padding eklemeli', () {
        // Arrange
        final date = DateTime(2024, 12, 5);

        // Act
        final result = DateFormatter.toDisplayDate(date);

        // Assert
        expect(result, '05.12.2024');
      });

      test('tek haneli ay için sıfır padding eklemeli', () {
        // Arrange
        final date = DateTime(2024, 1, 15);

        // Act
        final result = DateFormatter.toDisplayDate(date);

        // Assert
        expect(result, '15.01.2024');
      });

      test('yılbaşı tarihini Türk formatında göstermeli', () {
        // Arrange
        final date = DateTime(2024, 1, 1);

        // Act
        final result = DateFormatter.toDisplayDate(date);

        // Assert
        expect(result, '01.01.2024');
      });
    });

    group('toShortDate', () {
      test('tarihi kısa Türk formatına (DD.MM.YY) dönüştürmeli', () {
        // Arrange
        final date = DateTime(2024, 3, 5);

        // Act
        final result = DateFormatter.toShortDate(date);

        // Assert
        expect(result, '05.03.24');
      });

      test('tek haneli gün ve ay için sıfır padding eklemeli', () {
        // Arrange
        final date = DateTime(2024, 1, 1);

        // Act
        final result = DateFormatter.toShortDate(date);

        // Assert
        expect(result, '01.01.24');
      });

      test('2000 öncesi yılları doğru formatlamalı', () {
        // Arrange
        final date = DateTime(1999, 12, 31);

        // Act
        final result = DateFormatter.toShortDate(date);

        // Assert
        expect(result, '31.12.99');
      });

      test('2010\'lu yılları doğru formatlamalı', () {
        // Arrange
        final date = DateTime(2015, 6, 15);

        // Act
        final result = DateFormatter.toShortDate(date);

        // Assert
        expect(result, '15.06.15');
      });
    });

    group('Format Dönüşüm Tutarlılığı', () {
      test('toIso8601Date ve fromIso8601Date birbirinin tersi olmalı', () {
        // Arrange
        final originalDate = DateTime(2024, 3, 5);

        // Act
        final isoString = DateFormatter.toIso8601Date(originalDate);
        final parsedDate = DateFormatter.fromIso8601Date(isoString);

        // Assert
        expect(parsedDate.year, originalDate.year);
        expect(parsedDate.month, originalDate.month);
        expect(parsedDate.day, originalDate.day);
      });

      test('farklı formatlar aynı tarihi temsil etmeli', () {
        // Arrange
        final date = DateTime(2024, 3, 5);

        // Act
        final isoFormat = DateFormatter.toIso8601Date(date);
        final displayFormat = DateFormatter.toDisplayDate(date);
        final shortFormat = DateFormatter.toShortDate(date);

        // Assert
        expect(isoFormat, '2024-03-05');
        expect(displayFormat, '05.03.2024');
        expect(shortFormat, '05.03.24');
      });
    });

    group('Edge Cases', () {
      test('artık yıl 29 Şubat tarihini doğru işlemeli', () {
        // Arrange
        final leapYearDate = DateTime(2024, 2, 29);

        // Act
        final iso = DateFormatter.toIso8601Date(leapYearDate);
        final display = DateFormatter.toDisplayDate(leapYearDate);
        final short = DateFormatter.toShortDate(leapYearDate);

        // Assert
        expect(iso, '2024-02-29');
        expect(display, '29.02.2024');
        expect(short, '29.02.24');
      });

      test('maksimum tarih değerini işlemeli', () {
        // Arrange
        final maxDate = DateTime(9999, 12, 31);

        // Act
        final result = DateFormatter.toIso8601Date(maxDate);

        // Assert
        expect(result, '9999-12-31');
      });

      test('minimum tarih değerini işlemeli', () {
        // Arrange
        final minDate = DateTime(1000, 1, 1); // 4 haneli yıl kullan

        // Act
        final result = DateFormatter.toIso8601Date(minDate);

        // Assert
        expect(result, '1000-01-01');
      });
    });
  });
}
