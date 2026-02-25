import '../models/employee.dart';

/// Çalışan filtreleme yardımcı sınıfı
/// Filtre ve arama mantığını yönetir
class EmployeeFilterHelper {
  /// Çalışanları filtre tipine göre filtrele
  static List<Employee> applyFilter(
    List<Employee> employees,
    String filterType,
  ) {
    final now = DateTime.now();

    switch (filterType) {
      case 'new':
        // Son 3 ay içinde başlayanlar
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        return employees
            .where((emp) => emp.startDate.isAfter(threeMonthsAgo))
            .toList();

      case 'senior':
        // 1 yıldan fazla çalışanlar
        final oneYearAgo = now.subtract(const Duration(days: 365));
        return employees
            .where((emp) => emp.startDate.isBefore(oneYearAgo))
            .toList();

      default:
        return employees;
    }
  }

  /// Çalışanları arama sorgusuna göre filtrele
  static List<Employee> applySearch(List<Employee> employees, String query) {
    if (query.isEmpty) {
      return employees;
    }

    final lowerQuery = query.toLowerCase();
    return employees.where((emp) {
      return emp.name.toLowerCase().contains(lowerQuery) ||
          emp.title.toLowerCase().contains(lowerQuery) ||
          emp.phone.contains(query);
    }).toList();
  }

  /// Filtre ve arama işlemlerini birlikte uygula
  static List<Employee> applyFilterAndSearch(
    List<Employee> employees,
    String filterType,
    String searchQuery,
  ) {
    var filtered = applyFilter(employees, filterType);
    filtered = applySearch(filtered, searchQuery);
    return filtered;
  }
}
