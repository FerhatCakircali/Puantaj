import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart' as attendance_model;
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import '../../../services/pdf_service.dart';
import '../helpers/pdf_data_loader.dart';

/// Dönemsel genel rapor PDF oluşturucu
///
/// Tüm çalışanlar için dönemsel rapor oluşturur (isolate kullanarak).
class PeriodPdfGenerator {
  final PdfDataLoader _dataLoader;

  PeriodPdfGenerator({PdfDataLoader? dataLoader})
    : _dataLoader = dataLoader ?? PdfDataLoader();

  /// Dönemsel genel rapor oluştur
  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required String outputDirectory,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
    required ValueNotifier<double> progressNotifier,
  }) async {
    progressNotifier.value = 0.3;

    final allExpensesData = (await _dataLoader.loadExpenses(
      periodStart,
      periodEnd,
    )).map((e) => e.toMap()).toList();

    progressNotifier.value = 0.4;

    final allAttendancesData = (await _dataLoader.loadAllAttendances(
      employees,
      periodStart,
      periodEnd,
    )).map((list) => list.map((a) => a.toMap()).toList()).toList();

    progressNotifier.value = 0.5;

    final allPaymentsData = (await _dataLoader.loadAllPayments(
      employees,
    )).map((list) => list.map((p) => p.toMap()).toList()).toList();

    progressNotifier.value = 0.6;

    final allAdvancesData = (await _dataLoader.loadAllAdvances(
      employees,
    )).map((list) => list.map((a) => a.toMap()).toList()).toList();

    progressNotifier.value = 0.7;

    final filePath = await compute(_generateInIsolate, {
      'periodTitle': periodTitle,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'allAttendances': allAttendancesData,
      'allPayments': allPaymentsData,
      'allAdvances': allAdvancesData,
      'expenses': allExpensesData,
      'outputDirectory': outputDirectory,
      'robotoFontBytes': robotoFontBytes,
      'robotoBoldFontBytes': robotoBoldFontBytes,
    });

    progressNotifier.value = 0.9;

    return File(filePath);
  }

  /// Isolate içinde PDF oluştur
  static Future<String> _generateInIsolate(Map<String, dynamic> args) async {
    final periodTitle = args['periodTitle'] as String;
    final periodStart = DateTime.parse(args['periodStart'] as String);
    final periodEnd = DateTime.parse(args['periodEnd'] as String);
    final employees = (args['employees'] as List)
        .map((e) => Employee.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final allAttendances = (args['allAttendances'] as List)
        .map(
          (list) => (list as List)
              .map(
                (a) => attendance_model.Attendance.fromMap(
                  Map<String, dynamic>.from(a),
                ),
              )
              .toList(),
        )
        .toList();
    final allPayments = (args['allPayments'] as List)
        .map(
          (list) => (list as List)
              .map((p) => Payment.fromMap(Map<String, dynamic>.from(p)))
              .toList(),
        )
        .toList();
    final allAdvances = (args['allAdvances'] as List)
        .map(
          (list) => (list as List)
              .map((a) => Advance.fromMap(Map<String, dynamic>.from(a)))
              .toList(),
        )
        .toList();
    final expenses = (args['expenses'] as List)
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final outputDirectory = args['outputDirectory'] as String?;
    final robotoFontBytes = args['robotoFontBytes'] as Uint8List;
    final robotoBoldFontBytes = args['robotoBoldFontBytes'] as Uint8List;

    final file = await PdfService().generatePeriodGeneralReport(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      allAdvances: allAdvances,
      expenses: expenses,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );

    return file.path;
  }
}
