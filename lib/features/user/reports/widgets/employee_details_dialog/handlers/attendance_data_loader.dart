import '../../../../../../models/employee.dart';
import '../../../../../../services/attendance_service.dart';
import '../../../../../../services/payment_service.dart';
import '../calculators/attendance_calculator.dart';

/// Çalışan devam ve ödeme verilerini yükler
///
/// AttendanceService ve PaymentService ile koordinasyon sağlar.
class AttendanceDataLoader {
  final AttendanceService _attendanceService;
  final PaymentService _paymentService;

  AttendanceDataLoader({
    AttendanceService? attendanceService,
    PaymentService? paymentService,
  }) : _attendanceService = attendanceService ?? AttendanceService(),
       _paymentService = paymentService ?? PaymentService();

  /// Çalışanın tüm devam ve ödeme verilerini yükler
  Future<EmployeeData> loadEmployeeData(Employee employee) async {
    final records = await _attendanceService.getAttendanceBetween(
      employee.startDate,
      DateTime.now(),
      workerId: employee.id,
    );

    final attendanceResult = AttendanceCalculator.calculate(
      records: records,
      startDate: employee.startDate,
      endDate: DateTime.now(),
      workerId: employee.id,
    );

    final payments = await _paymentService.getPaymentsByWorkerId(employee.id);

    final totalPaid = payments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    final paidFullDays = payments.fold<int>(
      0,
      (sum, payment) => sum + payment.fullDays,
    );
    final paidHalfDays = payments.fold<int>(
      0,
      (sum, payment) => sum + payment.halfDays,
    );

    return EmployeeData(
      attendanceResult: attendanceResult,
      totalPaid: totalPaid,
      paidFullDays: paidFullDays,
      paidHalfDays: paidHalfDays,
    );
  }
}

/// Çalışan verisi modeli
class EmployeeData {
  final AttendanceResult attendanceResult;
  final double totalPaid;
  final int paidFullDays;
  final int paidHalfDays;

  EmployeeData({
    required this.attendanceResult,
    required this.totalPaid,
    required this.paidFullDays,
    required this.paidHalfDays,
  });
}
