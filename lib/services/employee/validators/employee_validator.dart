import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/validation/base_validator.dart';
import '../../../utils/date_formatter.dart';
import '../../../core/constants/database_constants.dart';

/// Çalışan validasyonlarını yapan sınıf
class EmployeeValidator extends BaseValidator {
  final SupabaseClient _supabase;

  EmployeeValidator(this._supabase);

  /// Çalışan ID'sini validate eder
  void validateEmployeeId(int id) {
    validateId(id, fieldName: 'Çalışan ID');
  }

  /// Belirli tarihten önce kayıt var mı kontrol eder
  Future<bool> hasRecordsBeforeDate(
    int userId,
    int workerId,
    DateTime date,
  ) async {
    return executeValidation(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);

        final attendanceResults = await _supabase
            .from(DatabaseConstants.attendanceTable)
            .select()
            .eq(DatabaseConstants.attendanceUserId, userId)
            .eq(DatabaseConstants.attendanceWorkerId, workerId)
            .lt(DatabaseConstants.attendanceDate, formattedDate)
            .limit(1);

        if (attendanceResults.isNotEmpty) {
          return true;
        }

        final paymentResults = await _supabase
            .from(DatabaseConstants.paidDaysTable)
            .select()
            .eq('user_id', userId)
            .eq('worker_id', workerId)
            .lt('date', formattedDate)
            .limit(1);

        return paymentResults.isNotEmpty;
      },
      false,
      context: 'EmployeeValidator.hasRecordsBeforeDate',
    );
  }
}
