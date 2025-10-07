// lib/core/constants.dart
class Constants {
  // Hive box names
  static const String vehicleBox = 'vehicles';
  static const String driverBox = 'drivers';
  static const String jobOrderBox = 'jobOrders';
  static const String tripLogBox = 'tripLogs';
  static const String fuelEntryBox = 'fuelEntries';
  static const String attendanceBox = 'attendances';
  static const String routeBox = 'routes';
  static const String allowanceBox = 'allowances';
  static const String userBox = 'users';
  static const String auditLogBox = 'auditLogs';
  static const String polPriceBox = 'polPrices';
  static const String maintenanceBox = 'maintenances';

  // Status enums as lists
  static const List<String> vehicleStatuses = [
    'active',
    'maintenance',
    'inactive',
    'assigned',
  ];
  static const List<String> driverStatuses = ['active', 'on_leave', 'inactive'];
  static const List<String> jobStatuses = [
    'pending',
    'assigned',
    'ongoing',
    'completed',
    'cancelled',
  ];
  static const List<String> tripStatuses = ['ongoing', 'completed', 'approved'];
  static const List<String> attendanceStatuses = [
    'present',
    'absent',
    'half_day',
    'leave',
  ];
  static const List<String> allowanceTypes = [
    'conveyance',
    'overtime',
    'reimbursement',
    'private_use',
    'other',
  ];
  static const List<String> allowanceStatuses = [
    'pending',
    'approved',
    'rejected',
    'paid',
  ];
  static const List<String> shiftTypes = ['morning', 'evening', 'night'];

  // App settings
  static const String appName = 'FleetMaster';
  static const String appVersion = '1.0.0';
  static const int hiveEncryptionKeyLength = 32; // For Hive encryption

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Fuel types
  static const List<String> fuelTypes = ['petrol', 'diesel'];

  // Default averages (km/l)
  static const double defaultPetrolAvg = 12.0;
  static const double defaultDieselAvg = 8.0;

  // Budget limits (example)
  static const double monthlyFuelBudget = 1000000.0; // Rs

  // File paths
  static const String backupPath = '/backups/';
  static const String exportPath = '/exports/';

  // Error messages
  static const String invalidData = 'Invalid data provided';
  static const String networkError = 'Network error occurred';
  static const String hiveError = 'Database error';

  // Roles
  static const List<String> userRoles = [
    'admin',
    'manager',
    'driver',
    'mechanic',
    'finance',
  ];

  // Add more constants as needed, e.g., API keys if any, colors, etc.
}
