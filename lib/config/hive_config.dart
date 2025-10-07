// lib/config/hive_config.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:fleet_management/models/allowance.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/job_order.dart';
import '../models/trip_log.dart';
import '../models/fuel_entry.dart';
import '../models/attendance.dart';
import '../models/route_model.dart';
import '../models/user.dart';
import '../models/audit_log.dart';
import '../models/pol_price.dart';
import '../models/maintenance.dart';

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(VehicleAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(VehicleDocumentAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DriverAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(JobOrderAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(TripLogAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(TripAttachmentAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(FuelEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AttendanceAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(RouteModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(RouteStopAdapter());
  }
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AllowanceAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(UserAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AuditLogAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(PolPriceAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(MaintenanceAdapter());
  }
}

// CRITICAL FIX: Open all boxes WITHOUT type parameters
Future<void> initHive() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    registerHiveAdapters();

    final encryptionKey = await _getEncryptionKey();

    // Open all boxes WITHOUT type - this fixes the "already open and of type Box<dynamic>" error
    await Hive.openBox(
      Constants.vehicleBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.vehicleBox);

    await Hive.openBox(
      Constants.driverBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.driverBox);

    await Hive.openBox(
      Constants.jobOrderBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.jobOrderBox);

    await Hive.openBox(
      Constants.tripLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.tripLogBox);

    await Hive.openBox(
      Constants.fuelEntryBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.fuelEntryBox);

    await Hive.openBox(
      Constants.attendanceBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.attendanceBox);

    await Hive.openBox(
      Constants.routeBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.routeBox);

    await Hive.openBox(
      Constants.allowanceBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.allowanceBox);

    await Hive.openBox(
      Constants.userBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.userBox);

    await Hive.openBox(
      Constants.auditLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.auditLogBox);

    await Hive.openBox(
      Constants.polPriceBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.polPriceBox);

    await Hive.openBox(
      Constants.maintenanceBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    Logger.logHiveOpen(Constants.maintenanceBox);

    await _performMigrations();
  } catch (e, stack) {
    Logger.logHiveError('initHive', e.toString());
    Logger.error('Hive initialization failed', error: e, stackTrace: stack);
    rethrow;
  }
}

Future<Uint8List> _getEncryptionKey() async {
  const storage = FlutterSecureStorage();
  const keyName = 'hive_encryption_key';

  String? base64Key = await storage.read(key: keyName);

  if (base64Key == null) {
    final key = Hive.generateSecureKey();
    base64Key = base64UrlEncode(key);
    await storage.write(key: keyName, value: base64Key);
    Logger.info('Generated new Hive encryption key');
  } else {
    Logger.info('Retrieved existing Hive encryption key');
  }

  return base64Url.decode(base64Key);
}

Future<void> _performMigrations() async {
  final vehicleBox = Hive.box(Constants.vehicleBox);
  if (vehicleBox.isNotEmpty) {
    for (var key in vehicleBox.keys) {
      Vehicle? vehicle = vehicleBox.get(key);
      if (vehicle != null && vehicle.currentOdometer == null) {
        vehicle.currentOdometer = 0.0;
        await vehicle.save();
        Logger.debug('Migrated vehicle ${vehicle.id} with default odometer');
      }
    }
  }

  Logger.info('Hive migrations completed');
}

Future<void> closeHive() async {
  await Hive.close();
  Logger.info('Closed all Hive boxes');
}

Future<void> compactHive() async {
  await Hive.box(Constants.vehicleBox).compact();
  await Hive.box(Constants.driverBox).compact();
  Logger.info('Compacted Hive boxes');
}

Future<void> resetHive() async {
  await Hive.deleteFromDisk();
  Logger.warning('Reset all Hive data');
}

// CRITICAL FIX: Box getters WITHOUT type parameters
Box get vehicleBox => Hive.box(Constants.vehicleBox);
Box get driverBox => Hive.box(Constants.driverBox);
Box get jobOrderBox => Hive.box(Constants.jobOrderBox);
Box get tripLogBox => Hive.box(Constants.tripLogBox);
Box get fuelEntryBox => Hive.box(Constants.fuelEntryBox);
Box get attendanceBox => Hive.box(Constants.attendanceBox);
Box get routeBox => Hive.box(Constants.routeBox);
Box get allowanceBox => Hive.box(Constants.allowanceBox);
Box get userBox => Hive.box(Constants.userBox);
Box get auditLogBox => Hive.box(Constants.auditLogBox);
Box get polPriceBox => Hive.box(Constants.polPriceBox);
Box get maintenanceBox => Hive.box(Constants.maintenanceBox);

Future<void> batchWriteVehicles(List<Vehicle> vehicles) async {
  final box = vehicleBox;
  await box.putAll({
    for (var v in vehicles) v.id ?? Random().nextInt(1000000).toString(): v,
  });
  Logger.debug('Batch wrote ${vehicles.length} vehicles');
}
