import 'package:flutter_test/flutter_test.dart';
import 'package:puantaj/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('format', () {
      test('tam sayıyı binlik ayırıcı ile formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(1000);

        // Assert
        expect(result, '1.000');
      });

      test('büyük sayıları doğru formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(1000000);

        // Assert
        expect(result, '1.000.000');
      });

      test('ondalıklı sayıyı virgül ile formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(1234.56);

        // Assert
        expect(result, '1.234,56');
      });

      test('ondalık kısım 00 ise göstermemeli', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(1000.00);

        // Assert
        expect(result, '1.000');
      });

      test('küçük sayıları formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(50);

        // Assert
        expect(result, '50');
      });

      test('sıfır değerini formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.format(0);

        // Assert
        expect(result, '0');
      });
    });

    group('formatWithSymbol', () {
      test('tutarı sembol ile birlikte formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.formatWithSymbol(1000);

        // Assert
        expect(result, '₺1.000');
      });

      test('ondalıklı tutarı sembol ile formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.formatWithSymbol(1234.56);

        // Assert
        expect(result, '₺1.234,56');
      });
    });

    group('parse', () {
      test('formatlanmış string\'i double\'a çevirmeli', () {
        // Arrange & Act
        final result = CurrencyFormatter.parse('1.000');

        // Assert
        expect(result, 1000.0);
      });

      test('ondalıklı formatı parse etmeli', () {
        // Arrange & Act
        final result = CurrencyFormatter.parse('1.234,56');

        // Assert
        expect(result, 1234.56);
      });

      test('sembol içeren string\'i parse etmeli', () {
        // Arrange & Act
        final result = CurrencyFormatter.parse('₺1.000');

        // Assert
        expect(result, 1000.0);
      });

      test('geçersiz format için 0.0 döndürmeli', () {
        // Arrange & Act
        final result = CurrencyFormatter.parse('geçersiz');

        // Assert
        expect(result, 0.0);
      });
    });

    group('formatSimple', () {
      test('ondalık kısmı göstermeden formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.formatSimple(1234.56);

        // Assert
        expect(result, '1.234');
      });

      test('tam sayıyı formatlamalı', () {
        // Arrange & Act
        final result = CurrencyFormatter.formatSimple(1000);

        // Assert
        expect(result, '1.000');
      });
    });

    group('Format Dönüşüm Tutarlılığı', () {
      test('format ve parse birbirinin tersi olmalı', () {
        // Arrange
        const originalAmount = 1234.56;

        // Act
        final formatted = CurrencyFormatter.format(originalAmount);
        final parsed = CurrencyFormatter.parse(formatted);

        // Assert
        expect(parsed, originalAmount);
      });
    });
  });
}
