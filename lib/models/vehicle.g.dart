// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 14;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String?,
      registrationNumber: fields[1] as String,
      makeType: fields[2] as String,
      modelYear: fields[3] as String?,
      engineCC: fields[4] as double?,
      chassisNumber: fields[5] as String?,
      engineNumber: fields[6] as String?,
      color: fields[7] as String?,
      status: fields[8] as String,
      currentOdometer: fields[9] as double?,
      assignedDriver: fields[10] as String?,
      documents: (fields[11] as List?)?.cast<VehicleDocument>(),
      fuelType: fields[12] as String?,
      purchaseDate: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.registrationNumber)
      ..writeByte(2)
      ..write(obj.makeType)
      ..writeByte(3)
      ..write(obj.modelYear)
      ..writeByte(4)
      ..write(obj.engineCC)
      ..writeByte(5)
      ..write(obj.chassisNumber)
      ..writeByte(6)
      ..write(obj.engineNumber)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.currentOdometer)
      ..writeByte(10)
      ..write(obj.assignedDriver)
      ..writeByte(11)
      ..write(obj.documents)
      ..writeByte(12)
      ..write(obj.fuelType)
      ..writeByte(13)
      ..write(obj.purchaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleDocumentAdapter extends TypeAdapter<VehicleDocument> {
  @override
  final int typeId = 15;

  @override
  VehicleDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleDocument(
      type: fields[0] as String?,
      url: fields[1] as String?,
      expiryDate: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleDocument obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.expiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
