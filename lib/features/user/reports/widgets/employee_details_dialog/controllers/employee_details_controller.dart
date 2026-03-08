import 'package:flutter/material.dart';

/// Çalışan detay dialog'unun state yönetimini sağlar
///
/// Loading durumları, devam verileri ve ödeme bilgilerini yönetir.
class EmployeeDetailsController extends ChangeNotifier {
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  int _fullDays = 0;
  int _halfDays = 0;
  int _absentDays = 0;

  List<DateTime> _fullDayDates = [];
  List<DateTime> _halfDayDates = [];
  List<DateTime> _absentDayDates = [];

  double _totalPaid = 0.0;
  int _paidFullDays = 0;
  int _paidHalfDays = 0;

  bool get isLoading => _isLoading;
  bool get isGeneratingReport => _isGeneratingReport;

  int get fullDays => _fullDays;
  int get halfDays => _halfDays;
  int get absentDays => _absentDays;

  List<DateTime> get fullDayDates => _fullDayDates;
  List<DateTime> get halfDayDates => _halfDayDates;
  List<DateTime> get absentDayDates => _absentDayDates;

  double get totalPaid => _totalPaid;
  int get paidFullDays => _paidFullDays;
  int get paidHalfDays => _paidHalfDays;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setGeneratingReport(bool value) {
    _isGeneratingReport = value;
    notifyListeners();
  }

  /// Devam verilerini günceller
  void updateAttendanceData({
    required int fullDays,
    required int halfDays,
    required int absentDays,
    required List<DateTime> fullDayDates,
    required List<DateTime> halfDayDates,
    required List<DateTime> absentDayDates,
  }) {
    _fullDays = fullDays;
    _halfDays = halfDays;
    _absentDays = absentDays;
    _fullDayDates = fullDayDates;
    _halfDayDates = halfDayDates;
    _absentDayDates = absentDayDates;
    notifyListeners();
  }

  /// Ödeme verilerini günceller
  void updatePaymentData({
    required double totalPaid,
    required int paidFullDays,
    required int paidHalfDays,
  }) {
    _totalPaid = totalPaid;
    _paidFullDays = paidFullDays;
    _paidHalfDays = paidHalfDays;
    notifyListeners();
  }
}
