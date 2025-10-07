// lib/services/import_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../config/import_config.dart';
import '../core/constants.dart';
import '../core/utils/csv_helpers.dart';
import '../core/logger.dart';
import '../core/errors/app_exceptions.dart' hide ImportException;
import 'hive_service.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/trip_log.dart';
import '../models/fuel_entry.dart';
import '../models/attendance.dart';
import '../models/route_model.dart';
import '../models/allowance.dart';
import '../models/pol_price.dart';
import '../models/maintenance.dart';
import '../models/expense.dart';
// Import all models

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  // Import from Excel
  Future<ImportResult> importFromExcel(String path) async {
    try {
      var bytes = File(path).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      final results = ImportResult();

      for (var sheetName in excel.tables.keys) {
        var sheet = excel.tables[sheetName]!;
        var entityName = ImportConfig.sheetToEntity[sheetName];

        if (entityName == null) {
          results.warnings.add('No mapping found for sheet: $sheetName');
          continue;
        }

        try {
          final importResult = await ImportConfig.parseSheetToEntities(
            sheet,
            entityName,
          );

          if (importResult.hasErrors) {
            results.errors.addAll(importResult.errors);
            results.warnings.addAll(importResult.warnings);
          } else {
            await _importEntities(entityName, importResult.entities);
            results.importedCount += importResult.entities.length;
            results.successfulSheets.add(sheetName);
          }
        } catch (e) {
          results.errors.add(
            ImportError(
              row: 0,
              field: 'sheet_processing',
              message: 'Failed to process sheet $sheetName: $e',
              value: sheetName,
            ),
          );
        }
      }

      Logger.info(
        'Imported from Excel: $path - ${results.importedCount} records',
      );
      return results;
    } catch (e) {
      Logger.error('Excel import failed', error: e);
      throw ImportException('Failed to import Excel file: $e');
    }
  }

  // Import from CSV (single entity)
  Future<ImportResult> importFromCsv(String path, String entityName) async {
    try {
      final results = ImportResult();

      List<Map<String, dynamic>> rows = await CsvHelpers.importFromCsv(path);
      rows = CsvHelpers.cleanCsvData(rows);

      // Validate required headers
      final requiredHeaders = ImportConfig.getRequiredHeaders(entityName);
      if (rows.isNotEmpty) {
        final actualHeaders = rows.first.keys.toList();
        if (!ImportConfig.validateHeaders(actualHeaders, requiredHeaders)) {
          throw ValidationException({
            'headers': 'Missing required headers. Expected: $requiredHeaders',
          });
        }
      }

      List<dynamic> entities = [];
      for (int i = 0; i < rows.length; i++) {
        try {
          final entity = _mapRowToEntity(rows[i], entityName);
          if (entity != null) {
            entities.add(entity);
          }
        } catch (e) {
          results.errors.add(
            ImportError(
              row: i + 2, // +2 for header row and 1-based indexing
              field: 'mapping',
              message: 'Failed to map row to entity: $e',
              value: rows[i].toString(),
            ),
          );
        }
      }

      // Validate entities
      final validationErrors = _validateEntities(entities, entityName);
      results.errors.addAll(validationErrors);

      if (results.hasErrors) {
        results.warnings.add(
          'Import completed with ${results.errors.length} errors',
        );
      } else {
        await _importEntities(entityName, entities);
        results.importedCount = entities.length;
      }

      Logger.info(
        'Imported from CSV: $path for $entityName - ${entities.length} records',
      );
      return results;
    } catch (e) {
      Logger.error('CSV import failed', error: e);
      throw ImportException('Failed to import CSV file for $entityName: $e');
    }
  }

  // Generic import to Hive
  Future<void> _importEntities(
    String entityName,
    List<dynamic> entities,
  ) async {
    switch (entityName) {
      case 'Vehicle':
        await HiveService().batchAdd<Vehicle>(
          Constants.vehicleBox,
          entities.cast<Vehicle>(),
        );
        break;
      case 'Driver':
        await HiveService().batchAdd<Driver>(
          Constants.driverBox,
          entities.cast<Driver>(),
        );
        break;
      case 'TripLog':
        await HiveService().batchAdd<TripLog>(
          Constants.tripLogBox,
          entities.cast<TripLog>(),
        );
        break;
      case 'FuelEntry':
        await HiveService().batchAdd<FuelEntry>(
          Constants.fuelEntryBox,
          entities.cast<FuelEntry>(),
        );
        break;
      case 'Attendance':
        await HiveService().batchAdd<Attendance>(
          Constants.attendanceBox,
          entities.cast<Attendance>(),
        );
        break;
      case 'RouteModel':
        await HiveService().batchAdd<RouteModel>(
          Constants.routeBox,
          entities.cast<RouteModel>(),
        );
        break;
      case 'Allowance':
        await HiveService().batchAdd<Allowance>(
          Constants.allowanceBox,
          entities.cast<Allowance>(),
        );
        break;
      case 'PolPrice':
        await HiveService().batchAdd<PolPrice>(
          Constants.polPriceBox,
          entities.cast<PolPrice>(),
        );
        break;
      case 'Maintenance':
        await HiveService().batchAdd<Maintenance>(
          Constants.maintenanceBox,
          entities.cast<Maintenance>(),
        );
        break;
      case 'Expense':
        await HiveService().batchAdd<Expense>(
          'expenses', // Add to constants if needed
          entities.cast<Expense>(),
        );
        break;
      default:
        throw BusinessLogicException('Unsupported entity: $entityName');
    }
  }

  // Map row to entity
  dynamic _mapRowToEntity(Map<String, dynamic> row, String entityName) {
    switch (entityName) {
      case 'Vehicle':
        return CsvHelpers.mapToVehicle(row);
      case 'Driver':
        return CsvHelpers.mapToDriver(row);
      case 'FuelEntry':
        return CsvHelpers.mapToFuelEntry(row);
      // Add cases for other entities as needed
      default:
        throw BusinessLogicException(
          'No mapper available for entity: $entityName',
        );
    }
  }

  // Validate entities
  List<ImportError> _validateEntities(
    List<dynamic> entities,
    String entityName,
  ) {
    final errors = <ImportError>[];

    for (int i = 0; i < entities.length; i++) {
      try {
        final validationError = _validateEntity(entities[i], entityName);
        if (validationError != null) {
          errors.add(
            ImportError(
              row: i + 1,
              field: 'validation',
              message: validationError,
              value: entities[i].toString(),
            ),
          );
        }
      } catch (e) {
        errors.add(
          ImportError(
            row: i + 1,
            field: 'validation',
            message: 'Validation failed: $e',
            value: entities[i].toString(),
          ),
        );
      }
    }

    return errors;
  }

  // Validate single entity
  String? _validateEntity(dynamic entity, String entityName) {
    switch (entityName) {
      case 'Vehicle':
        return ImportConfig.validators['Vehicle']?.call(entity);
      case 'Driver':
        return ImportConfig.validators['Driver']?.call(entity);
      // Add validation for other entities
      default:
        return null;
    }
  }

  // Pick file for import
  Future<String?> pickImportFile({bool excel = true}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: excel ? ['xlsx', 'xls'] : ['csv'],
        allowMultiple: false,
      );
      return result?.files.single.path;
    } catch (e) {
      throw FileException('Failed to pick import file: $e');
    }
  }

  // Get supported entity types
  List<String> getSupportedEntities() {
    return ImportConfig.availableEntities;
  }

  // Get template for entity
  Future<String> getTemplateForEntity(String entityType) async {
    return await CsvHelpers.generateTemplate(entityType);
  }

  // Validate file before import
  Future<ImportValidationResult> validateFile(
    String path,
    String entityType,
  ) async {
    try {
      final results = ImportValidationResult();

      if (path.toLowerCase().endsWith('.csv')) {
        final csvData = await CsvHelpers.importFromCsv(path);
        results.totalRows = csvData.length;

        // Check headers
        if (csvData.isNotEmpty) {
          final headers = csvData.first.keys.toList();
          final requiredHeaders = ImportConfig.getRequiredHeaders(entityType);
          results.hasValidHeaders = ImportConfig.validateHeaders(
            headers,
            requiredHeaders,
          );
          if (!results.hasValidHeaders) {
            results.warnings.add(
              'Missing required headers. Expected: $requiredHeaders',
            );
          }
        }
      } else {
        // Excel validation
        var bytes = File(path).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        results.totalSheets = excel.tables.keys.length;

        for (var sheetName in excel.tables.keys) {
          final entityName = ImportConfig.sheetToEntity[sheetName];
          if (entityName != null) {
            results.validSheets.add(sheetName);
          } else {
            results.invalidSheets.add(sheetName);
          }
        }
      }

      return results;
    } catch (e) {
      throw ImportException('File validation failed: $e');
    }
  }

  // Get import statistics
  Future<Map<String, dynamic>> getImportStats() async {
    final stats = <String, dynamic>{};
    final entities = getSupportedEntities();

    for (final entity in entities) {
      final boxName = _getBoxNameForEntity(entity);
      final count = await HiveService().getBoxSize(boxName);
      stats[entity] = count;
    }

    return stats;
  }

  // Get box name for entity
  String _getBoxNameForEntity(String entity) {
    switch (entity) {
      case 'Vehicle':
        return Constants.vehicleBox;
      case 'Driver':
        return Constants.driverBox;
      case 'TripLog':
        return Constants.tripLogBox;
      case 'FuelEntry':
        return Constants.fuelEntryBox;
      case 'Attendance':
        return Constants.attendanceBox;
      case 'RouteModel':
        return Constants.routeBox;
      case 'Allowance':
        return Constants.allowanceBox;
      case 'PolPrice':
        return Constants.polPriceBox;
      case 'Maintenance':
        return Constants.maintenanceBox;
      default:
        return entity.toLowerCase() + 's';
    }
  }
}

// Import result class
class ImportResult {
  int importedCount = 0;
  final List<ImportError> errors = [];
  final List<String> warnings = [];
  final List<String> successfulSheets = [];

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isSuccessful => errors.isEmpty;

  double get successRate {
    return importedCount > 0
        ? importedCount / (importedCount + errors.length)
        : 0.0;
  }
}

// Import validation result
class ImportValidationResult {
  int totalRows = 0;
  int totalSheets = 0;
  bool hasValidHeaders = false;
  final List<String> validSheets = [];
  final List<String> invalidSheets = [];
  final List<String> warnings = [];
  final List<String> errors = [];

  bool get isValid => errors.isEmpty && hasValidHeaders;
}
