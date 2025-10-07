// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 1;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      id: fields[0] as String?,
      driverId: fields[1] as String,
      vehicleId: fields[2] as String?,
      date: fields[3] as DateTime,
      shiftStart: fields[4] as String?,
      shiftEnd: fields[5] as String?,
      status: fields[6] as String,
      overtimeHours: fields[7] as double?,
      notes: fields[8] as String?,
      checkIn: fields[9] as DateTime?,
      checkOut: fields[10] as DateTime?,
      shift: fields[11] as String?,
      hoursWorked: fields[12] as double?,
      remarks: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.vehicleId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.shiftStart)
      ..writeByte(5)
      ..write(obj.shiftEnd)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.overtimeHours)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.checkIn)
      ..writeByte(10)
      ..write(obj.checkOut)
      ..writeByte(11)
      ..write(obj.shift)
      ..writeByte(12)
      ..write(obj.hoursWorked)
      ..writeByte(13)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
