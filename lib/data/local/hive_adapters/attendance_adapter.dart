import 'package:hive/hive.dart';
import '../../../models/attendance.dart';

/// Attendance modeli için Hive TypeAdapter
///
/// Offline-first mimari için attendance verilerini yerel olarak saklar.
/// Type ID: 0
class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 0;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Attendance(
      id: fields[0] as int?,
      userId: fields[1] as int,
      workerId: fields[2] as int,
      date: DateTime.parse(fields[3] as String),
      status: _statusFromInt(fields[4] as int),
      createdBy: fields[5] as String?,
      notificationSent: fields[6] as bool? ?? false,
      workerName: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(8) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.workerId)
      ..writeByte(3)
      ..write(obj.date.toIso8601String())
      ..writeByte(4)
      ..write(_statusToInt(obj.status))
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.notificationSent)
      ..writeByte(7)
      ..write(obj.workerName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  static AttendanceStatus _statusFromInt(int value) {
    return switch (value) {
      1 => AttendanceStatus.halfDay,
      2 => AttendanceStatus.fullDay,
      _ => AttendanceStatus.absent,
    };
  }

  static int _statusToInt(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.halfDay => 1,
      AttendanceStatus.fullDay => 2,
      AttendanceStatus.absent => 0,
    };
  }
}
