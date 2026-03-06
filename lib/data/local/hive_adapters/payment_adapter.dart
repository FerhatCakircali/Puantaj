import 'package:hive/hive.dart';
import '../../../models/payment.dart';

/// Payment modeli için Hive TypeAdapter
/// 
/// Offline-first mimari için payment verilerini yerel olarak saklar.
/// Type ID: 2
class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 2;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Payment(
      id: fields[0] as int?,
      userId: fields[1] as int,
      workerId: fields[2] as int,
      fullDays: fields[3] as int,
      halfDays: fields[4] as int,
      paymentDate: DateTime.parse(fields[5] as String),
      amount: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(7) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.workerId)
      ..writeByte(3)
      ..write(obj.fullDays)
      ..writeByte(4)
      ..write(obj.halfDays)
      ..writeByte(5)
      ..write(obj.paymentDate.toIso8601String())
      ..writeByte(6)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
