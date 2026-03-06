import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../widgets/screen_widgets/index.dart';

/// Rapor ekranı iş mantığı mixin'i
/// Rapor oluşturma, tarih seçimi ve veri hazırlama işlemlerini yönetir
/// Bu mixin, rapor işlemlerini modüler alt mixin'lere böler:
/// - ReportControllerDataMixin: Veri yükleme ve filtreleme
/// - ReportControllerDateMixin: Tarih seçimi işlemleri
/// - ReportControllerPdfMixin: PDF oluşturma işlemleri
/// - ReportControllerNotificationMixin: Bildirim işlemleri
mixin ReportControllerMixin<T extends StatefulWidget> on State<T> {
  // State
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  Map<int, Map<String, dynamic>> statsMap = {};
  bool isLoading = true;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  // Dönemsel rapor değişkenleri
  ReportPeriod selectedPeriodType = ReportPeriod.monthly;
  DateTime customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime customEndDate = DateTime.now();
  bool isEmployeeSpecific = false;
  Employee? selectedEmployee;

  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);

  @override
  void dispose() {
    progressNotifier.dispose();
    super.dispose();
  }
}
