// lib/config/import_config.dart
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../core/utils/validators.dart';
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
import '../core/logger.dart';
import 'app_config.dart';

class ImportConfig {
  // Sheet to entity mapping
  static Map<String, String> get sheetToEntity => AppConfig.sheetToEntityMap;

  // Field mappings per entity with detailed configuration
  static final Map<String, Map<String, dynamic>> fieldMappings = {
    'Vehicle': {
      'registration_number': {
        'excel_header': 'Reg #',
        'type': 'string',
        'required': true,
      },
      'make_type': {
        'excel_header': 'Make & Type',
        'type': 'string',
        'required': true,
      },
      'model_year': {
        'excel_header': 'Model Year',
        'type': 'number',
        'required': false,
      },
      'engine_cc': {
        'excel_header': 'Engine CC',
        'type': 'number',
        'required': false,
      },
      'chassis_number': {
        'excel_header': 'Chassis #',
        'type': 'string',
        'required': false,
      },
      'engine_number': {
        'excel_header': 'Engine #',
        'type': 'string',
        'required': false,
      },
      'color': {'excel_header': 'Color', 'type': 'string', 'required': false},
      'current_odometer': {
        'excel_header': 'Current Odometer',
        'type': 'number',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'active',
      },
      'fuel_type': {
        'excel_header': 'Fuel Type',
        'type': 'string',
        'required': false,
      },
      'purchase_date': {
        'excel_header': 'Purchase Date',
        'type': 'date',
        'required': false,
      },
    },
    'Driver': {
      'name': {
        'excel_header': 'Name of Employee',
        'type': 'string',
        'required': true,
      },
      'employee_id': {
        'excel_header': 'Employee ID',
        'type': 'string',
        'required': true,
      },
      'license_number': {
        'excel_header': 'License #',
        'type': 'string',
        'required': true,
      },
      'license_expiry': {
        'excel_header': 'License Expiry',
        'type': 'date',
        'required': false,
      },
      'phone': {'excel_header': 'Phone', 'type': 'string', 'required': false},
      'address': {
        'excel_header': 'Address',
        'type': 'string',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'active',
      },
      'joining_date': {
        'excel_header': 'Joining Date',
        'type': 'date',
        'required': false,
      },
    },
    'TripLog': {
      'vehicle_id': {
        'excel_header': 'Vehicle Reg No',
        'type': 'string',
        'required': true,
      },
      'driver_id': {
        'excel_header': 'Driver Name',
        'type': 'string',
        'required': true,
      },
      'start_km': {
        'excel_header': 'Meter Out',
        'type': 'number',
        'required': true,
      },
      'end_km': {
        'excel_header': 'Meter IN',
        'type': 'number',
        'required': false,
      },
      'start_time': {
        'excel_header': 'Time Out',
        'type': 'datetime',
        'required': true,
      },
      'end_time': {
        'excel_header': 'Time In',
        'type': 'datetime',
        'required': false,
      },
      'purpose': {
        'excel_header': 'Duty Detail',
        'type': 'string',
        'required': false,
      },
      'route': {'excel_header': 'Route', 'type': 'string', 'required': false},
      'distance': {
        'excel_header': 'Distance',
        'type': 'number',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'completed',
      },
      'fuel_used': {
        'excel_header': 'Fuel Used',
        'type': 'number',
        'required': false,
      },
    },
    'FuelEntry': {
      'vehicle_id': {
        'excel_header': 'Vehicle No.',
        'type': 'string',
        'required': true,
      },
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'liters': {'excel_header': 'Ltrs', 'type': 'number', 'required': true},
      'total_cost': {
        'excel_header': 'Amount',
        'type': 'number',
        'required': true,
      },
      'price_per_liter': {
        'excel_header': 'Price/Ltr',
        'type': 'number',
        'required': false,
      },
      'odometer_reading': {
        'excel_header': 'Odometer',
        'type': 'number',
        'required': false,
      },
      'fuel_type': {
        'excel_header': 'Fuel Type',
        'type': 'string',
        'required': false,
      },
      'station': {
        'excel_header': 'Station',
        'type': 'string',
        'required': false,
      },
      'receipt_number': {
        'excel_header': 'Receipt #',
        'type': 'string',
        'required': false,
      },
    },
    'Attendance': {
      'driver_id': {
        'excel_header': 'Employee ID',
        'type': 'string',
        'required': true,
      },
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'status': {'excel_header': 'Status', 'type': 'string', 'required': true},
      'check_in': {
        'excel_header': 'Check In',
        'type': 'datetime',
        'required': false,
      },
      'check_out': {
        'excel_header': 'Check Out',
        'type': 'datetime',
        'required': false,
      },
      'shift': {'excel_header': 'Shift', 'type': 'string', 'required': false},
      'hours_worked': {
        'excel_header': 'Hours Worked',
        'type': 'number',
        'required': false,
      },
      'remarks': {
        'excel_header': 'Remarks',
        'type': 'string',
        'required': false,
      },
    },
    'RouteModel': {
      'name': {
        'excel_header': 'Route Name',
        'type': 'string',
        'required': true,
      },
      'description': {
        'excel_header': 'Description',
        'type': 'string',
        'required': false,
      },
      'start_point': {
        'excel_header': 'Start Point',
        'type': 'string',
        'required': false,
      },
      'end_point': {
        'excel_header': 'End Point',
        'type': 'string',
        'required': false,
      },
      'distance': {
        'excel_header': 'Distance (km)',
        'type': 'number',
        'required': false,
      },
      'estimated_time': {
        'excel_header': 'Est. Time',
        'type': 'string',
        'required': false,
      },
      'stops': {'excel_header': 'Stops', 'type': 'list', 'required': false},
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'active',
      },
    },
    'Allowance': {
      'driver_id': {
        'excel_header': 'Employee ID',
        'type': 'string',
        'required': true,
      },
      'type': {'excel_header': 'Type', 'type': 'string', 'required': true},
      'amount': {'excel_header': 'Amount', 'type': 'number', 'required': true},
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'description': {
        'excel_header': 'Description',
        'type': 'string',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'pending',
      },
      'approved_by': {
        'excel_header': 'Approved By',
        'type': 'string',
        'required': false,
      },
      'remarks': {
        'excel_header': 'Remarks',
        'type': 'string',
        'required': false,
      },
    },
    'PolPrice': {
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'petrol_price': {
        'excel_header': 'Petrol Price',
        'type': 'number',
        'required': true,
      },
      'diesel_price': {
        'excel_header': 'Diesel Price',
        'type': 'number',
        'required': true,
      },
      'pvt_use_rate_petrol': {
        'excel_header': 'Private Use Petrol',
        'type': 'number',
        'required': false,
      },
      'pvt_use_rate_diesel': {
        'excel_header': 'Private Use Diesel',
        'type': 'number',
        'required': false,
      },
    },
    'Maintenance': {
      'vehicle_id': {
        'excel_header': 'Vehicle Reg No',
        'type': 'string',
        'required': true,
      },
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'description': {
        'excel_header': 'Description',
        'type': 'string',
        'required': true,
      },
      'cost': {'excel_header': 'Cost', 'type': 'number', 'required': false},
      'vendor': {'excel_header': 'Vendor', 'type': 'string', 'required': false},
      'odometer_at_maintenance': {
        'excel_header': 'Odometer',
        'type': 'number',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'completed',
      },
      'parts_replaced': {
        'excel_header': 'Parts Replaced',
        'type': 'list',
        'required': false,
      },
      'notes': {'excel_header': 'Notes', 'type': 'string', 'required': false},
      'next_maintenance_date': {
        'excel_header': 'Next Maintenance',
        'type': 'date',
        'required': false,
      },
      'maintenance_type': {
        'excel_header': 'Type',
        'type': 'string',
        'required': false,
      },
    },
    'Expense': {
      'vehicle_id': {
        'excel_header': 'Vehicle Reg No',
        'type': 'string',
        'required': false,
      },
      'date': {'excel_header': 'Date', 'type': 'date', 'required': true},
      'description': {
        'excel_header': 'Description',
        'type': 'string',
        'required': true,
      },
      'amount': {'excel_header': 'Amount', 'type': 'number', 'required': true},
      'category': {
        'excel_header': 'Category',
        'type': 'string',
        'required': false,
      },
      'payment_method': {
        'excel_header': 'Payment Method',
        'type': 'string',
        'required': false,
      },
      'receipt_number': {
        'excel_header': 'Receipt #',
        'type': 'string',
        'required': false,
      },
      'approved_by': {
        'excel_header': 'Approved By',
        'type': 'string',
        'required': false,
      },
      'status': {
        'excel_header': 'Status',
        'type': 'string',
        'required': false,
        'default': 'pending',
      },
      'vendor': {'excel_header': 'Vendor', 'type': 'string', 'required': false},
      'notes': {'excel_header': 'Notes', 'type': 'string', 'required': false},
    },
  };

  // Validation functions per entity
  static final Map<String, Function(dynamic)> validators = {
    'Vehicle': (dynamic v) => Validators.validateVehicle(v as Vehicle),
    'Driver': (dynamic d) {
      final driver = d as Driver;
      return Validators.requiredField(driver.name, 'Name') ??
          Validators.requiredField(driver.licenseNumber, 'License Number') ??
          (Validators.isValidLicenseNumber(driver.licenseNumber)
              ? null
              : 'Invalid license number');
    },
    'TripLog': (dynamic t) {
      final trip = t as TripLog;
      return Validators.requiredField(trip.vehicleId, 'Vehicle') ??
          Validators.requiredField(trip.driverId, 'Driver') ??
          (Validators.isValidOdometer(trip.startKm)
              ? null
              : 'Invalid start KM');
    },
    'FuelEntry': (dynamic f) {
      final fuel = f as FuelEntry;
      return Validators.requiredField(fuel.vehicleId, 'Vehicle') ??
          (Validators.isValidFuelLiters(fuel.liters)
              ? null
              : 'Invalid fuel liters') ??
          (Validators.isValidPrice(fuel.totalCost) ? null : 'Invalid cost');
    },
    'PolPrice': (dynamic p) {
      final pol = p as PolPrice;
      return (Validators.isValidPrice(pol.petrolPrice)
              ? null
              : 'Invalid petrol price') ??
          (Validators.isValidPrice(pol.dieselPrice)
              ? null
              : 'Invalid diesel price');
    },
  };

  // Default values per entity
  static final Map<String, Map<String, dynamic>> defaultValues = {
    'Vehicle': {'status': 'active', 'fuel_type': 'petrol'},
    'Driver': {'status': 'active'},
    'TripLog': {'status': 'completed'},
    'Attendance': {'status': 'present'},
    'RouteModel': {'status': 'active'},
    'Allowance': {'status': 'pending'},
    'Maintenance': {'status': 'completed'},
    'Expense': {'status': 'pending'},
  };

  // Date formats to try during parsing
  static final List<String> dateFormats = [
    'yyyy-MM-dd',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'dd-MM-yyyy',
    'yyyy/MM/dd',
    'dd MMM yyyy',
    'dd MMMM yyyy',
  ];

  // DateTime formats to try during parsing
  static final List<String> datetimeFormats = [
    'yyyy-MM-dd HH:mm:ss',
    'dd/MM/yyyy HH:mm:ss',
    'MM/dd/yyyy HH:mm:ss',
    'yyyy-MM-dd HH:mm',
    'dd/MM/yyyy HH:mm',
    'hh:mm a dd/MM/yyyy',
    'HH:mm dd/MM/yyyy',
  ];

  // Load mapping from JSON if needed
  static Future<void> loadImportConfig() async {
    try {
      final file = File('assets/config/import_mappings.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        // Update fieldMappings with custom mappings
        if (json['field_mappings'] != null) {
          (json['field_mappings'] as Map).forEach((key, value) {
            fieldMappings[key] = Map<String, dynamic>.from(value);
          });
        }
        Logger.info('Loaded import config from JSON');
      }
    } catch (e) {
      Logger.warning('Could not load import config from JSON, using defaults');
    }
  }

  // Parse Excel sheet to entity list with comprehensive error handling
  static Future<ImportResult<T>> parseSheetToEntities<T>(
    Sheet sheet,
    String entityName,
  ) async {
    final List<T> entities = [];
    final List<ImportError> errors = [];
    final List<String> warnings = [];

    final mapping = fieldMappings[entityName];
    if (mapping == null) {
      throw ImportException('No field mapping found for entity: $entityName');
    }

    // Extract headers from first row
    final List<String> headers = _extractHeaders(sheet.row(0));

    // Validate required headers
    final missingHeaders = _validateRequiredHeaders(headers, mapping);
    if (missingHeaders.isNotEmpty) {
      warnings.add('Missing recommended headers: ${missingHeaders.join(', ')}');
    }

    // Process each data row
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (_isEmptyRow(row)) continue;

      try {
        final Map<String, dynamic> rowData = _parseRowData(
          row,
          headers,
          mapping,
          entityName,
        );
        final T? entity = _mapRowToEntity<T>(rowData, entityName, i + 1);

        if (entity != null) {
          // Validate entity
          final validationError = _validateEntity(entity, entityName);
          if (validationError != null) {
            errors.add(
              ImportError(
                row: i + 1,
                field: 'validation',
                message: validationError,
                value: rowData.toString(),
              ),
            );
          } else {
            entities.add(entity);
          }
        }
      } catch (e) {
        errors.add(
          ImportError(
            row: i + 1,
            field: 'parsing',
            message: e.toString(),
            value: 'Row parsing failed',
          ),
        );
      }
    }

    return ImportResult(
      entities: entities,
      errors: errors,
      warnings: warnings,
      totalRows: sheet.maxRows - 1,
    );
  }

  static List<String> _extractHeaders(List<Data?> headerRow) {
    return headerRow.map((cell) {
      if (cell == null) return '';
      return cell.value.toString().trim().toLowerCase();
    }).toList();
  }

  static List<String> _validateRequiredHeaders(
    List<String> headers,
    Map<String, dynamic> mapping,
  ) {
    final List<String> missing = [];

    mapping.forEach((field, config) {
      final fieldConfig = config as Map<String, dynamic>;
      if (fieldConfig['required'] == true) {
        final excelHeader = (fieldConfig['excel_header'] as String)
            .toLowerCase();
        if (!headers.contains(excelHeader)) {
          missing.add(fieldConfig['excel_header']);
        }
      }
    });

    return missing;
  }

  static bool _isEmptyRow(List<Data?> row) {
    return row.every(
      (cell) =>
          cell == null ||
          cell.value == null ||
          cell.value.toString().trim().isEmpty,
    );
  }

  static Map<String, dynamic> _parseRowData(
    List<Data?> row,
    List<String> headers,
    Map<String, dynamic> mapping,
    String entityName,
  ) {
    final Map<String, dynamic> rowData = {};

    // Add default values first
    final defaults = defaultValues[entityName] ?? {};
    defaults.forEach((key, value) {
      rowData[key] = value;
    });

    for (int j = 0; j < headers.length; j++) {
      final header = headers[j];
      final fieldConfig = _getFieldConfigForHeader(header, mapping);

      if (fieldConfig != null) {
        final cell = j < row.length ? row[j] : null;
        final value = _cleanValue(
          cell?.value,
          fieldConfig['type'] as String,
          fieldConfig['excel_header'] as String,
        );

        if (value != null) {
          rowData[fieldConfig['field']] = value;
        } else if (fieldConfig['required'] == true) {
          throw ImportException(
            'Required field ${fieldConfig['excel_header']} is empty or invalid',
          );
        }
      }
    }

    // Calculate derived fields
    _calculateDerivedFields(rowData, entityName);

    return rowData;
  }

  static Map<String, dynamic>? _getFieldConfigForHeader(
    String header,
    Map<String, dynamic> mapping,
  ) {
    for (final entry in mapping.entries) {
      final fieldConfig = entry.value as Map<String, dynamic>;
      final excelHeader = (fieldConfig['excel_header'] as String).toLowerCase();
      if (excelHeader == header) {
        return {'field': entry.key, ...fieldConfig};
      }
    }
    return null;
  }

  static dynamic _cleanValue(
    dynamic value,
    String fieldType,
    String fieldName,
  ) {
    if (value == null) return null;

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return null;

    try {
      switch (fieldType) {
        case 'number':
          return _parseNumber(stringValue);
        case 'date':
          return _parseDate(stringValue);
        case 'datetime':
          return _parseDateTime(stringValue);
        case 'boolean':
          return _parseBoolean(stringValue);
        case 'list':
          return _parseList(stringValue);
        case 'string':
        default:
          return stringValue;
      }
    } catch (e) {
      Logger.warning('Failed to parse $fieldName: $stringValue as $fieldType');
      return null;
    }
  }

  static double? _parseNumber(String value) {
    // Remove currency symbols, commas, etc.
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned);
  }

  static DateTime? _parseDate(String value) {
    for (final format in dateFormats) {
      try {
        return DateFormat(format).parseStrict(value);
      } catch (e) {
        continue;
      }
    }

    // Try DateTime parsing as fallback
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseDateTime(String value) {
    for (final format in datetimeFormats) {
      try {
        return DateFormat(format).parseStrict(value);
      } catch (e) {
        continue;
      }
    }

    // Try standard DateTime parsing
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  static bool _parseBoolean(String value) {
    final lowerValue = value.toLowerCase();
    return lowerValue == 'yes' ||
        lowerValue == 'true' ||
        lowerValue == '1' ||
        lowerValue == 'y';
  }

  static List<String> _parseList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // ImportConfig class mein add karein
  static List<String> getRequiredHeaders(String entityName) {
    final mapping = fieldMappings[entityName];
    if (mapping == null) return [];

    return mapping.entries
        .where((entry) => (entry.value as Map)['required'] == true)
        .map((entry) => (entry.value as Map)['excel_header'] as String)
        .toList();
  }

  // ImportConfig class mein add karein
  static bool validateHeaders(List<String> actual, List<String> expected) {
    final actualLower = actual.map((e) => e.toLowerCase()).toSet();
    final expectedLower = expected.map((e) => e.toLowerCase()).toSet();
    return expectedLower.every(actualLower.contains);
  }

  static void _calculateDerivedFields(
    Map<String, dynamic> rowData,
    String entityName,
  ) {
    switch (entityName) {
      case 'FuelEntry':
        final liters = rowData['liters'] as double?;
        final totalCost = rowData['total_cost'] as double?;
        if (liters != null && totalCost != null && liters > 0) {
          rowData['price_per_liter'] = totalCost / liters;
        }
        break;
      case 'PolPrice':
        final petrolPrice = rowData['petrol_price'] as double?;
        final dieselPrice = rowData['diesel_price'] as double?;
        if (petrolPrice != null) {
          rowData['pvt_use_rate_petrol'] = petrolPrice * 0.5;
        }
        if (dieselPrice != null) {
          rowData['pvt_use_rate_diesel'] = dieselPrice * 0.5;
        }
        break;
      case 'TripLog':
        final startKm = rowData['start_km'] as double?;
        final endKm = rowData['end_km'] as double?;
        if (startKm != null && endKm != null && endKm > startKm) {
          rowData['distance'] = endKm - startKm;
        }
        break;
    }
  }

  static T? _mapRowToEntity<T>(
    Map<String, dynamic> row,
    String entityName,
    int rowNumber,
  ) {
    try {
      switch (entityName) {
        case 'Vehicle':
          return Vehicle(
                id: '${row['registration_number']}_${DateTime.now().millisecondsSinceEpoch}',
                registrationNumber: row['registration_number'] ?? '',
                makeType: row['make_type'] ?? '',
                modelYear: row['model_year']?.toString(),
                engineCC: row['engine_cc'] as double?,
                chassisNumber: row['chassis_number']?.toString(),
                engineNumber: row['engine_number']?.toString(),
                color: row['color']?.toString(),
                currentOdometer: row['current_odometer'] as double?,
                status: row['status'] ?? 'active',
                fuelType: row['fuel_type']?.toString(),
                purchaseDate: row['purchase_date'] as DateTime?,
              )
              as T;

        case 'Driver':
          return Driver(
                id: '${row['employee_id']}_${DateTime.now().millisecondsSinceEpoch}',
                name: row['name'] ?? '',
                employeeId: row['employee_id']?.toString() ?? '',
                licenseNumber: row['license_number'] ?? '',
                licenseExpiry: row['license_expiry'] as DateTime?,
                phone: row['phone']?.toString(),
                address: row['address']?.toString(),
                status: row['status'] ?? 'active',
                joiningDate: row['joining_date'] as DateTime?,
              )
              as T;

        case 'TripLog':
          return TripLog(
                id: 'trip_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                vehicleId: row['vehicle_id'] ?? '',
                driverId: row['driver_id'] ?? '',
                startKm: row['start_km'] as double? ?? 0.0,
                endKm: row['end_km'] as double?,
                startTime: row['start_time'] as DateTime? ?? DateTime.now(),
                endTime: row['end_time'] as DateTime?,
                purpose: row['purpose']?.toString(),
                route: row['route']?.toString(),
                distance: row['distance'] as double?,
                status: row['status'] ?? 'completed',
                fuelUsed: row['fuel_used'] as double?,
              )
              as T;

        case 'FuelEntry':
          return FuelEntry(
                id: 'fuel_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                vehicleId: row['vehicle_id'] ?? '',
                date: row['date'] as DateTime? ?? DateTime.now(),
                liters: row['liters'] as double? ?? 0.0,
                totalCost: row['total_cost'] as double? ?? 0.0,
                pricePerLiter: row['price_per_liter'] as double?,
                odometerReading: row['odometer_reading'] as double?,
                fuelType: row['fuel_type']?.toString(),
                station: row['station']?.toString(),
                receiptNumber: row['receipt_number']?.toString(),
              )
              as T;

        case 'Attendance':
          return Attendance(
                id: 'attendance_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                driverId: row['driver_id'] ?? '',
                date: row['date'] as DateTime? ?? DateTime.now(),
                status: row['status'] ?? 'present',
                checkIn: row['check_in'] as DateTime?,
                checkOut: row['check_out'] as DateTime?,
                shift: row['shift']?.toString(),
                hoursWorked: row['hours_worked'] as double?,
                remarks: row['remarks']?.toString(),
              )
              as T;

        case 'RouteModel':
          List<RouteStop>? routeStops;
          if (row['stops'] is List<String>) {
            final stopsList = row['stops'] as List<String>;
            routeStops = stopsList.asMap().entries.map((entry) {
              return RouteStop(name: entry.value, sequence: entry.key + 1);
            }).toList();
          }

          return RouteModel(
                id: 'route_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                name: row['name'] ?? '',
                description: row['description']?.toString(),
                startPoint: row['start_point']?.toString(),
                endPoint: row['end_point']?.toString(),
                distance: row['distance'] as double?,
                estimatedTime: row['estimated_time']?.toString(),
                stops: routeStops,
                status: row['status'] ?? 'active',
              )
              as T;

        case 'Allowance':
          return Allowance(
                id: 'allowance_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                driverId: row['driver_id'] ?? '',
                type: row['type'] ?? '',
                amount: row['amount'] as double? ?? 0.0,
                date: row['date'] as DateTime? ?? DateTime.now(),
                description: row['description']?.toString(),
                status: row['status'] ?? 'pending',
                approvedBy: row['approved_by']?.toString(),
                remarks: row['remarks']?.toString(),
              )
              as T;

        case 'PolPrice':
          return PolPrice(
                id: 'pol_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                date: row['date'] as DateTime? ?? DateTime.now(),
                petrolPrice: row['petrol_price'] as double? ?? 0.0,
                dieselPrice: row['diesel_price'] as double? ?? 0.0,
                pvtUseRatePetrol: row['pvt_use_rate_petrol'] as double?,
                pvtUseRateDiesel: row['pvt_use_rate_diesel'] as double?,
              )
              as T;

        case 'Maintenance':
          return Maintenance(
                id: 'maintenance_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                vehicleId: row['vehicle_id'] ?? '',
                date: row['date'] as DateTime? ?? DateTime.now(),
                description: row['description'] ?? '',
                cost: row['cost'] as double?,
                vendor: row['vendor']?.toString(),
                odometerAtMaintenance:
                    row['odometer_at_maintenance'] as double?,
                status: row['status'] ?? 'completed',
                partsReplaced: row['parts_replaced'] as List<String>?,
                notes: row['notes']?.toString(),
              )
              as T;

        case 'Expense':
          return Expense(
                id: 'expense_${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
                vehicleId: row['vehicle_id']?.toString(),
                date: row['date'] as DateTime? ?? DateTime.now(),
                description: row['description'] ?? '',
                amount: row['amount'] as double? ?? 0.0,
                category: row['category']?.toString(),
                paymentMethod: row['payment_method']?.toString(),
                receiptNumber: row['receipt_number']?.toString(),
                approvedBy: row['approved_by']?.toString(),
                status: row['status'] ?? 'pending',
                vendor: row['vendor']?.toString(),
                notes: row['notes']?.toString(),
              )
              as T;

        default:
          Logger.warning('Unknown entity type: $entityName');
          return null;
      }
    } catch (e) {
      Logger.error('Failed to map row to entity $entityName', error: e);
      return null;
    }
  }

  static String? _validateEntity(dynamic entity, String entityName) {
    final validator = validators[entityName];
    if (validator != null) {
      return validator(entity);
    }
    return null;
  }

  // Get available entity types for import
  static List<String> get availableEntities => fieldMappings.keys.toList();

  // Get required fields for an entity
  static List<String> getRequiredFields(String entityName) {
    final mapping = fieldMappings[entityName];
    if (mapping == null) return [];

    return mapping.entries
        .where((entry) => (entry.value as Map)['required'] == true)
        .map((entry) => (entry.value as Map)['excel_header'] as String)
        .toList();
  }

  // Get field description for UI
  static Map<String, dynamic> getFieldDescription(
    String entityName,
    String fieldName,
  ) {
    final mapping = fieldMappings[entityName];
    if (mapping == null || !mapping.containsKey(fieldName)) {
      return {};
    }
    return mapping[fieldName] as Map<String, dynamic>;
  }
}

// Supporting classes for import results
class ImportResult<T> {
  final List<T> entities;
  final List<ImportError> errors;
  final List<String> warnings;
  final int totalRows;

  ImportResult({
    required this.entities,
    required this.errors,
    required this.warnings,
    required this.totalRows,
  });

  int get successCount => entities.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  double get successRate => totalRows > 0 ? successCount / totalRows : 0.0;
}

class ImportError {
  final int row;
  final String field;
  final String message;
  final String value;

  ImportError({
    required this.row,
    required this.field,
    required this.message,
    required this.value,
  });

  @override
  String toString() {
    return 'Row $row, Field $field: $message (Value: $value)';
  }
}

class ImportException implements Exception {
  final String message;

  ImportException(this.message);

  @override
  String toString() => 'ImportException: $message';
}
