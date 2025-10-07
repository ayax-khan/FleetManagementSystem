// lib/env.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Environment variables and constants
class Env {
  // Build mode
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;

  // API keys (use secure storage in production)
  static String get apiKey => isDebug ? 'debug_key' : 'prod_key';

  // Database config
  static String get hivePath => 'fleet_hive';

  // Versioning
  static String get appVersion => '1.0.0';
  static String get buildNumber => '1';

  // Flags
  static bool enableLogging = isDebug;
  static bool enableAnalytics = !isDebug;
  static bool offlineFirst = true;

  // URLs
  static String get baseUrl =>
      isDebug ? 'http://localhost:3000' : 'https://api.fleetmaster.com';

  // Colors (if not in theme)
  static Color primaryColor = Colors.blue[900]!;

  // Load from .env file if using (but Flutter doesn't support directly, use build flavors)
  static void loadEnv() {
    // Implement if using flutter_dotenv or similar
  }

  // Platform checks
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isDesktop => !isWeb && !isAndroid && !isIOS;

  // Feature flags
  static bool get enableGPS => false; // Future
  static bool get enable2FA => true;

  // Limits
  static int get maxImportSize => 100 * 1024 * 1024; // 100MB

  // Currencies
  static String get defaultCurrency => 'PKR';
  static double get exchangeRateUSD => 280.0; // Example

  // Timezones
  static String get defaultTimezone => 'Asia/Karachi';

  // More env vars: Secrets, configs
  static Map<String, dynamic> secrets = {
    'hiveEncryptionKey': 'secure_key', // Retrieve from secure storage
  };

  // Full env setup
}
