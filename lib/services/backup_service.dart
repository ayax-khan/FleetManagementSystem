// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../core/logger.dart';
import '../core/errors/app_exceptions.dart';
import '../core/constants.dart';
import 'hive_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _secureStorage = FlutterSecureStorage();

  // Create backup
  Future<String> createBackup({bool encrypted = true}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}${AppConfig.backupDirectory}');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '${backupDir.path}/fleet_backup_$timestamp.zip';

      // Close Hive to backup files
      await HiveService().close();

      // Zip Hive files
      final encoder = ZipFileEncoder();
      encoder.create(backupPath);

      // Add all Hive database files
      final hiveFiles = dir.listSync().where(
        (f) =>
            f.path.endsWith('.hive') ||
            f.path.endsWith('.lock') ||
            f.path.contains('.hive.'),
      );

      for (var file in hiveFiles) {
        if (file is File) {
          encoder.addFile(file);
        }
      }

      // Add configuration files if any
      final configFiles = dir.listSync().where(
        (f) => f.path.endsWith('.json') || f.path.endsWith('.config'),
      );

      for (var file in configFiles) {
        if (file is File) {
          encoder.addFile(file);
        }
      }

      encoder.close();

      // Update last backup timestamp
      await _secureStorage.write(
        key: 'last_backup_time',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Reopen Hive
      await HiveService().init();

      Logger.info('Created backup: $backupPath');
      return backupPath;
    } catch (e) {
      Logger.error('Backup creation failed', error: e);
      throw FileException('Backup creation failed: $e');
    }
  }

  // Restore from backup
  Future<void> restoreBackup(String path) async {
    try {
      // Validate backup file
      final backupFile = File(path);
      if (!await backupFile.exists()) {
        throw FileNotFoundException('Backup file not found: $path');
      }

      // Create restore directory
      final dir = await getApplicationDocumentsDirectory();
      final restoreDir = Directory(
        '${dir.path}/restore_${DateTime.now().millisecondsSinceEpoch}',
      );
      await restoreDir.create(recursive: true);

      // Close Hive
      await HiveService().close();

      // Extract zip
      final bytes = backupFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (var file in archive) {
        final filename = '${restoreDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // Validate restored files
      final restoredFiles = restoreDir.listSync();
      if (restoredFiles.isEmpty) {
        throw FileException('No files found in backup archive');
      }

      // Replace current database files with restored ones
      final currentFiles = dir.listSync().where(
        (f) => f.path.endsWith('.hive') || f.path.endsWith('.lock'),
      );

      // Backup current files before replacement
      final currentBackupDir = Directory(
        '${dir.path}/current_backup_${DateTime.now().millisecondsSinceEpoch}',
      );
      await currentBackupDir.create(recursive: true);

      for (var file in currentFiles) {
        if (file is File) {
          final backupFile = File(
            '${currentBackupDir.path}/${file.uri.pathSegments.last}',
          );
          await file.copy(backupFile.path);
        }
      }

      // Copy restored files to main directory
      for (var file in restoredFiles) {
        if (file is File) {
          final targetFile = File('${dir.path}/${file.uri.pathSegments.last}');
          await file.copy(targetFile.path);
        }
      }

      // Clean up restore directory
      await restoreDir.delete(recursive: true);

      // Reopen Hive
      await HiveService().init();

      Logger.info('Successfully restored from backup: $path');
    } catch (e) {
      Logger.error('Backup restoration failed', error: e);
      throw FileException('Backup restoration failed: $e');
    }
  }

  // Scheduled backup
  Future<void> scheduledBackup() async {
    try {
      final lastBackupTime = await _secureStorage.read(key: 'last_backup_time');
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lastBackupTime == null) {
        // First time backup
        await createBackup();
        return;
      }

      final lastBackup = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastBackupTime),
      );
      final hoursSinceLastBackup = DateTime.now()
          .difference(lastBackup)
          .inHours;

      if (hoursSinceLastBackup >= AppConfig.backupFrequency.inHours) {
        await createBackup();
        Logger.info('Scheduled backup completed');
      }
    } catch (e) {
      Logger.error('Scheduled backup failed', error: e);
      // Don't throw, just log for scheduled tasks
    }
  }

  // Share backup
  Future<void> shareBackup(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw FileNotFoundException('Backup file not found for sharing: $path');
      }

      await Share.shareXFiles([
        XFile(path),
      ], text: 'FleetMaster Backup - ${DateTime.now()}');
      Logger.info('Backup shared: $path');
    } catch (e) {
      Logger.error('Backup sharing failed', error: e);
      throw FileException('Backup sharing failed: $e');
    }
  }

  // Get backup list
  Future<List<BackupInfo>> getBackupList() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}${AppConfig.backupDirectory}');

      if (!await backupDir.exists()) {
        return [];
      }

      final backupFiles = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      final backupList = <BackupInfo>[];

      for (var file in backupFiles) {
        final stat = await file.stat();
        backupList.add(
          BackupInfo(
            path: file.path,
            size: stat.size,
            modified: stat.modified,
            name: file.uri.pathSegments.last,
          ),
        );
      }

      // Sort by modification time (newest first)
      backupList.sort((a, b) => b.modified.compareTo(a.modified));

      return backupList;
    } catch (e) {
      Logger.error('Failed to get backup list', error: e);
      throw FileException('Failed to get backup list: $e');
    }
  }

  // Delete backup
  Future<void> deleteBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        Logger.info('Backup deleted: $path');
      }
    } catch (e) {
      Logger.error('Failed to delete backup: $path', error: e);
      throw FileException('Failed to delete backup: $e');
    }
  }

  // Get backup statistics
  Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final backups = await getBackupList();
      final totalSize = backups.fold<int>(
        0,
        (sum, backup) => sum + backup.size,
      );
      final oldestBackup = backups.isNotEmpty ? backups.last.modified : null;
      final newestBackup = backups.isNotEmpty ? backups.first.modified : null;

      return {
        'totalBackups': backups.length,
        'totalSize': totalSize,
        'oldestBackup': oldestBackup,
        'newestBackup': newestBackup,
        'averageSize': backups.isNotEmpty ? totalSize ~/ backups.length : 0,
      };
    } catch (e) {
      Logger.error('Failed to get backup stats', error: e);
      throw FileException('Failed to get backup stats: $e');
    }
  }

  // Validate backup file
  Future<bool> validateBackup(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Check if archive contains Hive files
      final hasHiveFiles = archive.files.any(
        (file) => file.name.endsWith('.hive'),
      );

      return hasHiveFiles && archive.files.isNotEmpty;
    } catch (e) {
      Logger.error('Backup validation failed: $path', error: e);
      return false;
    }
  }

  // Auto cleanup old backups
  Future<void> cleanupOldBackups({int keepLast = 10}) async {
    try {
      final backups = await getBackupList();

      if (backups.length > keepLast) {
        final backupsToDelete = backups.sublist(keepLast);

        for (final backup in backupsToDelete) {
          await deleteBackup(backup.path);
        }

        Logger.info('Cleaned up ${backupsToDelete.length} old backups');
      }
    } catch (e) {
      Logger.error('Backup cleanup failed', error: e);
      // Don't throw for cleanup operations
    }
  }

  // Export settings only
  Future<String> exportSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final settingsPath = '${dir.path}/settings_backup_$timestamp.json';

      // Export app configuration and user preferences
      final settings = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': Constants.appVersion,
        'backupVersion': '1.0',
        'settings': {
          // Add app settings here
          'theme': 'light',
          'language': 'en',
          'autoBackup': true,
        },
      };

      final settingsFile = File(settingsPath);
      await settingsFile.writeAsString(json.encode(settings));

      return settingsPath;
    } catch (e) {
      Logger.error('Settings export failed', error: e);
      throw FileException('Settings export failed: $e');
    }
  }

  // Import settings
  Future<void> importSettings(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw FileNotFoundException('Settings file not found: $path');
      }

      final content = await file.readAsString();
      final settings = json.decode(content) as Map<String, dynamic>;

      // Validate settings file
      if (settings['backupVersion'] == null) {
        throw ValidationException({'file': 'Invalid settings file format'});
      }

      // Apply settings
      // Implementation depends on your app's settings structure

      Logger.info('Settings imported successfully');
    } catch (e) {
      Logger.error('Settings import failed', error: e);
      throw FileException('Settings import failed: $e');
    }
  }
}

// Backup information class
class BackupInfo {
  final String path;
  final int size;
  final DateTime modified;
  final String name;

  BackupInfo({
    required this.path,
    required this.size,
    required this.modified,
    required this.name,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return '${modified.day}/${modified.month}/${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}';
  }
}
