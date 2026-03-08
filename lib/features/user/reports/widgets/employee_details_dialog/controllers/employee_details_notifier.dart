import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/base_loading_state.dart';

/// Çalışan detay dialog state
class EmployeeDetailsState with LoadingStateMixin {
  @override
  final bool isLoading;

  @override
  final String? errorMessage;

  final bool isGeneratingReport;
  final int fullDays;
  final int halfDays;
  final int absentDays;
  final List<DateTime> fullDayDates;
  final List<DateTime> halfDayDates;
  final List<DateTime> absentDayDates;
  final double totalPaid;
  final int paidFullDays;
  final int paidHalfDays;

  const EmployeeDetailsState({
    this.isLoading = true,
    this.errorMessage,
    this.isGeneratingReport = false,
    this.fullDays = 0,
    this.halfDays = 0,
    this.absentDays = 0,
    this.fullDayDates = const [],
    this.halfDayDates = const [],
    this.absentDayDates = const [],
    this.totalPaid = 0.0,
    this.paidFullDays = 0,
    this.paidHalfDays = 0,
  });

  EmployeeDetailsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isGeneratingReport,
    int? fullDays,
    int? halfDays,
    int? absentDays,
    List<DateTime>? fullDayDates,
    List<DateTime>? halfDayDates,
    List<DateTime>? absentDayDates,
    double? totalPaid,
    int? paidFullDays,
    int? paidHalfDays,
  }) {
    return EmployeeDetailsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isGeneratingReport: isGeneratingReport ?? this.isGeneratingReport,
      fullDays: fullDays ?? this.fullDays,
      halfDays: halfDays ?? this.halfDays,
      absentDays: absentDays ?? this.absentDays,
      fullDayDates: fullDayDates ?? this.fullDayDates,
      halfDayDates: halfDayDates ?? this.halfDayDates,
      absentDayDates: absentDayDates ?? this.absentDayDates,
      totalPaid: totalPaid ?? this.totalPaid,
      paidFullDays: paidFullDays ?? this.paidFullDays,
      paidHalfDays: paidHalfDays ?? this.paidHalfDays,
    );
  }
}

/// Çalışan detay dialog notifier
class EmployeeDetailsNotifier extends Notifier<EmployeeDetailsState> {
  @override
  EmployeeDetailsState build() {
    return const EmployeeDetailsState();
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setGeneratingReport(bool value) {
    state = state.copyWith(isGeneratingReport: value);
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
    state = state.copyWith(
      fullDays: fullDays,
      halfDays: halfDays,
      absentDays: absentDays,
      fullDayDates: fullDayDates,
      halfDayDates: halfDayDates,
      absentDayDates: absentDayDates,
    );
  }

  /// Ödeme verilerini günceller
  void updatePaymentData({
    required double totalPaid,
    required int paidFullDays,
    required int paidHalfDays,
  }) {
    state = state.copyWith(
      totalPaid: totalPaid,
      paidFullDays: paidFullDays,
      paidHalfDays: paidHalfDays,
    );
  }
}

/// Provider - her dialog instance için ayrı provider oluşturulmalı
final employeeDetailsNotifierProvider =
    NotifierProvider.autoDispose<EmployeeDetailsNotifier, EmployeeDetailsState>(
      () => EmployeeDetailsNotifier(),
    );
