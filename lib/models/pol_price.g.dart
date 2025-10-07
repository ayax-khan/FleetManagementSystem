// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pol_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PolPriceAdapter extends TypeAdapter<PolPrice> {
  @override
  final int typeId = 8;

  @override
  PolPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PolPrice(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      petrolPrice: fields[2] as double,
      dieselPrice: fields[3] as double,
      pvtUseRatePetrol: fields[4] as double?,
      pvtUseRateDiesel: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, PolPrice obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.petrolPrice)
      ..writeByte(3)
      ..write(obj.dieselPrice)
      ..writeByte(4)
      ..write(obj.pvtUseRatePetrol)
      ..writeByte(5)
      ..write(obj.pvtUseRateDiesel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
