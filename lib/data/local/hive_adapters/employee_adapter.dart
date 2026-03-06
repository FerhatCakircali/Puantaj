import 'package:hive/hive.dart';
import '../../../models/employee.dart';

/// Employee modeli için Hive TypeAdapter
/// Offline-first mimari için employee verilerini yerel olarak saklar.
/// Type ID: 3
class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 3;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Employee(
      id: fields[0] as int,
      userId: fields[1] as int,
      name: fields[2] as String,
      title: fields[3] as String,
      phone: fields[4] as String,
      email: fields[5] as String?,
      startDate: DateTime.parse(fields[6] as String),
      createdAt: fields[7] != null ? DateTime.parse(fields[7] as String) : null,
      username: fields[8] as String?,
      password: fields[9] as String?,
      isActive: fields[10] as bool? ?? true,
      isTrusted: fields[11] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(12) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.startDate.toIso8601String())
      ..writeByte(7)
      ..write(obj.createdAt?.toIso8601String())
      ..writeByte(8)
      ..write(obj.username)
      ..writeByte(9)
      ..write(obj.password)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.isTrusted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
