import 'package:hive/hive.dart';
import '../../../models/worker.dart';

/// Worker modeli için Hive TypeAdapter
/// Offline-first mimari için worker verilerini yerel olarak saklar.
/// Type ID: 1
class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 1;

  @override
  Worker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Worker(
      id: fields[0] as int?,
      userId: fields[1] as int,
      username: fields[2] as String,
      fullName: fields[3] as String,
      title: fields[4] as String?,
      phone: fields[5] as String?,
      email: fields[6] as String?,
      startDate: fields[7] as String,
      createdAt: fields[8] != null ? DateTime.parse(fields[8] as String) : null,
    );
  }

  @override
  void write(BinaryWriter writer, Worker obj) {
    writer
      ..writeByte(9) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.fullName)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.createdAt?.toIso8601String());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
