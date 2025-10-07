// lib/models/attendance.dart
import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 1)
class Attendance extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String driverId;

  @HiveField(2)
  String? vehicleId;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? shiftStart;

  @HiveField(5)
  String? shiftEnd;

  @HiveField(6)
  String status;

  @HiveField(7)
  double? overtimeHours;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  DateTime? checkIn; // Added missing field

  @HiveField(10)
  DateTime? checkOut; // Added missing field

  @HiveField(11)
  String? shift; // Added missing field

  @HiveField(12)
  double? hoursWorked; // Added missing field

  @HiveField(13)
  String? remarks; // Added missing field

  Attendance({
    this.id,
    required this.driverId,
    this.vehicleId,
    required this.date,
    this.shiftStart,
    this.shiftEnd,
    this.status = 'present',
    this.overtimeHours,
    this.notes,
    this.checkIn,
    this.checkOut,
    this.shift,
    this.hoursWorked,
    this.remarks,
  });
}
