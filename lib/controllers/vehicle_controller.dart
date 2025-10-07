// lib/controllers/vehicle_controller.dart
import 'package:fleet_management/models/fuel_entry.dart';
import 'package:fleet_management/models/maintenance.dart';
import 'package:fleet_management/repositories/trip_repo.dart';
import 'package:fleet_management/services/hive_service.dart';
import 'package:flutter/material.dart';
import '../repositories/vehicle_repo.dart';
import '../models/vehicle.dart';
import '../core/logger.dart';

class VehicleController extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  String _searchTerm = '';
  bool _isLoading = false;
  Vehicle? _selectedVehicle;

  List<Vehicle> get vehicles => _vehicles
      .where(
        (v) =>
            v.registrationNumber.toLowerCase().contains(
              _searchTerm.toLowerCase(),
            ) ||
            v.makeType.toLowerCase().contains(_searchTerm.toLowerCase()),
      )
      .toList();

  bool get isLoading => _isLoading;
  Vehicle? get selectedVehicle => _selectedVehicle;

  VehicleController() {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vehicles = await VehicleRepo().getAllVehicles();
      Logger.info('Loaded ${_vehicles.length} vehicles');
    } catch (e) {
      Logger.error('Failed to load vehicles', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await VehicleRepo().addVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> updateVehicle(String id, Vehicle vehicle) async {
    await VehicleRepo().updateVehicle(id, vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await VehicleRepo().deleteVehicle(id);
    await loadVehicles();
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  // Assign driver
  Future<void> assignDriver(String vehicleId, String driverId) async {
    await VehicleRepo().assignDriver(vehicleId, driverId);
    await loadVehicles();
  }

  // Update odometer
  Future<void> updateOdometer(String id, double odometer) async {
    await VehicleRepo().updateOdometer(id, odometer);
    await loadVehicles();
  }

  // Get vehicle history (trips, fuel, maintenance)
  Future<Map<String, dynamic>> getVehicleHistory(String id) async {
    // Query related data
    final trips = await TripRepo().getTripsByVehicle(id);
    final fuel = await HiveService().query<FuelEntry>(
      'fuelEntries',
      (f) => f.vehicleId == id,
    );
    final maintenance = await HiveService().query<Maintenance>(
      'maintenances',
      (m) => m.vehicleId == id,
    );

    return {'trips': trips, 'fuel': fuel, 'maintenance': maintenance};
  }

  // More: Documents upload, status change
}
