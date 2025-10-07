// lib/repositories/vehicle_repo.dart
import '../services/hive_service.dart';
import '../models/vehicle.dart';
import '../core/logger.dart';
import '../core/utils/validators.dart';

class VehicleRepo {
  static final VehicleRepo _instance = VehicleRepo._internal();
  factory VehicleRepo() => _instance;
  VehicleRepo._internal();

  Future<void> addVehicle(Vehicle vehicle) async {
    final error = Validators.validateVehicle(vehicle);
    if (error != null) throw Exception(error);
    await HiveService().add<Vehicle>('vehicles', vehicle);
  }

  Future<Vehicle?> getVehicle(String id) async {
    return await HiveService().get<Vehicle>('vehicles', id);
  }

  Future<List<Vehicle>> getAllVehicles() async {
    return await HiveService().getAll<Vehicle>('vehicles');
  }

  // Add this missing method
  Future<void> loadVehicles() async {
    // This method can be used to refresh vehicles if needed
    // For now, it just returns a completed future since getAllVehicles already exists
    return;
  }

  Future<void> updateVehicle(String id, Vehicle vehicle) async {
    await HiveService().update<Vehicle>('vehicles', id, vehicle);
  }

  Future<void> deleteVehicle(String id) async {
    await HiveService().delete<Vehicle>('vehicles', id);
  }

  // Custom queries
  Future<List<Vehicle>> getActiveVehicles() async {
    return await HiveService().query<Vehicle>(
      'vehicles',
      (v) => v.status == 'active',
    );
  }

  Future<List<Vehicle>> searchVehicles(String query) async {
    return await HiveService().query<Vehicle>(
      'vehicles',
      (v) =>
          v.registrationNumber.toLowerCase().contains(query.toLowerCase()) ||
          v.makeType.toLowerCase().contains(query.toLowerCase()),
    );
  }

  // Assign driver
  Future<void> assignDriver(String vehicleId, String driverId) async {
    final vehicle = await getVehicle(vehicleId);
    if (vehicle != null) {
      vehicle.assignedDriver = driverId;
      vehicle.status = 'assigned';
      await updateVehicle(vehicleId, vehicle);
    }
  }

  // Update odometer
  Future<void> updateOdometer(String id, double newOdometer) async {
    final vehicle = await getVehicle(id);
    if (vehicle != null && newOdometer > (vehicle.currentOdometer ?? 0)) {
      vehicle.currentOdometer = newOdometer;
      await updateVehicle(id, vehicle);
    } else {
      throw Exception('Invalid odometer update');
    }
  }

  // More business logic: Check maintenance due, etc.
}

bool isValidVehicleStatus(String status) {
  const validStatuses = ['active', 'maintenance', 'inactive', 'assigned'];
  return validStatuses.contains(status.toLowerCase());
}

bool isValidOdometer(double? odometer) {
  if (odometer == null) return true; // Optional field
  return odometer >= 0;
}

bool isValidRegistrationNumber(String reg) {
  final regex = RegExp(r'^[A-Z0-9-]{1,10}$'); // Simple pattern
  return regex.hasMatch(reg);
}

bool isValidMakeType(String make) {
  return make.isNotEmpty && make.length <= 50;
}

String? validateVehicle(Vehicle vehicle) {
  if (!isValidRegistrationNumber(vehicle.registrationNumber)) {
    return 'Invalid registration number';
  }
  if (!isValidMakeType(vehicle.makeType)) {
    return 'Invalid make/type';
  }
  if (!isValidOdometer(vehicle.currentOdometer)) {
    return 'Invalid current odometer';
  }
  if (!isValidVehicleStatus(vehicle.status)) {
    return 'Invalid vehicle status';
  }
  // Add more field validations as needed
  return null; // No errors
}
