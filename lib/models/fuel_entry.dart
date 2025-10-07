// lib/models/fuel_entry.dart
import 'package:hive/hive.dart';

part 'fuel_entry.g.dart';

@HiveType(typeId: 5)
class FuelEntry extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  String? driverId;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  double liters;

  @HiveField(5)
  double? pricePerLiter;

  @HiveField(6)
  double totalCost;

  @HiveField(7)
  String? vendor;

  @HiveField(8)
  double? odometer;

  @HiveField(9)
  String? shift;

  @HiveField(10)
  String? receiptUrl;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  double? odometerReading; // Added missing field

  @HiveField(13)
  String? fuelType; // Added missing field

  @HiveField(14)
  String? station; // Added missing field

  @HiveField(15)
  String? receiptNumber; // Added missing field

  FuelEntry({
    this.id,
    required this.vehicleId,
    this.driverId,
    required this.date,
    required this.liters,
    this.pricePerLiter,
    required this.totalCost,
    this.vendor,
    this.odometer,
    this.shift,
    this.receiptUrl,
    this.notes,
    this.odometerReading,
    this.fuelType,
    this.station,
    this.receiptNumber,
  });
}
