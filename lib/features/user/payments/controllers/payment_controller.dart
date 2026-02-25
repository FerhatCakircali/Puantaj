import '../../../../models/employee.dart';
import '../../../../services/worker_service.dart';
import '../../../../services/payment_service.dart';

/// Ödeme ekranı iş mantığı kontrolcüsü
class PaymentController {
  final WorkerService _workerService = WorkerService();
  final PaymentService _paymentService = PaymentService();

  /// Tüm çalışanları ve ödenmemiş günlerini yükler
  Future<PaymentData> loadPaymentData() async {
    final employees = await _workerService.getEmployees();
    final unpaidDaysMap = <int, Map<String, int>>{};
    final unpaidScoresMap = <int, double>{};

    for (var emp in employees) {
      final unpaidDays = await _paymentService.getUnpaidDays(emp.id);
      if (unpaidDays['fullDays']! > 0 || unpaidDays['halfDays']! > 0) {
        unpaidDaysMap[emp.id] = unpaidDays;
        final score =
            unpaidDays['fullDays']!.toDouble() +
            (unpaidDays['halfDays']!.toDouble() * 0.5);
        unpaidScoresMap[emp.id] = score;
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

  /// Bu ay ödenen toplam tutarı hesaplar
  Future<double> _getMonthlyPaidAmount(List<Employee> employees) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double totalPaid = 0;

    for (var emp in employees) {
      final payments = await _paymentService.getPaymentsByWorkerId(emp.id);
      for (var payment in payments) {
        if (payment.paymentDate.isAfter(
              startOfMonth.subtract(const Duration(days: 1)),
            ) &&
            payment.paymentDate.isBefore(
              endOfMonth.add(const Duration(days: 1)),
            )) {
          totalPaid += payment.amount;
        }
      }
    }

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
