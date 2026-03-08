import '../models/payment.dart';
import '../models/payment_summary.dart';
import '../models/attendance.dart';
import '../core/error_handling/error_handler_mixin.dart';
import '../core/di/service_locator.dart';
import 'auth_service.dart';
import 'payment/repositories/payment_repository.dart';
import 'payment/repositories/paid_days_repository.dart';
import 'payment/helpers/payment_calculator.dart';
import 'payment/helpers/payment_sync_helper.dart';
import 'payment/helpers/payment_user_helper.dart';
import 'payment/validators/payment_validator.dart';

/// Ödeme yönetimi servisi
class PaymentService with ErrorHandlerMixin {
  final PaymentRepository _repository;
  final PaidDaysRepository _paidDaysRepository;
  final PaymentCalculator _calculator;
  final PaymentSyncHelper _syncHelper;
  final PaymentUserHelper _userHelper;
  final PaymentValidator _validator;

  PaymentService({
    AuthService? authService,
    PaymentRepository? repository,
    PaidDaysRepository? paidDaysRepository,
    PaymentCalculator? calculator,
    PaymentSyncHelper? syncHelper,
    PaymentUserHelper? userHelper,
    PaymentValidator? validator,
  }) : _repository = repository ?? getIt<PaymentRepository>(),
       _paidDaysRepository = paidDaysRepository ?? getIt<PaidDaysRepository>(),
       _calculator = calculator ?? PaymentCalculator(),
       _syncHelper = syncHelper ?? PaymentSyncHelper(),
       _userHelper =
           userHelper ?? PaymentUserHelper(authService ?? AuthService()),
       _validator = validator ?? PaymentValidator();

  /// Yeni ödeme ekler
  Future<int?> addPayment(Payment payment) async {
    int? tempPaymentId;

    try {
      _validator.validatePayment(payment);
      final userId = await _userHelper.getUserIdOrThrow();
      tempPaymentId = await _syncHelper.addPaymentWithSync(payment, userId);
      return tempPaymentId;
    } catch (e) {
      await _syncHelper.cleanupTempPayment(tempPaymentId);
      return handleErrorSync(
        () => throw e,
        null,
        context: 'PaymentService.addPayment',
      );
    }
  }

  /// Çalışana ait ödemeleri getirir
  Future<List<Payment>> getPaymentsByWorker(int workerId) async {
    return handleError(
      () async {
        _validator.validateWorkerId(workerId);
        return await _userHelper.executeWithUserId(
          (userId) => _repository.getPaymentsByWorker(workerId, userId),
          defaultValue: [],
        );
      },
      [],
      context: 'PaymentService.getPaymentsByWorker',
    );
  }

  /// Çalışana ait ödemeleri getirir (alias)
  Future<List<Payment>> getPaymentsByWorkerId(int workerId) async {
    return await getPaymentsByWorker(workerId);
  }

  /// Çalışanın ödenmemiş günlerini getirir
  Future<Map<String, int>> getUnpaidDays(int workerId) async {
    return handleError(
      () async {
        _validator.validateWorkerId(workerId);
        return await _userHelper.executeWithUserId((userId) async {
          final unpaidAttendance = await _paidDaysRepository
              .getUnpaidAttendance(userId: userId, workerId: workerId);
          return _calculator.calculateUnpaidDays(unpaidAttendance);
        }, defaultValue: {'fullDays': 0, 'halfDays': 0});
      },
      {'fullDays': 0, 'halfDays': 0},
      context: 'PaymentService.getUnpaidDays',
    );
  }

  /// Belirli bir ödemeyi hariç tutarak ödenmemiş günleri getirir
  Future<Map<String, int>> getUnpaidDaysExcludingPayment(
    int workerId,
    int excludePaymentId,
  ) async {
    return handleError(
      () async {
        _validator.validateWorkerId(workerId);
        _validator.validatePaymentId(excludePaymentId);
        return await _userHelper.executeWithUserId(
          (userId) => _paidDaysRepository.getUnpaidDaysExcludingPayment(
            userId: userId,
            workerId: workerId,
            excludePaymentId: excludePaymentId,
          ),
          defaultValue: {'fullDays': 0, 'halfDays': 0},
        );
      },
      {'fullDays': 0, 'halfDays': 0},
      context: 'PaymentService.getUnpaidDaysExcludingPayment',
    );
  }

  /// Günün ödenip ödenmediğini kontrol eder
  Future<bool> isDayPaid(
    int workerId,
    DateTime date,
    AttendanceStatus status,
  ) async {
    return handleError(
      () async {
        _validator.validateWorkerId(workerId);
        return await _userHelper.executeWithUserId((userId) {
          final statusStr = _calculator.attendanceStatusToString(status);
          return _paidDaysRepository.isDayPaid(
            userId: userId,
            workerId: workerId,
            date: date,
            status: statusStr,
          );
        }, defaultValue: false);
      },
      false,
      context: 'PaymentService.isDayPaid',
    );
  }

  /// Ödeme kaydını günceller
  Future<bool> updatePayment({
    required int paymentId,
    required int fullDays,
    required int halfDays,
    required double amount,
  }) async {
    return handleErrorWithThrow(
      () async {
        _validator.validatePaymentId(paymentId);

        if (fullDays < 0 || halfDays < 0) {
          throw ArgumentError('Gün sayıları negatif olamaz');
        }

        if (amount < 0) {
          throw ArgumentError('Ödeme tutarı negatif olamaz');
        }

        return await _repository.updatePayment(
          paymentId: paymentId,
          fullDays: fullDays,
          halfDays: halfDays,
          amount: amount,
        );
      },
      context: 'PaymentService.updatePayment',
      userMessage: 'Ödeme güncellenirken hata oluştu',
    );
  }

  /// Ödeme kaydını siler
  Future<bool> deletePayment(int paymentId) async {
    return handleErrorWithThrow(
      () async {
        _validator.validatePaymentId(paymentId);
        return await _repository.deletePayment(paymentId);
      },
      context: 'PaymentService.deletePayment',
      userMessage: 'Ödeme silinirken hata oluştu',
    );
  }

  /// Kullanıcının ödeme geçmişini getirir
  Future<List<Map<String, dynamic>>> getUserPaymentHistory({
    required DateTime startDate,
    required DateTime endDate,
    String? workerNameFilter,
  }) async {
    return handleError(
      () async {
        _validator.validateDateRange(startDate, endDate);
        return await _userHelper.executeWithUserId((userId) async {
          final combined = await _repository.getUserPaymentHistory(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          );

          if (workerNameFilter != null && workerNameFilter.isNotEmpty) {
            return combined.where((item) {
              final workerName = item['workers']['full_name'] as String;
              return workerName.toLowerCase().contains(
                workerNameFilter.toLowerCase(),
              );
            }).toList();
          }

          return combined;
        }, defaultValue: []);
      },
      [],
      context: 'PaymentService.getUserPaymentHistory',
    );
  }

  /// Ödeme özet bilgilerini getirir
  Future<PaymentSummary?> getPaymentSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return handleError(
      () async {
        _validator.validateDateRange(startDate, endDate);
        return await _userHelper.executeWithUserIdOrThrow(
          (userId) => _repository.getPaymentSummary(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          ),
        );
      },
      null,
      context: 'PaymentService.getPaymentSummary',
    );
  }
}
