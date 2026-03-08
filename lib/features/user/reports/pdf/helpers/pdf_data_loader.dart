import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import '../../../../../models/employee.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/advance_service.dart';
import '../../../../../services/expense_service.dart';

/// PDF raporları için veri yükleme yardımcısı
///
/// Çalışan, ödeme, avans ve masraf verilerini toplar.
class PdfDataLoader {
  final AttendanceService _attendanceService;
  final PaymentService _paymentService;
  final AdvanceService _advanceService;
  final ExpenseService _expenseService;

  PdfDataLoader({
    AttendanceService? attendanceService,
    PaymentService? paymentService,
    AdvanceService? advanceService,
    ExpenseService? expenseService,
  }) : _attendanceService = attendanceService ?? AttendanceService(),
       _paymentService = paymentService ?? PaymentService(),
       _advanceService = advanceService ?? AdvanceService(),
       _expenseService = expenseService ?? ExpenseService();

  /// Tek çalışan için devam kayıtlarını yükle
  Future<List<Attendance>> loadEmployeeAttendances(
    int workerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _attendanceService.getAttendanceBetween(
      startDate,
      endDate,
      workerId: workerId,
    );
  }

  /// Tek çalışan için ödemeleri yükle
  Future<List<Payment>> loadEmployeePayments(int workerId) async {
    return await _paymentService.getPaymentsByWorkerId(workerId);
  }

  /// Tek çalışan için avansları yükle
  Future<List<Advance>> loadEmployeeAdvances(int workerId) async {
    return await _advanceService.getWorkerAdvances(workerId);
  }

  /// Tüm çalışanlar için devam kayıtlarını yükle
  Future<List<List<Attendance>>> loadAllAttendances(
    List<Employee> employees,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await Future.wait(
      employees.map(
        (emp) => _attendanceService.getAttendanceBetween(
          startDate,
          endDate,
          workerId: emp.id,
        ),
      ),
    );
  }

  /// Tüm çalışanlar için ödemeleri yükle
  Future<List<List<Payment>>> loadAllPayments(List<Employee> employees) async {
    return await Future.wait(
      employees.map((emp) => _paymentService.getPaymentsByWorkerId(emp.id)),
    );
  }

  /// Tüm çalışanlar için avansları yükle
  Future<List<List<Advance>>> loadAllAdvances(List<Employee> employees) async {
    return await Future.wait(
      employees.map((emp) => _advanceService.getWorkerAdvances(emp.id)),
    );
  }

  /// Dönem içindeki masrafları yükle
  Future<List<Expense>> loadExpenses(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _expenseService.getExpensesByDateRange(startDate, endDate);
  }
}
