// lib/migrations/migration_001_add_odometer.dart
import 'package:fleet_management/core/logger.dart';
import 'package:fleet_management/models/vehicle.dart';
import 'package:hive/hive.dart';

import '../../core/constants.dart';

Future<void> migration001AddOdometer() async {
  final box = Hive.box<Vehicle>(Constants.vehicleBox);
  for (var key in box.keys) {
    Vehicle? vehicle = box.get(key);
    if (vehicle != null && vehicle.currentOdometer == null) {
      vehicle.currentOdometer = 0.0;
      await box.put(key, vehicle);
      Logger.debug('Added odometer to vehicle $key');
    }
  }
}
