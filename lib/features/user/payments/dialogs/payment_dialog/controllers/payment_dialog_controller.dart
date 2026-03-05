import '../../../../../../models/employee.dart';
import '../../../../../../models/payment.dart';
import '../../../../../../services/auth_service.dart';
import '../../../../../../services/payment_service.dart';

/// Ödeme dialog'u iş mantığı kontrolcüsü
class PaymentDialogController {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();

  /// Ödenmemiş günleri yükler
  Future<Map<String, int>> loadUnpaidDays(int employeeId) async {
    return await _paymentService.getUnpaidDays(employeeId);
  }

  /// Ödeme tutarını hesaplar
  double calculateAmount({
    required int fullDays,
    required int halfDays,
    required double dailyRate,
  }) {
    final totalDays = fullDays + (halfDays * 0.5);
    return totalDays * dailyRate;
  }

  /// Sayıyı formatlar (binlik ayırıcı ile)
  String formatNumber(int number) {
    if (number == 0) return '';
    final str = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }

  /// Ödeme validasyonu yapar
  String? validatePayment({
    required int fullDays,
    required int halfDays,
    required double amount,
    required int availableFullDays,
    required int availableHalfDays,
  }) {
    if (fullDays > availableFullDays || halfDays > availableHalfDays) {
      return 'Girdiğiniz gün sayısı mevcut gün sayısından fazla olamaz.';
    }

    if (fullDays == 0 && halfDays == 0) {
      return 'En az bir gün seçmelisiniz.';
    }

    if (amount <= 0) {
      return 'Lütfen geçerli bir ödeme miktarı girin.';
    }

    return null;
  }

  /// Ödeme kaydı oluşturur ve payment ID'yi döner
  Future<int?> makePayment({
    required Employee employee,
    required int fullDays,
    required int halfDays,
    required double amount,
  }) async {
    final currentUser = await _authService.currentUser;
    if (currentUser == null) {
      throw Exception('Oturum bilgisi alınamadı. Lütfen tekrar giriş yapın.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final payment = Payment(
      userId: currentUser['id'] as int,
      workerId: employee.id,
      fullDays: fullDays,
      halfDays: halfDays,
      paymentDate: today,
      amount: amount,
    );

    return await _paymentService.addPayment(payment);
  }
}
