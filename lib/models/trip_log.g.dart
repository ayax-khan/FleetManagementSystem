// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripLogAdapter extends TypeAdapter<TripLog> {
  @override
  final int typeId = 11;

  @override
  TripLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripLog(
      id: fields[0] as String?,
      jobOrderId: fields[1] as String?,
      vehicleId: fields[2] as String,
      driverId: fields[3] as String,
      startKm: fields[4] as double,
      endKm: fields[5] as double?,
      startTime: fields[6] as DateTime,
      endTime: fields[7] as DateTime?,
      routeTaken: fields[8] as String?,
      purpose: fields[9] as String?,
      attachments: (fields[10] as List?)?.cast<TripAttachment>(),
      status: fields[11] as String,
      route: fields[12] as String?,
      distance: fields[13] as double?,
      fuelUsed: fields[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TripLog obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jobOrderId)
      ..writeByte(2)
      ..write(obj.vehicleId)
      ..writeByte(3)
      ..write(obj.driverId)
      ..writeByte(4)
      ..write(obj.startKm)
      ..writeByte(5)
      ..write(obj.endKm)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.routeTaken)
      ..writeByte(9)
      ..write(obj.purpose)
      ..writeByte(10)
      ..write(obj.attachments)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.route)
      ..writeByte(13)
      ..write(obj.distance)
      ..writeByte(14)
      ..write(obj.fuelUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TripAttachmentAdapter extends TypeAdapter<TripAttachment> {
  @override
  final int typeId = 12;

  @override
  TripAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripAttachment(
      type: fields[0] as String?,
      url: fields[1] as String?,
      description: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TripAttachment obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
