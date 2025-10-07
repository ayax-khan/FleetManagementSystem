// lib/models/maintenance.dart  (Inferred from WO & JO sheet, not in schemas but mentioned in structure)
import 'package:hive/hive.dart';

part 'maintenance.g.dart';

@HiveType(typeId: 7)
class Maintenance extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? description;

  @HiveField(4)
  double? cost;

  @HiveField(5)
  String? vendor;

  @HiveField(6)
  double? odometerAtMaintenance;

  @HiveField(7)
  String? status; // pending, completed

  @HiveField(8)
  List<String>? partsReplaced;

  @HiveField(9)
  String? notes;

  Maintenance({
    this.id,
    required this.vehicleId,
    required this.date,
    this.description,
    this.cost,
    this.vendor,
    this.odometerAtMaintenance,
    this.status,
    this.partsReplaced,
    this.notes,
  });
}
