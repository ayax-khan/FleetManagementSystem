// lib/core/logger.dart
import 'dart:developer' as dev;
import 'package:intl/intl.dart';

class Logger {
  static bool _isDebug = true; // Toggle for production

  static void setDebugMode(bool isDebug) {
    _isDebug = isDebug;
  }

  static String _getTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  static void info(String message, {String? tag}) {
    if (_isDebug) {
      dev.log('[INFO] ${tag ?? ''} ${_getTimestamp()}: $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (_isDebug) {
      dev.log('[WARNING] ${tag ?? ''} ${_getTimestamp()}: $message');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    dev.log(
      '[ERROR] ${tag ?? ''} ${_getTimestamp()}: $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String? tag}) {
    if (_isDebug) {
      dev.log('[DEBUG] ${tag ?? ''} ${_getTimestamp()}: $message');
    }
  }

  // Log Hive operations
  static void logHiveOpen(String boxName) {
    info('Opened Hive box: $boxName', tag: 'HIVE');
  }

  static void logHiveWrite(String boxName, String key) {
    debug('Wrote to Hive box $boxName with key $key', tag: 'HIVE');
  }

  static void logHiveError(String boxName, String error) {
    error;
    ('Hive error in box $boxName: $error', tag: 'HIVE');
  }

  // Log validation errors
  static void logValidationError(String field, String message) {
    warning('Validation failed for $field: $message', tag: 'VALIDATOR');
  }

  // Log CSV operations
  static void logCsvExport(String fileName, int rows) {
    info('Exported CSV: $fileName with $rows rows', tag: 'CSV');
  }

  static void logCsvImport(String fileName, int rows) {
    info('Imported CSV: $fileName with $rows rows', tag: 'CSV');
  }

  // Add more specific loggers as needed
}
