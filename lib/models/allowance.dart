// lib/models/allowance.dart
import 'package:hive/hive.dart';

part 'allowance.g.dart';

@HiveType(typeId: 0)
class Allowance extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String driverId;

  @HiveField(2)
  String type;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String? period;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? description;

  @HiveField(7)
  String status;

  @HiveField(8)
  String? approvedBy;

  @HiveField(9)
  String? receiptUrl;

  @HiveField(10)
  String? remarks; // Added missing field

  Allowance({
    this.id,
    required this.driverId,
    required this.type,
    required this.amount,
    this.period,
    required this.date,
    this.description,
    this.status = 'pending',
    this.approvedBy,
    this.receiptUrl,
    this.remarks,
  });
}
