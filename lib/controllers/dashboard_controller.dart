// lib/controllers/dashboard_controller.dart
import 'package:fleet_management/models/job_order.dart';
import 'package:fleet_management/repositories/driver_repo.dart';
import 'package:fleet_management/repositories/vehicle_repo.dart';
import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/reporting_service.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/trip_log.dart';
import '../models/fuel_entry.dart';
import '../core/logger.dart';

class DashboardController extends ChangeNotifier {
  // Stats
  int _totalVehicles = 0;
  int _activeVehicles = 0;
  int _totalDrivers = 0;
  int _activeJobs = 0;
  double _todayFuelCost = 0.0;
  double _monthFuelCost = 0.0;

  // Lists
  List<TripLog> _recentTrips = [];
  List<Map<String, dynamic>> _fuelData = [];

  // Loading state
  bool _isLoading = false;

  // Getters
  int get totalVehicles => _totalVehicles;
  int get activeVehicles => _activeVehicles;
  int get totalDrivers => _totalDrivers;
  int get activeJobs => _activeJobs;
  double get todayFuelCost => _todayFuelCost;
  double get monthFuelCost => _monthFuelCost;
  List<TripLog> get recentTrips => _recentTrips;
  List<Map<String, dynamic>> get fuelData => _fuelData;
  bool get isLoading => _isLoading;

  // Initialize
  DashboardController() {
    loadDashboardData();
  }

  // Load data
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicles = await HiveService().getAll<Vehicle>('vehicles');
      _totalVehicles = vehicles.length;
      _activeVehicles = vehicles
          .where((v) => v.status == 'active' || v.status == 'assigned')
          .length;

      final drivers = await HiveService().getAll<Driver>('drivers');
      _totalDrivers = drivers.length;

      final jobs = await HiveService().getAll<JobOrder>('jobOrders');
      _activeJobs = jobs
          .where((j) => j.status == 'ongoing' || j.status == 'assigned')
          .length;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Assume FuelEntry.date and FuelEntry.totalCost are non-nullable
      final List<FuelEntry> fuelEntries = await HiveService().getAll<FuelEntry>(
        'fuelEntries',
      );

      // Today's fuel cost
      _todayFuelCost = fuelEntries
          .where((f) => f.date.toIso8601String().split('T')[0] == todayStr)
          .fold<double>(0.0, (double sum, f) => sum + f.totalCost);

      // Month's fuel cost (include entries on/after monthStart)
      final monthStart = DateTime(today.year, today.month, 1);
      _monthFuelCost = fuelEntries
          .where((f) => !f.date.isBefore(monthStart))
          .fold<double>(0.0, (double sum, f) => sum + f.totalCost);

      // Recent trips (last 5)
      final allTrips = await HiveService().getAll<TripLog>('tripLogs');

      // Defensive: handle nullable startTime while sorting
      allTrips.sort((a, b) {
        final aTime = a.startTime;
        final bTime = b.startTime;
        return bTime.compareTo(aTime);
      });
      _recentTrips = allTrips.take(5).toList();

      // Fuel data last 7 days
      _fuelData = [];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayFuel = fuelEntries
            .where((f) => f.date.toIso8601String().split('T')[0] == dateStr)
            .fold<double>(0.0, (double sum, f) => sum + f.totalCost);
        _fuelData.add({'date': dateStr, 'cost': dayFuel});
      }

      Logger.info('Dashboard data loaded');
    } catch (e, stack) {
      Logger.error(
        'Failed to load dashboard data',
        error: e,
        stackTrace: stack,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Generate report
  Future<Map<String, dynamic>> generateReport(DateTime date) async {
    return await ReportingService().generateDailyReport(date);
  }

  // More: Charts data, KPIs calculation
  double get avgFuelPerDay {
    final day = DateTime.now().day;
    return day > 0 ? _monthFuelCost / day : 0.0;
  }

  // Anomalies
  Future<List<FuelEntry>> getAnomalies() async {
    final start = DateTime.now().subtract(Duration(days: 30));
    final end = DateTime.now();
    return await ReportingService().detectAnomalousFuel(start, end);
  }

  // Expiring reminders
  Future<List<Driver>> getExpiringLicenses() async {
    return await DriverRepo().getExpiringLicenses(Duration(days: 30));
  }

  // Vehicle maintenance due
  Future<List<Vehicle>> getMaintenanceDue() async {
    // Assume due every 5000 km
    final vehicles = await VehicleRepo().getAllVehicles();
    return vehicles
        .where((v) => ((v.currentOdometer ?? 0) % 5000) > 4500)
        .toList();
  }

  // Notify on load
  void notifyOnAnomalies() {
    // Implement notifications
  }

  // Extend with more dashboard logic
}
