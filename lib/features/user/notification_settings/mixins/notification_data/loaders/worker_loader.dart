import 'package:flutter/material.dart';
import '../../../../../../models/worker.dart';
import '../../../../../../services/worker_service.dart';
import '../../../../../../core/di/service_locator.dart';

/// Çalışan yükleme işlemlerini yöneten sınıf
class WorkerLoader {
  final WorkerService _workerService = getIt<WorkerService>();

  /// Çalışanları yükler
  Future<List<Worker>> loadWorkers() async {
    try {
      return await _workerService.getWorkers();
    } catch (e) {
      debugPrint('Çalışanlar yüklenirken hata: $e');
      rethrow;
    }
  }

  /// Çalışanları ve hatırlatıcıları filtreler
  static List<T> filterByQuery<T>(
    List<T> items,
    String query,
    String Function(T) getName,
  ) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return items
        .where((item) => getName(item).toLowerCase().contains(lowerQuery))
        .toList();
  }
}
