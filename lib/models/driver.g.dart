// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverAdapter extends TypeAdapter<Driver> {
  @override
  final int typeId = 3;

  @override
  Driver read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Driver(
      id: fields[0] as String?,
      name: fields[1] as String,
      employeeId: fields[2] as String?,
      licenseNumber: fields[3] as String,
      licenseExpiry: fields[4] as DateTime?,
      phone: fields[5] as String?,
      emergencyContact: fields[6] as String?,
      status: fields[7] as String,
      assignedVehicle: fields[8] as String?,
      address: fields[9] as String?,
      joiningDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Driver obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.employeeId)
      ..writeByte(3)
      ..write(obj.licenseNumber)
      ..writeByte(4)
      ..write(obj.licenseExpiry)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.emergencyContact)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.assignedVehicle)
      ..writeByte(9)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.joiningDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
