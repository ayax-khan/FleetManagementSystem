// lib/core/utils/csv_helpers.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fleet_management/models/driver.dart';
import 'package:fleet_management/models/fuel_entry.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../errors/app_exceptions.dart';
import '../../models/vehicle.dart'; // Import models as needed
// Add imports for other models

class CsvHelpers {
  // Export list of objects to CSV
  static Future<String> exportToCsv<T>(
    List<T> data,
    String fileName,
    List<String> headers,
    List<dynamic> Function(T) rowMapper,
  ) async {
    try {
      List<List<dynamic>> rows = [headers];
      for (var item in data) {
        rows.add(rowMapper(item));
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName.csv';
      final file = File(path);
      await file.writeAsString(csv);
      return path;
    } catch (e) {
      throw ExportException('Failed to export CSV: $e');
    }
  }

  // Example for Vehicles
  static Future<String> exportVehicles(List<Vehicle> vehicles) async {
    return exportToCsv<Vehicle>(
      vehicles,
      'vehicles',
      [
        'ID',
        'Registration',
        'Make Type',
        'Model Year',
        'Engine CC',
        'Status',
        'Odometer',
      ],
      (v) => [
        v.id,
        v.registrationNumber,
        v.makeType,
        v.modelYear,
        v.engineCC,
        v.status,
        v.currentOdometer,
      ],
    );
  }

  // Example for Drivers
  static Future<String> exportDrivers(List<Driver> drivers) async {
    return exportToCsv<Driver>(
      drivers,
      'drivers',
      [
        'ID',
        'Name',
        'Employee ID',
        'License Number',
        'License Expiry',
        'Phone',
        'Status',
        'Assigned Vehicle',
      ],
      (d) => [
        d.id,
        d.name,
        d.employeeId,
        d.licenseNumber,
        d.licenseExpiry?.toIso8601String(),
        d.phone,
        d.status,
        d.assignedVehicle,
      ],
    );
  }

  // Example for Fuel Entries
  static Future<String> exportFuelEntries(List<FuelEntry> fuelEntries) async {
    return exportToCsv<FuelEntry>(
      fuelEntries,
      'fuel_entries',
      [
        'ID',
        'Vehicle ID',
        'Date',
        'Liters',
        'Price Per Liter',
        'Total Cost',
        'Odometer',
        'Vendor',
      ],
      (f) => [
        f.id,
        f.vehicleId,
        f.date.toIso8601String(),
        f.liters,
        f.pricePerLiter,
        f.totalCost,
        f.odometer,
        f.vendor,
      ],
    );
  }

  // Import CSV to list of maps
  static Future<List<Map<String, dynamic>>> importFromCsv(String path) async {
    try {
      final file = File(path);
      final csvString = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
      if (rows.isEmpty) return [];
      List<String> headers = rows[0]
          .map((e) => e.toString().toLowerCase().replaceAll(' ', '_'))
          .toList();
      rows.removeAt(0);
      return rows.map((row) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < headers.length; i++) {
          if (i < row.length) {
            map[headers[i]] = row[i];
          }
        }
        return map;
      }).toList();
    } catch (e) {
      throw ImportException('Failed to import CSV: $e');
    }
  }

  // Pick CSV file
  static Future<String?> pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      return result?.files.single.path;
    } catch (e) {
      throw FileException('Failed to pick CSV file: $e');
    }
  }

  // Map CSV row to Vehicle (example)
  static Vehicle mapToVehicle(Map<String, dynamic> row) {
    return Vehicle(
      id: row['id']?.toString(),
      registrationNumber: row['registration_number']?.toString() ?? '',
      makeType: row['make_type']?.toString() ?? '',
      modelYear: row['model_year']?.toString(),
      engineCC: _parseDouble(row['engine_cc']),
      chassisNumber: row['chassis_number']?.toString(),
      engineNumber: row['engine_number']?.toString(),
      color: row['color']?.toString(),
      status: row['status']?.toString() ?? 'active',
      currentOdometer: _parseDouble(row['current_odometer']),
      fuelType: row['fuel_type']?.toString(),
      purchaseDate: _parseDate(row['purchase_date']),
    );
  }

  // Map CSV row to Driver
  static Driver mapToDriver(Map<String, dynamic> row) {
    return Driver(
      id: row['id']?.toString(),
      name: row['name']?.toString() ?? '',
      employeeId: row['employee_id']?.toString(),
      licenseNumber: row['license_number']?.toString() ?? '',
      licenseExpiry: _parseDate(row['license_expiry']),
      phone: row['phone']?.toString(),
      emergencyContact: row['emergency_contact']?.toString(),
      status: row['status']?.toString() ?? 'active',
      assignedVehicle: row['assigned_vehicle']?.toString(),
      address: row['address']?.toString(),
      joiningDate: _parseDate(row['joining_date']),
    );
  }

  // Map CSV row to FuelEntry
  static FuelEntry mapToFuelEntry(Map<String, dynamic> row) {
    return FuelEntry(
      id: row['id']?.toString(),
      vehicleId: row['vehicle_id']?.toString() ?? '',
      driverId: row['driver_id']?.toString(),
      date: _parseDate(row['date']) ?? DateTime.now(),
      liters: _parseDouble(row['liters']) ?? 0.0,
      pricePerLiter: _parseDouble(row['price_per_liter']),
      totalCost: _parseDouble(row['total_cost']) ?? 0.0,
      vendor: row['vendor']?.toString(),
      odometer: _parseDouble(row['odometer']),
      shift: row['shift']?.toString(),
      receiptUrl: row['receipt_url']?.toString(),
      notes: row['notes']?.toString(),
      odometerReading: _parseDouble(row['odometer_reading']),
      fuelType: row['fuel_type']?.toString(),
      station: row['station']?.toString(),
      receiptNumber: row['receipt_number']?.toString(),
    );
  }

  // Helper method to parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }

  // Helper method to parse date values
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Try other common formats
        final formats = [
          'yyyy-MM-dd',
          'dd/MM/yyyy',
          'MM/dd/yyyy',
          'yyyy/MM/dd',
        ];
        for (final format in formats) {
          try {
            return DateFormat(format).parseStrict(value);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  // Validate CSV headers
  static bool validateHeaders(List<String> actual, List<String> expected) {
    final actualLower = actual.map((e) => e.toLowerCase()).toSet();
    final expectedLower = expected.map((e) => e.toLowerCase()).toSet();
    return expectedLower.every(actualLower.contains);
  }

  // Get required headers for entity type
  static List<String> getRequiredHeaders(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'vehicle':
        return ['registration_number', 'make_type'];
      case 'driver':
        return ['name', 'license_number'];
      case 'fuel_entry':
        return ['vehicle_id', 'date', 'liters', 'total_cost'];
      default:
        return [];
    }
  }

  // Generate CSV template for entity type
  static Future<String> generateTemplate(String entityType) async {
    List<String> headers = [];
    List<String> exampleRow = [];

    switch (entityType.toLowerCase()) {
      case 'vehicle':
        headers = [
          'registration_number',
          'make_type',
          'model_year',
          'engine_cc',
          'chassis_number',
          'engine_number',
          'color',
          'status',
          'current_odometer',
          'fuel_type',
          'purchase_date',
        ];
        exampleRow = [
          'GD-092',
          'Toyota Corolla',
          '2022',
          '1800',
          'ABC123456789',
          'ENG123456',
          'White',
          'active',
          '15000',
          'petrol',
          '2022-01-15',
        ];
        break;
      case 'driver':
        headers = [
          'name',
          'employee_id',
          'license_number',
          'license_expiry',
          'phone',
          'emergency_contact',
          'status',
          'address',
          'joining_date',
        ];
        exampleRow = [
          'John Doe',
          'EMP001',
          'LIC123456789',
          '2025-12-31',
          '+923001234567',
          '+923451234567',
          'active',
          '123 Main Street, City',
          '2023-01-01',
        ];
        break;
      case 'fuel_entry':
        headers = [
          'vehicle_id',
          'driver_id',
          'date',
          'liters',
          'price_per_liter',
          'total_cost',
          'vendor',
          'odometer',
          'fuel_type',
          'station',
        ];
        exampleRow = [
          'GD-092',
          'EMP001',
          '2024-01-15',
          '40.5',
          '280.50',
          '11360.25',
          'Shell Station',
          '15200',
          'petrol',
          'Shell Main Branch',
        ];
        break;
      default:
        throw BusinessLogicException('Unknown entity type: $entityType');
    }

    final rows = [headers, exampleRow];
    final csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${entityType}_template.csv';
    final file = File(path);
    await file.writeAsString(csv);

    return path;
  }

  // Clean up CSV data by removing empty rows and trimming values
  static List<Map<String, dynamic>> cleanCsvData(
    List<Map<String, dynamic>> data,
  ) {
    return data
        .where((row) {
          // Remove empty rows (where all values are null or empty)
          final hasData = row.values.any(
            (value) => value != null && value.toString().trim().isNotEmpty,
          );
          return hasData;
        })
        .map((row) {
          // Trim string values
          final cleanedRow = <String, dynamic>{};
          row.forEach((key, value) {
            if (value is String) {
              cleanedRow[key] = value.trim();
            } else {
              cleanedRow[key] = value;
            }
          });
          return cleanedRow;
        })
        .toList();
  }
}
