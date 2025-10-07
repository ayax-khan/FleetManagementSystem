// lib/models/user.dart
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 13)
class User extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String? role; // admin, manager, driver, etc.

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? hashedPassword; // For local auth, or token

  @HiveField(5)
  String? fullName;

  @HiveField(6)
  String? phone;

  @HiveField(7)
  DateTime? createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  @HiveField(9)
  bool isActive;

  User({
    this.id,
    required this.username,
    this.role,
    this.email,
    this.hashedPassword,
    this.fullName,
    this.phone,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });
}
