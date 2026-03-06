import '../../../domain/entities/attendance.dart';

/// Devam kaydı state'i
/// Attendance ekranının durumunu yönetir.
class AttendanceState {
  final List<Attendance> records;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  AttendanceState({
    this.records = const [],
    DateTime? selectedDate,
    this.isLoading = false,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// Initial state
  factory AttendanceState.initial() =>
      AttendanceState(selectedDate: DateTime.now());

  /// Copy with method
  AttendanceState copyWith({
    List<Attendance>? records,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
