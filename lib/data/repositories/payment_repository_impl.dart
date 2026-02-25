import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/payment_model.dart';

/// Payment repository implementation
///
/// Implements IPaymentRepository using Supabase as data source.
/// Handles all payment data operations with proper error handling.
class PaymentRepositoryImpl implements IPaymentRepository {
  final SupabaseDataSource _dataSource;

  PaymentRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Payment>>> getByEmployee(int employeeId) async {
    try {
      final response = await _dataSource.queryList(
        'payments',
        filters: {'employee_id': employeeId},
      );

      final payments = response
          .map((json) => PaymentModel.fromJson(json).toEntity())
          .toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch payments: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<Payment>>> getByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Use client for complex date range query
      final response = await _dataSource.client
          .from('payments')
          .select()
          .gte('period', start.toIso8601String())
          .lte('period', end.toIso8601String())
          .order('period', ascending: false);

      final payments = (response as List)
          .map((json) => PaymentModel.fromJson(json).toEntity())
          .toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch payments by period: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Payment>> create(Payment payment) async {
    try {
      final data = PaymentModel.fromEntity(payment);

      // Remove id for insert operation
      final insertData = Map<String, dynamic>.from(data)..remove('id');

      final response = await _dataSource.insert('payments', insertData);

      final createdPayment = PaymentModel.fromJson(response).toEntity();
      return Success(createdPayment);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to create payment: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Payment>> update(Payment payment) async {
    try {
      final data = PaymentModel.fromEntity(payment);

      final response = await _dataSource.update(
        'payments',
        payment.id.toString(),
        data,
      );

      final updatedPayment = PaymentModel.fromJson(response).toEntity();
      return Success(updatedPayment);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to update payment: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<double>> calculatePayment(
    int employeeId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Get employee's daily wage
      final employeeResponse = await _dataSource.query('employees', {
        'id': employeeId,
      });

      if (employeeResponse == null) {
        return Failure(
          NotFoundException('Employee with id $employeeId not found'),
        );
      }

      final dailyWage = (employeeResponse['daily_wage'] as num).toDouble();

      // Get attendance records for the period
      final attendanceResponse = await _dataSource.client
          .from('attendance')
          .select('hours_worked')
          .eq('employee_id', employeeId)
          .eq('status', 'approved')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      // Calculate total hours worked
      double totalHours = 0.0;
      for (final record in attendanceResponse as List) {
        totalHours += (record['hours_worked'] as num).toDouble();
      }

      // Calculate payment: (total hours / 8) * daily wage
      final totalDays = totalHours / 8.0;
      final totalPayment = totalDays * dailyWage;

      return Success(totalPayment);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to calculate payment: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
