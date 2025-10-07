// lib/models/audit_log.dart
import 'package:hive/hive.dart';

part 'audit_log.g.dart';

@HiveType(typeId: 2)
class AuditLog extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String entityType; // e.g., 'Vehicle', 'Driver'

  @HiveField(2)
  String entityId;

  @HiveField(3)
  String action; // create, update, delete

  @HiveField(4)
  String userId;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  Map<String, dynamic>? changes; // Old vs new values

  AuditLog({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.userId,
    required this.timestamp,
    this.changes,
  });
}
