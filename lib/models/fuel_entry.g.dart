// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelEntryAdapter extends TypeAdapter<FuelEntry> {
  @override
  final int typeId = 5;

  @override
  FuelEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelEntry(
      id: fields[0] as String?,
      vehicleId: fields[1] as String,
      driverId: fields[2] as String?,
      date: fields[3] as DateTime,
      liters: fields[4] as double,
      pricePerLiter: fields[5] as double?,
      totalCost: fields[6] as double,
      vendor: fields[7] as String?,
      odometer: fields[8] as double?,
      shift: fields[9] as String?,
      receiptUrl: fields[10] as String?,
      notes: fields[11] as String?,
      odometerReading: fields[12] as double?,
      fuelType: fields[13] as String?,
      station: fields[14] as String?,
      receiptNumber: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelEntry obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.driverId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.liters)
      ..writeByte(5)
      ..write(obj.pricePerLiter)
      ..writeByte(6)
      ..write(obj.totalCost)
      ..writeByte(7)
      ..write(obj.vendor)
      ..writeByte(8)
      ..write(obj.odometer)
      ..writeByte(9)
      ..write(obj.shift)
      ..writeByte(10)
      ..write(obj.receiptUrl)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.odometerReading)
      ..writeByte(13)
      ..write(obj.fuelType)
      ..writeByte(14)
      ..write(obj.station)
      ..writeByte(15)
      ..write(obj.receiptNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
