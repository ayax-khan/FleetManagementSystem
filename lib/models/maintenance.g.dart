// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceAdapter extends TypeAdapter<Maintenance> {
  @override
  final int typeId = 7;

  @override
  Maintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Maintenance(
      id: fields[0] as String?,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      description: fields[3] as String?,
      cost: fields[4] as double?,
      vendor: fields[5] as String?,
      odometerAtMaintenance: fields[6] as double?,
      status: fields[7] as String?,
      partsReplaced: (fields[8] as List?)?.cast<String>(),
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Maintenance obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.cost)
      ..writeByte(5)
      ..write(obj.vendor)
      ..writeByte(6)
      ..write(obj.odometerAtMaintenance)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.partsReplaced)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
