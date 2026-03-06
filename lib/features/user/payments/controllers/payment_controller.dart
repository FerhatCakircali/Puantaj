import '../../../../models/employee.dart';
import '../../../../services/worker_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../data/local/hive_service.dart';

/// Ödeme ekranı iş mantığı kontrolcüsü
class PaymentController {
  final WorkerService _workerService = WorkerService();
  final PaymentService _paymentService = PaymentService();
  final _hiveService = HiveService.instance;

  /// Tüm çalışanları ve ödenmemiş günlerini yükler (Optimized)
  Future<PaymentData> loadPaymentData() async {
    // 1. Önce cache'den employees al (hızlı)
    final cachedEmployees = _hiveService.employees.values.toList();

    // Eğer cache varsa hemen döndür, arka planda güncelle
    if (cachedEmployees.isNotEmpty) {
      // Arka planda gerçek veriyi çek
      _loadDataInBackground();

      // Cache'den hızlı sonuç döndür
      return _processEmployeeData(cachedEmployees);
    }

    // Cache yoksa normal yükle
    final employees = await _workerService.getEmployees();
    return _processEmployeeData(employees);
  }

  /// Arka planda veri güncelle (non-blocking)
  Future<void> _loadDataInBackground() async {
    try {
      await _workerService.getEmployees();
    } catch (e) {
      // Sessizce başarısız ol
    }
  }

  /// Employee verilerini işle ve unpaid days hesapla
  Future<PaymentData> _processEmployeeData(List<Employee> employees) async {
    final unpaidDaysMap = <int, Map<String, int>>{};
    final unpaidScoresMap = <int, double>{};

    // Paralel olarak tüm unpaid days'leri çek
    final unpaidDaysFutures = employees.map((emp) async {
      try {
        final unpaidDays = await _paymentService.getUnpaidDays(emp.id);
        if (unpaidDays['fullDays']! > 0 || unpaidDays['halfDays']! > 0) {
          return MapEntry(emp.id, unpaidDays);
        }
      } catch (e) {
        // Hata durumunda skip et
      }
      return null;
    });

    final results = await Future.wait(unpaidDaysFutures);

    // Sonuçları map'e ekle
    for (var result in results) {
      if (result != null) {
        unpaidDaysMap[result.key] = result.value;
        final score =
            result.value['fullDays']!.toDouble() +
            (result.value['halfDays']!.toDouble() * 0.5);
        unpaidScoresMap[result.key] = score;
      }
    }

    final filteredEmployees = employees
        .where((emp) => unpaidDaysMap.containsKey(emp.id))
        .toList();

    filteredEmployees.sort((a, b) {
      final scoreA = unpaidScoresMap[a.id] ?? 0;
      final scoreB = unpaidScoresMap[b.id] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    final monthlyPaid = await _getMonthlyPaidAmount(employees);

    return PaymentData(
      employees: filteredEmployees,
      unpaidDays: unpaidDaysMap,
      unpaidScores: unpaidScoresMap,
      monthlyPaidAmount: monthlyPaid,
    );
  }

  /// Bu ay ödenen toplam tutarı hesaplar (Optimized)
  Future<double> _getMonthlyPaidAmount(List<Employee> employees) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double totalPaid = 0;

    // Paralel olarak tüm payments'ları çek
    final paymentFutures = employees.map((emp) async {
      try {
        final payments = await _paymentService.getPaymentsByWorkerId(emp.id);
        double empTotal = 0;
        for (var payment in payments) {
          if (payment.paymentDate.isAfter(
                startOfMonth.subtract(const Duration(days: 1)),
              ) &&
              payment.paymentDate.isBefore(
                endOfMonth.add(const Duration(days: 1)),
              )) {
            empTotal += payment.amount;
          }
        }
        return empTotal;
      } catch (e) {
        return 0.0;
      }
    });

    final results = await Future.wait(paymentFutures);
    totalPaid = results.fold(0.0, (sum, amount) => sum + amount);

    return totalPaid;
  }

  /// Çalışanları ada veya ünvana göre filtreler
  List<Employee> filterEmployees(List<Employee> employees, String query) {
    if (query.isEmpty) {
      return employees;
    }

    return employees
        .where(
          (employee) =>
              employee.name.toLowerCase().contains(query.toLowerCase()) ||
              employee.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Toplam ödenmemiş gün sayısını hesaplar
  double calculateTotalUnpaidDays(
    List<Employee> employees,
    Map<int, Map<String, int>> unpaidDays,
  ) {
    double total = 0;
    for (var emp in employees) {
      final days = unpaidDays[emp.id];
      if (days != null) {
        final score =
            days['fullDays']!.toDouble() + (days['halfDays']!.toDouble() * 0.5);
        total += score;
      }
    }
    return total;
  }
}

/// Ödeme verisi model sınıfı
class PaymentData {
  final List<Employee> employees;
  final Map<int, Map<String, int>> unpaidDays;
  final Map<int, double> unpaidScores;
  final double monthlyPaidAmount;

  PaymentData({
    required this.employees,
    required this.unpaidDays,
    required this.unpaidScores,
    required this.monthlyPaidAmount,
  });
}
