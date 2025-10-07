// lib/models/driver.dart
import 'package:hive/hive.dart';

part 'driver.g.dart';

@HiveType(typeId: 3)
class Driver extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? employeeId;

  @HiveField(3)
  String licenseNumber;

  @HiveField(4)
  DateTime? licenseExpiry;

  @HiveField(5)
  String? phone;

  @HiveField(6)
  String? emergencyContact;

  @HiveField(7)
  String status;

  @HiveField(8)
  String? assignedVehicle;

  @HiveField(9)
  String? address; // Added missing field

  @HiveField(10)
  DateTime? joiningDate; // Added missing field

  Driver({
    this.id,
    required this.name,
    this.employeeId,
    required this.licenseNumber,
    this.licenseExpiry,
    this.phone,
    this.emergencyContact,
    this.status = 'active',
    this.assignedVehicle,
    this.address,
    this.joiningDate,
  });
}
