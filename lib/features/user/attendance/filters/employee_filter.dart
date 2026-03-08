import '../../../../models/employee.dart';

/// Çalışan filtreleme sınıfı
///
/// Çalışanları arama sorgusuna göre filtreler
class EmployeeFilter {
  /// Çalışanları arama sorgusuna göre filtreler
  static List<Employee> filter(List<Employee> employees, String query) {
    if (query.isEmpty) {
      return employees;
    }

    return employees
        .where(
          (employee) =>
              employee.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
