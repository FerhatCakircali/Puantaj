/// Payment domain entity
/// Represents a payment record for an employee.
/// Independent of any data source or UI framework.
class Payment {
  final int id;
  final int employeeId;
  final DateTime period;
  final double amount;
  final double hoursWorked;
  final DateTime createdAt;
  final String? notes;

  const Payment({
    required this.id,
    required this.employeeId,
    required this.period,
    required this.amount,
    required this.hoursWorked,
    required this.createdAt,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Payment(id: $id, employeeId: $employeeId, amount: $amount, period: $period)';
}
