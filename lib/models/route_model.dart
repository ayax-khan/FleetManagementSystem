// lib/models/route_model.dart
import 'package:hive/hive.dart';

part 'route_model.g.dart';

@HiveType(typeId: 9)
class RouteModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<RouteStop>? stops;

  @HiveField(3)
  double? estimatedDistanceKm;

  @HiveField(4)
  double? estimatedTimeHours;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  String? description; // Added missing field

  @HiveField(7)
  String? startPoint; // Added missing field

  @HiveField(8)
  String? endPoint; // Added missing field

  @HiveField(9)
  double? distance; // Added missing field

  @HiveField(10)
  String? estimatedTime; // Added missing field

  @HiveField(11)
  String? status; // Added missing field

  RouteModel({
    this.id,
    required this.name,
    this.stops,
    this.estimatedDistanceKm,
    this.estimatedTimeHours,
    this.isActive = true,
    this.description,
    this.startPoint,
    this.endPoint,
    this.distance,
    this.estimatedTime,
    this.status = 'active',
  });
}

@HiveType(typeId: 10)
class RouteStop {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? address;

  @HiveField(2)
  int? sequence;

  RouteStop({this.name, this.address, this.sequence});
}
