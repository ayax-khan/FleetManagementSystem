import 'package:flutter/foundation.dart';

class DebugUtils {
  static void log(String message, [String tag = 'FleetApp']) {
    if (kDebugMode) {
      print('[$tag] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] ${DateTime.now().toIso8601String()}: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  static void logAuth(String message) {
    log(message, 'AUTH');
  }

  static void logNavigation(String message) {
    log(message, 'NAVIGATION');
  }
}