// lib/models/job_order.dart
import 'package:hive/hive.dart';

part 'job_order.g.dart';

@HiveType(typeId: 6)
class JobOrder extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? vehicleId;

  @HiveField(4)
  String? driverId;

  @HiveField(5)
  DateTime startDatetime;

  @HiveField(6)
  DateTime? endDatetime;

  @HiveField(7)
  String status; // pending, assigned, ongoing, completed, cancelled

  @HiveField(8)
  String? routeId;

  @HiveField(9)
  String? purpose;

  @HiveField(10)
  String? costCenter;

  JobOrder({
    this.id,
    required this.title,
    this.description,
    this.vehicleId,
    this.driverId,
    required this.startDatetime,
    this.endDatetime,
    this.status = 'pending',
    this.routeId,
    this.purpose,
    this.costCenter,
  });
}
