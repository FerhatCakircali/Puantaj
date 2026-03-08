import '../../../models/employee.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../utils/date_formatter.dart';
import '../constants/worker_constants.dart';

/// Employee modeli için backward compatibility repository
class EmployeeRepository extends BaseSupabaseRepository {
  EmployeeRepository(super.supabase);

  /// Yeni employee ekler
  ///
  /// [employee] Eklenecek employee
  /// [userId] Kullanıcı ID'si
  /// Returns: Eklenen employee'nin ID'si
  Future<int> insertEmployee(Employee employee, int userId) async {
    return executeQueryWithThrow(() async {
      final response = await supabase
          .from(WorkerConstants.tableName)
          .insert({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'email': employee.email,
            'start_date': DateFormatter.toIso8601Date(employee.startDate),
            'user_id': userId,
            'username':
                employee.username ??
                employee.name.toLowerCase().replaceAll(' ', ''),
            'password_hash': employee.password ?? 'default123',
          })
          .select('id');

      return response.first['id'] as int;
    }, context: 'EmployeeRepository.insertEmployee');
  }

  /// Employee bilgilerini günceller
  ///
  /// [employee] Güncellenecek employee
  /// [userId] Kullanıcı ID'si
  /// Returns: Güncellenen employee'nin ID'si
  Future<int> updateEmployee(Employee employee, int userId) async {
    return executeQueryWithThrow(() async {
      await supabase
          .from(WorkerConstants.tableName)
          .update({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'start_date': DateFormatter.toIso8601Date(employee.startDate),
            'is_active': employee.isActive,
            'is_trusted': employee.isTrusted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', employee.id)
          .eq(WorkerConstants.userIdColumn, userId);

      return employee.id;
    }, context: 'EmployeeRepository.updateEmployee');
  }

  /// Employee'yi siler
  ///
  /// [employeeId] Silinecek employee'nin ID'si
  /// [userId] Kullanıcı ID'si
  /// Returns: İşlem başarılı ise 1, başarısız ise -1
  Future<int> deleteEmployee(int employeeId, int userId) async {
    return executeQuery(
      () async {
        await supabase
            .from(WorkerConstants.tableName)
            .delete()
            .eq('id', employeeId)
            .eq(WorkerConstants.userIdColumn, userId);

        return 1;
      },
      -1,
      context: 'EmployeeRepository.deleteEmployee',
    );
  }
}
