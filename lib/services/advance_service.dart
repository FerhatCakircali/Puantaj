import '../models/advance.dart';
import '../core/error_handling/error_handler_mixin.dart';
import 'auth_service.dart';
import 'advance/repositories/advance_repository.dart';
import 'shared/base_user_helper.dart';

/// Avans yönetimi servisi
class AdvanceService with ErrorHandlerMixin {
  final AdvanceRepository _repository;
  final BaseUserHelper _userHelper;

  AdvanceService({
    AuthService? authService,
    AdvanceRepository? repository,
    BaseUserHelper? userHelper,
  }) : _repository = repository ?? AdvanceRepository(),
       _userHelper = userHelper ?? BaseUserHelper(authService ?? AuthService());

  Future<List<Advance>> getAdvances() async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getAdvances(userId),
        defaultValue: [],
      ),
      [],
      context: 'AdvanceService.getAdvances',
    );
  }

  Future<List<Advance>> getWorkerAdvances(int workerId) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getWorkerAdvances(userId, workerId),
        defaultValue: [],
      ),
      [],
      context: 'AdvanceService.getWorkerAdvances',
    );
  }

  Future<double> getWorkerPendingAdvances(int workerId) async {
    return handleError(
      () async => await _repository.getWorkerPendingAdvances(workerId),
      0.0,
      context: 'AdvanceService.getWorkerPendingAdvances',
    );
  }

  Future<int> addAdvance(Advance advance) async {
    return handleErrorWithThrow(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.addAdvance(advance, userId),
        defaultValue: -1,
      ),
      context: 'AdvanceService.addAdvance',
      userMessage: 'Avans eklenirken hata oluştu',
    );
  }

  Future<int> updateAdvance(Advance advance) async {
    return handleErrorWithThrow(
      () async => await _userHelper.executeWithUserId((userId) async {
        final success = await _repository.updateAdvance(advance, userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      context: 'AdvanceService.updateAdvance',
      userMessage: 'Avans güncellenirken hata oluştu',
    );
  }

  Future<int> deleteAdvance(int id) async {
    return handleErrorWithThrow(
      () async => await _userHelper.executeWithUserId((userId) async {
        final success = await _repository.deleteAdvance(id, userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      context: 'AdvanceService.deleteAdvance',
      userMessage: 'Avans silinirken hata oluştu',
    );
  }

  /// Çalışanın toplam avanslarını getir
  Future<double> getWorkerTotalAdvances(int workerId) async {
    return handleError(
      () async {
        final advances = await getWorkerAdvances(workerId);
        double total = 0.0;
        for (var advance in advances) {
          total += advance.amount;
        }
        return total;
      },
      0.0,
      context: 'AdvanceService.getWorkerTotalAdvances',
    );
  }

  /// Avansı ödendi olarak işaretle
  Future<bool> markAsDeducted(int advanceId, int paymentId) async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        final advance = (await _repository.getAdvances(
          userId,
        )).firstWhere((a) => a.id == advanceId);

        final updatedAdvance = Advance(
          id: advance.id,
          userId: advance.userId,
          workerId: advance.workerId,
          amount: advance.amount,
          advanceDate: advance.advanceDate,
          description: advance.description,
          isDeducted: true,
          deductedFromPaymentId: paymentId,
        );

        return await _repository.updateAdvance(updatedAdvance, userId);
      }, defaultValue: false),
      false,
      context: 'AdvanceService.markAsDeducted',
    );
  }
}
