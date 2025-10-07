// lib/config/app_config.dart
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../ui/theme.dart'; // Assuming theme.dart exists

class AppConfig {
  // App metadata
  static String get appName => Constants.appName;
  static String get appVersion => Constants.appVersion;

  // Environment flags
  static bool isDebugMode = true; // Set to false in production
  static bool isOfflineMode = false; // Toggle for offline-first

  // Database config
  static String get dbPath => 'fleet_db'; // Relative path

  // API endpoints if any (for future sync)
  static String apiBaseUrl = 'https://api.fleetmaster.com/v1';
  static String authEndpoint = '/auth/login';
  static String syncEndpoint = '/sync';

  // Security
  static bool enable2FA = true;
  static int sessionTimeoutMinutes = 30;

  // UI config
  static ThemeData get appTheme => AppTheme.lightTheme; // From theme.dart
  static double defaultPadding = 16.0;
  static double cardElevation = 4.0;

  // Import/Export config
  static List<String> supportedFileTypes = ['xlsx', 'csv', 'pdf'];
  static int maxImportRows = 10000;

  // Reporting config
  static String defaultCurrency = 'PKR';
  static double vatRate = 0.17; // 17% GST
  static List<String> reportTypes = ['daily', 'fuel', 'trips', 'attendance'];

  // Notification config
  static Duration reminderInterval = Duration(days: 7); // For expiries

  // Load config from env or file (if needed)
  static Future<void> loadConfig() async {
    // Example: Load from shared prefs or file
    // For now, static
  }

  // Set debug mode
  static void setDebug(bool debug) {
    isDebugMode = debug;
  }

  // More configs...
  // e.g., localization
  static Locale defaultLocale = Locale('en', 'PK');
  static List<Locale> supportedLocales = [Locale('en', 'PK'), Locale('ur')];

  // Fuel analytics thresholds
  static double anomalousFuelThreshold = 1.5; // 50% above avg

  // Backup config
  static String backupDirectory = Constants.backupPath;
  static Duration backupFrequency = Duration(days: 1);

  // User roles permissions
  static Map<String, List<String>> rolePermissions = {
    'admin': ['all'],
    'manager': ['read', 'write', 'delete'],
    'driver': ['read', 'write_trips'],
    'mechanic': ['read_vehicles', 'write_maintenance'],
    'finance': ['read_reports', 'write_allowances'],
  };

  // Check permission
  static bool hasPermission(String role, String permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }

  // Add more detailed configs as needed
  // For example, map sheet to entity for import
  static Map<String, String> sheetToEntityMap = {
    'Vehs': 'Vehicle',
    'Attendence': 'Attendance',
    'OT': 'Allowance', // Overtime
    'DR': 'TripLog', // Daily Reporting
    'Summary': 'Reporting', // Handled in reporting service
    'Summary Detail': 'TripLog',
    'WO & JO': 'JobOrder',
    'SPD Reporting': 'Maintenance',
    'Log Book': 'Maintenance',
    'Budget': 'Allowance', // Or separate budget entity
    'POL SOI & Ent': 'FuelEntry',
    'POL Utilized': 'FuelEntry',
    'POL Exp (Rs)': 'FuelEntry',
    'POL Monthly': 'FuelEntry',
    'POL (Rs)': 'FuelEntry',
    'POL Report': 'FuelEntry',
    'POL State': 'PolPrice',
    'Pvt Use': 'Allowance', // Private use
    'POL Prices': 'PolPrice',
    'Pvt School': 'Allowance', // School private
    'Routes': 'RouteModel',
  };

  // Detailed mapping for fields per sheet/entity can be here or in import_config
}
