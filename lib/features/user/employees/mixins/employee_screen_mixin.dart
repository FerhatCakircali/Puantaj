import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../services/worker_service.dart';

/// Çalışan ekranı iş mantığı mixin'i
/// Arama, filtreleme, sıralama ve CRUD operasyonlarını yönetir
mixin EmployeeScreenMixin<T extends StatefulWidget> on State<T> {
  // Servisler
  final WorkerService workerService = WorkerService();

  // State
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  bool isLoading = true;

  /// Türkçe alfabeye göre sıralama fonksiyonu
  int collateTurkish(String a, String b) {
    const turkishAlphabet = [
      'a',
      'b',
      'c',
      'ç',
      'd',
      'e',
      'f',
      'g',
      'ğ',
      'h',
      'ı',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'ö',
      'p',
      'r',
      's',
      'ş',
      't',
      'u',
      'ü',
      'v',
      'y',
      'z',
    ];

    final Map<String, int> alphabetOrder = {
      for (var i = 0; i < turkishAlphabet.length; i++) turkishAlphabet[i]: i,
    };

    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');

    final na = normalize(a);
    final nb = normalize(b);

    final minLen = na.length < nb.length ? na.length : nb.length;
    for (var i = 0; i < minLen; i++) {
      final ca = na[i];
      final cb = nb[i];
      final ia = alphabetOrder[ca] ?? -1;
      final ib = alphabetOrder[cb] ?? -1;
      if (ia != ib) {
        return ia.compareTo(ib);
      }
    }
    return na.length.compareTo(nb.length);
  }

  /// Çalışanları yükle
  Future<void> loadEmployees() async {
    if (!mounted) return;

    debugPrint('📋 EmployeeScreenMixin: Çalışanlar yükleniyor');

    try {
      final loadedEmployees = await workerService.getEmployees();
      loadedEmployees.sort((a, b) => collateTurkish(a.name, b.name));

      if (!mounted) return;

      setState(() {
        employees = loadedEmployees;
        filteredEmployees = loadedEmployees;
        isLoading = false;
      });

      debugPrint('✅ EmployeeScreenMixin: ${employees.length} çalışan yüklendi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Çalışan yükleme hatası: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  /// Çalışanları filtrele
  void filterEmployees(String query) {
    if (!mounted) return;

    debugPrint('🔍 EmployeeScreenMixin: Arama sorgusu: "$query"');

    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees
            .where(
              (employee) =>
                  employee.name.toLowerCase().contains(query.toLowerCase()) ||
                  employee.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });

    debugPrint(
      '✅ EmployeeScreenMixin: ${filteredEmployees.length} sonuç bulundu',
    );
  }

  /// Çalışan ekle
  Future<void> addEmployee(Employee employee) async {
    if (!mounted) return;

    debugPrint(
      '➕ EmployeeScreenMixin: Yeni çalışan ekleniyor: ${employee.name}',
    );

    try {
      await workerService.addEmployee(employee);
      await loadEmployees();

      debugPrint('✅ EmployeeScreenMixin: Çalışan başarıyla eklendi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Çalışan ekleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı adı kontrolü
  Future<bool> isUsernameExists(String username) async {
    debugPrint('🔍 EmployeeScreenMixin: Kullanıcı adı kontrolü: $username');

    try {
      final exists = await workerService.isUsernameExists(username);
      debugPrint('✅ EmployeeScreenMixin: Kullanıcı adı durumu: $exists');
      return exists;
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Kullanıcı adı kontrolü hatası: $e');
      return false;
    }
  }

  /// E-posta kontrolü
  Future<bool> isEmailExists(String email) async {
    debugPrint('🔍 EmployeeScreenMixin: E-posta kontrolü: $email');

    try {
      final exists = await workerService.isEmailExists(email);
      debugPrint('✅ EmployeeScreenMixin: E-posta durumu: $exists');
      return exists;
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: E-posta kontrolü hatası: $e');
      return false;
    }
  }

  /// Çalışan güncelle
  Future<void> updateEmployee(Employee employee) async {
    if (!mounted) return;

    debugPrint(
      '✏️ EmployeeScreenMixin: Çalışan güncelleniyor: ${employee.name}',
    );

    try {
      await workerService.updateEmployee(employee);
      await loadEmployees();

      debugPrint('✅ EmployeeScreenMixin: Çalışan başarıyla güncellendi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Çalışan güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Çalışan sil
  Future<void> deleteEmployee(int employeeId) async {
    if (!mounted) return;

    debugPrint('🗑️ EmployeeScreenMixin: Çalışan siliniyor: ID=$employeeId');

    try {
      await workerService.deleteEmployee(employeeId);
      await loadEmployees();

      debugPrint('✅ EmployeeScreenMixin: Çalışan başarıyla silindi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Çalışan silme hatası: $e');
      rethrow;
    }
  }

  /// Tüm çalışanları sil
  Future<void> deleteAllEmployees() async {
    if (!mounted) return;

    debugPrint('🗑️ EmployeeScreenMixin: TÜM çalışanlar siliniyor');

    try {
      await workerService.deleteAllEmployees();
      await loadEmployees();

      debugPrint('✅ EmployeeScreenMixin: Tüm çalışanlar başarıyla silindi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Toplu silme hatası: $e');
      rethrow;
    }
  }

  /// Tarihten önce kayıt var mı kontrol et
  Future<bool> hasRecordsBeforeDate(int employeeId, DateTime date) async {
    debugPrint(
      '🔍 EmployeeScreenMixin: Tarih öncesi kayıt kontrolü: ID=$employeeId, Tarih=$date',
    );

    try {
      final hasRecords = await workerService.hasRecordsBeforeDate(
        employeeId,
        date,
      );
      debugPrint('✅ EmployeeScreenMixin: Kayıt durumu: $hasRecords');
      return hasRecords;
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Kayıt kontrolü hatası: $e');
      return false;
    }
  }

  /// Tarihten önceki kayıtları sil
  Future<void> deleteRecordsBeforeDate(int employeeId, DateTime date) async {
    if (!mounted) return;

    debugPrint(
      '🗑️ EmployeeScreenMixin: Tarih öncesi kayıtlar siliniyor: ID=$employeeId, Tarih=$date',
    );

    try {
      await workerService.deleteRecordsBeforeDate(employeeId, date);
      debugPrint('✅ EmployeeScreenMixin: Tarih öncesi kayıtlar silindi');
    } catch (e) {
      debugPrint('❌ EmployeeScreenMixin: Kayıt silme hatası: $e');
      rethrow;
    }
  }
}
