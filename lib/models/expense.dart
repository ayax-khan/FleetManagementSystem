// lib/models/expense.dart
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 4)
class Expense extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String description;

  @HiveField(4)
  double amount;

  @HiveField(5)
  String? category;

  @HiveField(6)
  String? paymentMethod;

  @HiveField(7)
  String? receiptNumber;

  @HiveField(8)
  String? approvedBy;

  @HiveField(9)
  String status;

  @HiveField(10)
  String? vendor;

  @HiveField(11)
  String? notes;

  Expense({
    this.id,
    this.vehicleId,
    required this.date,
    required this.description,
    required this.amount,
    this.category,
    this.paymentMethod,
    this.receiptNumber,
    this.approvedBy,
    this.status = 'pending',
    this.vendor,
    this.notes,
  });
}
