// lib/models/vehicle.dart
import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 14)
class Vehicle extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String registrationNumber;

  @HiveField(2)
  String makeType;

  @HiveField(3)
  String? modelYear;

  @HiveField(4)
  double? engineCC; // Changed from String to double

  @HiveField(5)
  String? chassisNumber;

  @HiveField(6)
  String? engineNumber;

  @HiveField(7)
  String? color;

  @HiveField(8)
  String status;

  @HiveField(9)
  double? currentOdometer;

  @HiveField(10)
  String? assignedDriver;

  @HiveField(11)
  List<VehicleDocument>? documents;

  @HiveField(12)
  String? fuelType; // Added missing field

  @HiveField(13)
  DateTime? purchaseDate; // Added missing field

  Vehicle({
    this.id,
    required this.registrationNumber,
    required this.makeType,
    this.modelYear,
    this.engineCC,
    this.chassisNumber,
    this.engineNumber,
    this.color,
    this.status = 'active',
    this.currentOdometer,
    this.assignedDriver,
    this.documents,
    this.fuelType,
    this.purchaseDate,
  });
}

@HiveType(typeId: 15)
class VehicleDocument {
  @HiveField(0)
  String? type;

  @HiveField(1)
  String? url;

  @HiveField(2)
  DateTime? expiryDate;

  VehicleDocument({this.type, this.url, this.expiryDate});
}
