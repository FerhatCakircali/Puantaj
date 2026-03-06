import 'package:flutter_test/flutter_test.dart';
import 'package:puantaj/models/payment.dart';
import 'package:puantaj/utils/date_formatter.dart';
import 'package:puantaj/utils/currency_formatter.dart';

/// PaymentService entegrasyon testi
/// DateFormatter ve CurrencyFormatter'ın Payment modeli ile uyumlu çalıştığını doğrular
void main() {
  group('PaymentService Integration - DateFormatter & CurrencyFormatter', () {
    test('Payment modeli formatter\'lar ile uyumlu çalışmalı', () {
      // Arrange
      final paymentDate = DateTime(2024, 3, 15);
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 5000.0,
        fullDays: 10,
        halfDays: 0,
        paymentDate: paymentDate,
      );

      // Act
      final formattedDate = DateFormatter.toIso8601Date(payment.paymentDate);
      final displayDate = DateFormatter.toDisplayDate(payment.paymentDate);
      final formattedAmount = CurrencyFormatter.format(payment.amount);
      final amountWithSymbol = CurrencyFormatter.formatWithSymbol(
        payment.amount,
      );

      // Assert
      expect(formattedDate, '2024-03-15');
      expect(displayDate, '15.03.2024');
      expect(formattedAmount, '5.000');
      expect(amountWithSymbol, '₺5.000');
    });

    test('Ondalıklı tutar ve tarih formatı birlikte çalışmalı', () {
      // Arrange
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 5234.56,
        fullDays: 10,
        halfDays: 1,
        paymentDate: DateTime(2024, 1, 5),
      );

      // Act
      final formattedAmount = CurrencyFormatter.format(payment.amount);
      final formattedDate = DateFormatter.toIso8601Date(payment.paymentDate);

      // Assert
      expect(formattedAmount, '5.234,56');
      expect(formattedDate, '2024-01-05');
    });

    test('Payment listesi tarih sıralaması doğru çalışmalı', () {
      // Arrange
      final payments = [
        Payment(
          id: 1,
          workerId: 1,
          userId: 1,
          amount: 3000.0,
          fullDays: 6,
          halfDays: 0,
          paymentDate: DateTime(2024, 3, 15),
        ),
        Payment(
          id: 2,
          workerId: 1,
          userId: 1,
          amount: 5000.0,
          fullDays: 10,
          halfDays: 0,
          paymentDate: DateTime(2024, 1, 10),
        ),
        Payment(
          id: 3,
          workerId: 1,
          userId: 1,
          amount: 4000.0,
          fullDays: 8,
          halfDays: 0,
          paymentDate: DateTime(2024, 2, 20),
        ),
      ];

      // Act - Tarihe göre sırala (en yeni en üstte)
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      // Assert
      expect(payments[0].id, 1); // 2024-03-15
      expect(payments[1].id, 3); // 2024-02-20
      expect(payments[2].id, 2); // 2024-01-10
    });

    test('Payment toMap ve fromMap formatter\'lar ile tutarlı olmalı', () {
      // Arrange
      final originalPayment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 5234.56,
        fullDays: 10,
        halfDays: 1,
        paymentDate: DateTime(2024, 3, 15),
      );

      // Act
      final paymentMap = originalPayment.toMap();
      final reconstructedPayment = Payment.fromMap(paymentMap);

      // Assert
      expect(reconstructedPayment.amount, originalPayment.amount);
      expect(reconstructedPayment.fullDays, originalPayment.fullDays);
      expect(reconstructedPayment.halfDays, originalPayment.halfDays);

      // Tarih karşılaştırması (sadece gün, ay, yıl)
      expect(
        reconstructedPayment.paymentDate.year,
        originalPayment.paymentDate.year,
      );
      expect(
        reconstructedPayment.paymentDate.month,
        originalPayment.paymentDate.month,
      );
      expect(
        reconstructedPayment.paymentDate.day,
        originalPayment.paymentDate.day,
      );
    });

    test(
      'Aylık ödeme toplamı hesaplama formatter\'lar ile doğru çalışmalı',
      () {
        // Arrange
        final payments = [
          Payment(
            id: 1,
            workerId: 1,
            userId: 1,
            amount: 3000.0,
            fullDays: 6,
            halfDays: 0,
            paymentDate: DateTime(2024, 3, 5),
          ),
          Payment(
            id: 2,
            workerId: 1,
            userId: 1,
            amount: 2500.0,
            fullDays: 5,
            halfDays: 0,
            paymentDate: DateTime(2024, 3, 15),
          ),
          Payment(
            id: 3,
            workerId: 1,
            userId: 1,
            amount: 1500.0,
            fullDays: 3,
            halfDays: 0,
            paymentDate: DateTime(2024, 3, 25),
          ),
        ];

        // Act - Mart ayı ödemelerini topla
        final marchPayments = payments.where((p) {
          return p.paymentDate.year == 2024 && p.paymentDate.month == 3;
        }).toList();

        final totalAmount = marchPayments.fold<double>(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        // Assert
        expect(totalAmount, 7000.0);
        expect(CurrencyFormatter.formatWithSymbol(totalAmount), '₺7.000');
      },
    );

    test('Gün başına ücret hesaplama formatter\'lar ile doğru çalışmalı', () {
      // Arrange
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 5250.0,
        fullDays: 10,
        halfDays: 1, // 10.5 gün
        paymentDate: DateTime(2024, 3, 15),
      );

      // Act
      final totalDays = payment.fullDays + (payment.halfDays * 0.5);
      final dailyRate = payment.amount / totalDays;

      // Assert
      expect(totalDays, 10.5);
      expect(dailyRate, 500.0);
      expect(CurrencyFormatter.format(dailyRate), '500');
    });

    test('Sıfır tutarlı ödeme formatlanmalı', () {
      // Arrange
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 0.0,
        fullDays: 0,
        halfDays: 0,
        paymentDate: DateTime(2024, 3, 15),
      );

      // Act
      final formattedAmount = CurrencyFormatter.format(payment.amount);

      // Assert
      expect(formattedAmount, '0');
    });

    test('Çok büyük tutar formatlanmalı', () {
      // Arrange
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 1000000.0,
        fullDays: 200,
        halfDays: 0,
        paymentDate: DateTime(2024, 3, 15),
      );

      // Act
      final formattedAmount = CurrencyFormatter.formatWithSymbol(
        payment.amount,
      );

      // Assert
      expect(formattedAmount, '₺1.000.000');
    });

    test('Bugün yapılan ödeme için tarih formatı doğru olmalı', () {
      // Arrange
      final today = DateTime.now();
      final payment = Payment(
        id: 1,
        workerId: 1,
        userId: 1,
        amount: 5000.0,
        fullDays: 10,
        halfDays: 0,
        paymentDate: today,
      );

      // Act
      final formattedDate = DateFormatter.toIso8601Date(payment.paymentDate);
      final displayDate = DateFormatter.toDisplayDate(payment.paymentDate);

      // Assert
      expect(formattedDate, matches(r'^\d{4}-\d{2}-\d{2}$'));
      expect(displayDate, matches(r'^\d{2}\.\d{2}\.\d{4}$'));
    });

    test('Haftalık ödeme raporu formatter\'lar ile oluşturulmalı', () {
      // Arrange
      final weekPayments = [
        Payment(
          id: 1,
          workerId: 1,
          userId: 1,
          amount: 500.0,
          fullDays: 1,
          halfDays: 0,
          paymentDate: DateTime(2024, 3, 11),
        ),
        Payment(
          id: 2,
          workerId: 1,
          userId: 1,
          amount: 500.0,
          fullDays: 1,
          halfDays: 0,
          paymentDate: DateTime(2024, 3, 12),
        ),
        Payment(
          id: 3,
          workerId: 1,
          userId: 1,
          amount: 250.0,
          fullDays: 0,
          halfDays: 1,
          paymentDate: DateTime(2024, 3, 13),
        ),
      ];

      // Act
      final weeklyTotal = weekPayments.fold<double>(
        0.0,
        (sum, p) => sum + p.amount,
      );
      final totalFullDays = weekPayments.fold<int>(
        0,
        (sum, p) => sum + p.fullDays,
      );
      final totalHalfDays = weekPayments.fold<int>(
        0,
        (sum, p) => sum + p.halfDays,
      );

      // Assert
      expect(weeklyTotal, 1250.0);
      expect(totalFullDays, 2);
      expect(totalHalfDays, 1);
      expect(CurrencyFormatter.formatWithSymbol(weeklyTotal), '₺1.250');
    });
  });
}
