// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final int typeId = 9;

  @override
  RouteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      stops: (fields[2] as List?)?.cast<RouteStop>(),
      estimatedDistanceKm: fields[3] as double?,
      estimatedTimeHours: fields[4] as double?,
      isActive: fields[5] as bool,
      description: fields[6] as String?,
      startPoint: fields[7] as String?,
      endPoint: fields[8] as String?,
      distance: fields[9] as double?,
      estimatedTime: fields[10] as String?,
      status: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stops)
      ..writeByte(3)
      ..write(obj.estimatedDistanceKm)
      ..writeByte(4)
      ..write(obj.estimatedTimeHours)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.startPoint)
      ..writeByte(8)
      ..write(obj.endPoint)
      ..writeByte(9)
      ..write(obj.distance)
      ..writeByte(10)
      ..write(obj.estimatedTime)
      ..writeByte(11)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteStopAdapter extends TypeAdapter<RouteStop> {
  @override
  final int typeId = 10;

  @override
  RouteStop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteStop(
      name: fields[0] as String?,
      address: fields[1] as String?,
      sequence: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RouteStop obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.sequence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteStopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
