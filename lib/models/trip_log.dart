// lib/models/trip_log.dart
import 'package:hive/hive.dart';

part 'trip_log.g.dart';

@HiveType(typeId: 11)
class TripLog extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? jobOrderId;

  @HiveField(2)
  String vehicleId;

  @HiveField(3)
  String driverId;

  @HiveField(4)
  double startKm;

  @HiveField(5)
  double? endKm;

  @HiveField(6)
  DateTime startTime;

  @HiveField(7)
  DateTime? endTime;

  @HiveField(8)
  String? routeTaken;

  @HiveField(9)
  String? purpose;

  @HiveField(10)
  List<TripAttachment>? attachments;

  @HiveField(11)
  String status;

  @HiveField(12)
  String? route; // Added missing field

  @HiveField(13)
  double? distance; // Added missing field

  @HiveField(14)
  double? fuelUsed; // Added missing field

  TripLog({
    this.id,
    this.jobOrderId,
    required this.vehicleId,
    required this.driverId,
    required this.startKm,
    this.endKm,
    required this.startTime,
    this.endTime,
    this.routeTaken,
    this.purpose,
    this.attachments,
    this.status = 'ongoing',
    this.route,
    this.distance,
    this.fuelUsed,
  });
}

@HiveType(typeId: 12)
class TripAttachment {
  @HiveField(0)
  String? type;

  @HiveField(1)
  String? url;

  @HiveField(2)
  String? description;

  TripAttachment({this.type, this.url, this.description});
}
