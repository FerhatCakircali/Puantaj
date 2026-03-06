import '../../domain/entities/payment.dart';

/// Payment data model
/// Maps database records to Payment domain entity.
class PaymentModel {
  final int id;
  final int employeeId;
  final String period;
  final double amount;
  final double hoursWorked;
  final String createdAt;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.employeeId,
    required this.period,
    required this.amount,
    required this.hoursWorked,
    required this.createdAt,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      period: json['period'] as String,
      amount: (json['amount'] as num).toDouble(),
      hoursWorked: (json['hours_worked'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      notes: json['notes'] as String?,
    );
  }

  Payment toEntity() {
    return Payment(
      id: id,
      employeeId: employeeId,
      period: DateTime.parse(period),
      amount: amount,
      hoursWorked: hoursWorked,
      createdAt: DateTime.parse(createdAt),
      notes: notes,
    );
  }

  static Map<String, dynamic> fromEntity(Payment payment) {
    return {
      'id': payment.id,
      'employee_id': payment.employeeId,
      'period': payment.period.toIso8601String(),
      'amount': payment.amount,
      'hours_worked': payment.hoursWorked,
      'created_at': payment.createdAt.toIso8601String(),
      'notes': payment.notes,
    };
  }
}
