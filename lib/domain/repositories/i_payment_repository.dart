import '../../core/error/result.dart';
import '../entities/payment.dart';

/// Payment repository interface
///
/// Defines contract for payment data operations.
abstract class IPaymentRepository {
  /// Get payments by employee ID
  Future<Result<List<Payment>>> getByEmployee(int employeeId);

  /// Get payments by period
  Future<Result<List<Payment>>> getByPeriod(DateTime start, DateTime end);

  /// Create new payment record
  Future<Result<Payment>> create(Payment payment);

  /// Update existing payment record
  Future<Result<Payment>> update(Payment payment);

  /// Calculate payment for employee in period
  Future<Result<double>> calculatePayment(
    int employeeId,
    DateTime start,
    DateTime end,
  );
}
