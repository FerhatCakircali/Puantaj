import '../../../../models/advance.dart';
import '../../../../models/employee.dart';
import '../../../../services/advance_service.dart';
import '../../../../services/worker_service.dart';
import '../../../../data/local/hive_service.dart';
import '../../../../core/di/service_locator.dart';

/// Avans ekranı iş mantığı kontrolcüsü
class AdvanceController {
  final AdvanceService _advanceService;
  final WorkerService _workerService;
  final HiveService _hiveService;

  AdvanceController({
    AdvanceService? advanceService,
    WorkerService? workerService,
    HiveService? hiveService,
  }) : _advanceService = advanceService ?? getIt<AdvanceService>(),
       _workerService = workerService ?? getIt<WorkerService>(),
       _hiveService = hiveService ?? getIt<HiveService>();

  /// Tüm avansları ve istatistikleri yükler
  Future<AdvanceData> loadAdvanceData() async {
    final cachedEmployees = _hiveService.employees.values.toList();

    if (cachedEmployees.isNotEmpty) {
      // Arka planda gerçek veriyi çek (non-blocking)
      _loadDataInBackground();

      // Cache'den hızlı sonuç döndür
      final advances = await _advanceService.getAdvances();
      return _processAdvanceData(advances, cachedEmployees);
    }

    // Cache yoksa normal yükle
    final advances = await _advanceService.getAdvances();
    final employees = await _workerService.getEmployees();
    return _processAdvanceData(advances, employees);
  }

  /// Arka planda veri güncelle (non-blocking)
  Future<void> _loadDataInBackground() async {
    try {
      await _workerService.getEmployees();
    } catch (e) {
      // Sessizce başarısız ol
    }
  }

  /// Avans verilerini işle
  AdvanceData _processAdvanceData(
    List<Advance> advances,
    List<Employee> employees,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Tek loop'ta tüm hesaplamaları yap (daha performanslı)
    double monthlyTotal = 0;
    double overallTotal = 0;
    final uniqueWorkerIds = <int>{};

    for (var advance in advances) {
      overallTotal += advance.amount;
      uniqueWorkerIds.add(advance.workerId);

      if (advance.advanceDate.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          advance.advanceDate.isBefore(
            endOfMonth.add(const Duration(days: 1)),
          )) {
        monthlyTotal += advance.amount;
      }
    }

    // Avans alan çalışan sayısı
    final workerCount = uniqueWorkerIds.length;

    // Ortalama avans
    final averageAdvance = workerCount > 0 ? overallTotal / workerCount : 0.0;

    return AdvanceData(
      advances: advances,
      employees: employees,
      monthlyTotal: monthlyTotal,
      overallTotal: overallTotal,
      workerCount: workerCount,
      averageAdvance: averageAdvance,
    );
  }

  /// Avansları çalışan adına göre filtreler
  List<Advance> filterAdvances(
    List<Advance> advances,
    List<Employee> employees,
    String query,
  ) {
    if (query.isEmpty) {
      return advances;
    }

    // Çalışan ID'lerini ada göre filtrele
    final filteredEmployeeIds = employees
        .where(
          (employee) =>
              employee.name.toLowerCase().contains(query.toLowerCase()),
        )
        .map((e) => e.id)
        .toSet();

    // Avansları filtrelenmiş çalışan ID'lerine göre filtrele
    return advances
        .where((advance) => filteredEmployeeIds.contains(advance.workerId))
        .toList();
  }

  /// Çalışan adını ID'den bulur
  String getWorkerName(int workerId, List<Employee> employees) {
    try {
      return employees.firstWhere((e) => e.id == workerId).name;
    } catch (e) {
      return 'Bilinmeyen Çalışan';
    }
  }

  /// Avans ekle
  Future<void> addAdvance(Advance advance) async {
    await _advanceService.addAdvance(advance);
  }

  /// Avans güncelle
  Future<void> updateAdvance(Advance advance) async {
    await _advanceService.updateAdvance(advance);
  }

  /// Avans sil
  Future<void> deleteAdvance(int advanceId) async {
    await _advanceService.deleteAdvance(advanceId);
  }

  /// Çalışanın bekleyen avanslarını getir
  Future<double> getWorkerPendingAdvances(int workerId) async {
    return await _advanceService.getWorkerPendingAdvances(workerId);
  }

  /// Çalışanın toplam avanslarını getir
  Future<double> getWorkerTotalAdvances(int workerId) async {
    return await _advanceService.getWorkerTotalAdvances(workerId);
  }
}

/// Avans verisi model sınıfı
class AdvanceData {
  final List<Advance> advances;
  final List<Employee> employees;
  final double monthlyTotal;
  final double overallTotal;
  final int workerCount;
  final double averageAdvance;

  AdvanceData({
    required this.advances,
    required this.employees,
    required this.monthlyTotal,
    required this.overallTotal,
    required this.workerCount,
    required this.averageAdvance,
  });
}
