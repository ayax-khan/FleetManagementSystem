// lib/services/hive_service.dart
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/hive_config.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/errors/app_exceptions.dart';
import '../models/audit_log.dart';

class HiveService {
  // Singleton
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Initialize
  Future<void> init() async {
    await initHive();
  }

  // Generic CRUD
  Future<void> add<T>(String boxName, T entity, {String? key}) async {
    try {
      final box = Hive.box<T>(boxName);
      key ??= _generateKey();
      await box.put(key, entity);
      Logger.logHiveWrite(boxName, key);
      _logAudit('create', boxName, key, null);
    } catch (e) {
      throw DatabaseException('Failed to add to $boxName: $e');
    }
  }

  Future<T?> get<T>(String boxName, String key) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.get(key);
    } catch (e) {
      throw DatabaseException('Failed to get from $boxName: $e');
    }
  }

  Future<List<T>> getAll<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.values.toList();
    } catch (e) {
      throw DatabaseException('Failed to get all from $boxName: $e');
    }
  }

  Future<void> update<T>(String boxName, String key, T entity) async {
    try {
      final box = Hive.box<T>(boxName);
      final old = box.get(key);
      await box.put(key, entity);
      Logger.logHiveWrite(boxName, key);
      _logAudit('update', boxName, key, _diff(old, entity));
    } catch (e) {
      throw DatabaseException('Failed to update in $boxName: $e');
    }
  }

  Future<void> delete<T>(String boxName, String key) async {
    try {
      final box = Hive.box<T>(boxName);
      await box.delete(key);
      _logAudit('delete', boxName, key, null);
    } catch (e) {
      throw DatabaseException('Failed to delete from $boxName: $e');
    }
  }

  // Query with filters
  Future<List<T>> query<T>(String boxName, bool Function(T) filter) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.values.where(filter).toList();
    } catch (e) {
      throw DatabaseException('Query failed in $boxName: $e');
    }
  }

  // Batch operations
  Future<void> batchAdd<T>(String boxName, List<T> entities) async {
    try {
      final box = Hive.box<T>(boxName);
      final map = {for (var e in entities) _generateKey(): e};
      await box.putAll(map);
      Logger.debug('Batch added ${entities.length} to $boxName');
    } catch (e) {
      throw DatabaseException('Batch add failed: $e');
    }
  }

  // Clear entire box
  Future<void> clearBox<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      await box.clear();
      Logger.info('Cleared box: $boxName');
    } catch (e) {
      throw DatabaseException('Failed to clear box $boxName: $e');
    }
  }

  // Get box size
  Future<int> getBoxSize<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.length;
    } catch (e) {
      throw DatabaseException('Failed to get box size for $boxName: $e');
    }
  }

  // Check if key exists
  Future<bool> containsKey<T>(String boxName, String key) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.containsKey(key);
    } catch (e) {
      throw DatabaseException('Failed to check key in $boxName: $e');
    }
  }

  // Get all keys
  Future<List<dynamic>> getKeys<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      return box.keys.toList();
    } catch (e) {
      throw DatabaseException('Failed to get keys from $boxName: $e');
    }
  }

  // Generate unique key (UUID like)
  String _generateKey() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        Random().nextInt(10000).toString();
  }

  // Diff for audit
  Map<String, dynamic>? _diff(dynamic old, dynamic newEntity) {
    if (old == null) return null;
    Map<String, dynamic> changes = {};

    // Simple generic diff - in real implementation, you'd want type-specific diffs
    try {
      if (old is Map && newEntity is Map) {
        // Handle Map objects
        final allKeys = {...old.keys, ...newEntity.keys};
        for (final key in allKeys) {
          if (old[key] != newEntity[key]) {
            changes[key.toString()] = {'old': old[key], 'new': newEntity[key]};
          }
        }
      } else {
        // For HiveObjects, compare by toString for simplicity
        // In production, you'd want proper field-by-field comparison
        if (old.toString() != newEntity.toString()) {
          changes['object'] = {
            'old': old.toString(),
            'new': newEntity.toString(),
          };
        }
      }
    } catch (e) {
      Logger.warning('Failed to compute diff', tag: 'HIVE');
    }

    return changes.isEmpty ? null : changes;
  }

  // Log audit
  void _logAudit(
    String action,
    String entityType,
    String entityId,
    Map<String, dynamic>? changes,
  ) {
    try {
      final audit = AuditLog(
        entityType: entityType,
        entityId: entityId,
        action: action,
        userId: 'system', // In real app, get from auth service
        timestamp: DateTime.now(),
        changes: changes,
      );
      add<AuditLog>(Constants.auditLogBox, audit);
    } catch (e) {
      Logger.error('Failed to log audit', error: e);
    }
  }

  // Watch for changes
  Stream<BoxEvent> watchBox<T>(String boxName, {String? key}) {
    try {
      return Hive.box<T>(boxName).watch(key: key);
    } catch (e) {
      throw DatabaseException('Failed to watch box $boxName: $e');
    }
  }

  // Listen to all changes in a box
  Stream<List<T>> watchAll<T>(String boxName) {
    try {
      final box = Hive.box<T>(boxName);
      return box.watch().map((event) => box.values.toList());
    } catch (e) {
      throw DatabaseException('Failed to watch all in $boxName: $e');
    }
  }

  // Compact box (reduces file size)
  Future<void> compactBox<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      await box.compact();
      Logger.debug('Compacted box: $boxName');
    } catch (e) {
      throw DatabaseException('Failed to compact box $boxName: $e');
    }
  }

  // Get box statistics
  Future<Map<String, dynamic>> getBoxStats<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      final size = box.length;
      final keys = box.keys.toList();

      return {
        'name': boxName,
        'size': size,
        'keys_count': keys.length,
        'isOpen': box.isOpen,
      };
    } catch (e) {
      throw DatabaseException('Failed to get stats for $boxName: $e');
    }
  }

  // Backup box to file
  Future<void> backupBox<T>(String boxName, String backupPath) async {
    try {
      // Implementation would depend on your backup strategy
      // This is a placeholder for backup logic
      Logger.info('Backup initiated for box: $boxName to $backupPath');
    } catch (e) {
      throw DatabaseException('Failed to backup box $boxName: $e');
    }
  }

  // Restore box from backup
  Future<void> restoreBox<T>(String boxName, String backupPath) async {
    try {
      // Implementation would depend on your backup strategy
      Logger.info('Restore initiated for box: $boxName from $backupPath');
    } catch (e) {
      throw DatabaseException('Failed to restore box $boxName: $backupPath');
    }
  }

  // Close service
  Future<void> close() async {
    try {
      await closeHive();
    } catch (e) {
      throw DatabaseException('Failed to close Hive service: $e');
    }
  }

  // Transaction-like operations (Hive doesn't support true transactions)
  Future<void> executeInBatch(Future<void> Function() operations) async {
    try {
      await operations();
    } catch (e) {
      // Note: Hive doesn't support rollback, so this is just error handling
      Logger.error('Batch operation failed', error: e);
      rethrow;
    }
  }

  // Search by field value (basic implementation)
  Future<List<T>> searchByField<T>(
    String boxName,
    String fieldName,
    dynamic value,
  ) async {
    try {
      final allItems = await getAll<T>(boxName);
      return allItems.where((item) {
        // This is a basic implementation - you'd need reflection for proper field access
        // or implement a toMap() method in your models
        final itemMap = _toMap(item);
        return itemMap[fieldName] == value;
      }).toList();
    } catch (e) {
      throw DatabaseException('Search failed in $boxName: $e');
    }
  }

  // Helper to convert object to map (basic implementation)
  Map<String, dynamic> _toMap(dynamic obj) {
    if (obj is Map) return Map<String, dynamic>.from(obj);
    // For HiveObjects, you'd need proper serialization
    // This is a simplified version
    try {
      return obj.toMap(); // Assuming your models have toMap() method
    } catch (e) {
      return {'toString': obj.toString()};
    }
  }
}
