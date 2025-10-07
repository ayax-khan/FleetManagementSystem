// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobOrderAdapter extends TypeAdapter<JobOrder> {
  @override
  final int typeId = 6;

  @override
  JobOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobOrder(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String?,
      vehicleId: fields[3] as String?,
      driverId: fields[4] as String?,
      startDatetime: fields[5] as DateTime,
      endDatetime: fields[6] as DateTime?,
      status: fields[7] as String,
      routeId: fields[8] as String?,
      purpose: fields[9] as String?,
      costCenter: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JobOrder obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.vehicleId)
      ..writeByte(4)
      ..write(obj.driverId)
      ..writeByte(5)
      ..write(obj.startDatetime)
      ..writeByte(6)
      ..write(obj.endDatetime)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.routeId)
      ..writeByte(9)
      ..write(obj.purpose)
      ..writeByte(10)
      ..write(obj.costCenter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
