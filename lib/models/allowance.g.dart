// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allowance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AllowanceAdapter extends TypeAdapter<Allowance> {
  @override
  final int typeId = 0;

  @override
  Allowance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Allowance(
      id: fields[0] as String?,
      driverId: fields[1] as String,
      type: fields[2] as String,
      amount: fields[3] as double,
      period: fields[4] as String?,
      date: fields[5] as DateTime,
      description: fields[6] as String?,
      status: fields[7] as String,
      approvedBy: fields[8] as String?,
      receiptUrl: fields[9] as String?,
      remarks: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Allowance obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.approvedBy)
      ..writeByte(9)
      ..write(obj.receiptUrl)
      ..writeByte(10)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllowanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
