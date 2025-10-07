// lib/repositories/driver_repo.dart
import '../services/hive_service.dart';
import '../models/driver.dart';
import '../core/logger.dart';
import '../core/utils/validators.dart';

class DriverRepo {
  static final DriverRepo _instance = DriverRepo._internal();
  factory DriverRepo() => _instance;
  DriverRepo._internal();

  Future<void> addDriver(Driver driver) async {
    final error =
        Validators.requiredField(driver.name, 'Name') ??
        Validators.requiredField(driver.licenseNumber, 'License Number');
    if (error != null) throw Exception(error);

    if (!Validators.isValidLicenseNumber(driver.licenseNumber)) {
      throw Exception('Invalid license number format');
    }

    await HiveService().add<Driver>('drivers', driver);
  }

  Future<Driver?> getDriver(String id) async {
    return await HiveService().get<Driver>('drivers', id);
  }

  Future<List<Driver>> getAllDrivers() async {
    return await HiveService().getAll<Driver>('drivers');
  }

  Future<void> updateDriver(String id, Driver driver) async {
    await HiveService().update<Driver>('drivers', id, driver);
  }

  Future<void> deleteDriver(String id) async {
    await HiveService().delete<Driver>('drivers', id);
  }

  // Custom queries
  Future<List<Driver>> getActiveDrivers() async {
    return await HiveService().query<Driver>(
      'drivers',
      (d) => d.status == 'active',
    );
  }

  Future<List<Driver>> getDriversByStatus(String status) async {
    return await HiveService().query<Driver>(
      'drivers',
      (d) => d.status == status,
    );
  }

  Future<List<Driver>> searchDrivers(String query) async {
    return await HiveService().query<Driver>(
      'drivers',
      (d) =>
          d.name.toLowerCase().contains(query.toLowerCase()) ||
          d.employeeId?.toLowerCase().contains(query.toLowerCase()) == true ||
          d.licenseNumber.toLowerCase().contains(query.toLowerCase()) ||
          d.phone?.toLowerCase().contains(query.toLowerCase()) == true,
    );
  }

  // Assign vehicle to driver
  Future<void> assignVehicle(String driverId, String vehicleId) async {
    final driver = await getDriver(driverId);
    if (driver != null) {
      driver.assignedVehicle = vehicleId;
      await updateDriver(driverId, driver);
    }
  }

  // Remove vehicle assignment
  Future<void> removeVehicleAssignment(String driverId) async {
    final driver = await getDriver(driverId);
    if (driver != null) {
      driver.assignedVehicle = null;
      await updateDriver(driverId, driver);
    }
  }

  // Get drivers with expiring licenses
  Future<List<Driver>> getExpiringLicenses(Duration within) async {
    final thresholdDate = DateTime.now().add(within);
    return await HiveService().query<Driver>(
      'drivers',
      (d) =>
          d.licenseExpiry != null &&
          d.licenseExpiry!.isBefore(thresholdDate) &&
          d.licenseExpiry!.isAfter(DateTime.now()),
    );
  }

  // Get drivers without assigned vehicles
  Future<List<Driver>> getAvailableDrivers() async {
    return await HiveService().query<Driver>(
      'drivers',
      (d) => d.assignedVehicle == null && d.status == 'active',
    );
  }

  // Update driver status
  Future<void> updateStatus(String id, String status) async {
    final driver = await getDriver(id);
    if (driver != null) {
      driver.status = status;
      await updateDriver(id, driver);
    }
  }

  // Get driver by employee ID
  Future<Driver?> getDriverByEmployeeId(String employeeId) async {
    final drivers = await HiveService().query<Driver>(
      'drivers',
      (d) => d.employeeId == employeeId,
    );
    return drivers.isNotEmpty ? drivers.first : null;
  }

  // Validate driver data
  static String? validateDriver(Driver driver) {
    String? error = Validators.requiredField(driver.name, 'Name');
    if (error != null) return error;

    error = Validators.requiredField(driver.licenseNumber, 'License Number');
    if (error != null) return error;

    if (!Validators.isValidLicenseNumber(driver.licenseNumber)) {
      return 'Invalid license number format';
    }

    if (!Validators.isValidDriverStatus(driver.status)) {
      return 'Invalid driver status';
    }

    if (driver.phone != null && !Validators.isValidPhone(driver.phone!)) {
      return 'Invalid phone number';
    }

    return null;
  }
}
