// lib/services/reporting_service.dart
import '../config/app_config.dart';
import '../models/attendance.dart';
import '../models/fuel_entry.dart';
import '../models/trip_log.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/maintenance.dart';
import '../models/expense.dart';
import '../core/utils/csv_helpers.dart';
import '../core/errors/app_exceptions.dart';
import '../core/constants.dart';
import 'hive_service.dart';

class ReportingService {
  static final ReportingService _instance = ReportingService._internal();
  factory ReportingService() => _instance;
  ReportingService._internal();

  // Generate daily summary
  Future<Map<String, dynamic>> generateDailyReport(DateTime date) async {
    try {
      final trips = await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) =>
            t.startTime.day == date.day &&
            t.startTime.month == date.month &&
            t.startTime.year == date.year,
      );

      final fuel = await HiveService().query<FuelEntry>(
        Constants.fuelEntryBox,
        (f) =>
            f.date.day == date.day &&
            f.date.month == date.month &&
            f.date.year == date.year,
      );

      final attendance = await HiveService().query<Attendance>(
        Constants.attendanceBox,
        (a) =>
            a.date.day == date.day &&
            a.date.month == date.month &&
            a.date.year == date.year,
      );

      double totalFuelCost = fuel.fold(0.0, (sum, f) => sum + f.totalCost);
      int totalTrips = trips.length;
      int presentDrivers = attendance
          .where((a) => a.status == 'present')
          .length;
      double totalDistance = trips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );

      return {
        'date': date,
        'totalTrips': totalTrips,
        'totalFuelCost': totalFuelCost,
        'totalDistance': totalDistance,
        'presentDrivers': presentDrivers,
        'fuelEntries': fuel.length,
        'avgFuelEfficiency': totalDistance > 0
            ? fuel.fold(0.0, (sum, f) => sum + f.liters) / totalDistance
            : 0,
      };
    } catch (e) {
      throw BusinessLogicException('Failed to generate daily report: $e');
    }
  }

  // Generate monthly report
  Future<Map<String, dynamic>> generateMonthlyReport(
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final trips = await generateTripReport(startDate, endDate);
      final fuel = await generateFuelReport(startDate, endDate);
      final expenses = await HiveService().query<Expense>(
        'expenses',
        (e) => e.date.isAfter(startDate) && e.date.isBefore(endDate),
      );

      double totalFuelCost = fuel.fold(0.0, (sum, f) => sum + f.totalCost);
      double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
      double totalDistance = trips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );

      return {
        'period': '$year-${month.toString().padLeft(2, '0')}',
        'totalTrips': trips.length,
        'totalFuelCost': totalFuelCost,
        'totalExpenses': totalExpenses,
        'totalDistance': totalDistance,
        'fuelEfficiency': totalDistance > 0
            ? fuel.fold(0.0, (sum, f) => sum + f.liters) / totalDistance
            : 0,
        'costPerKm': totalDistance > 0
            ? (totalFuelCost + totalExpenses) / totalDistance
            : 0,
      };
    } catch (e) {
      throw BusinessLogicException('Failed to generate monthly report: $e');
    }
  }

  // Fuel report
  Future<List<FuelEntry>> generateFuelReport(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await HiveService().query<FuelEntry>(
        Constants.fuelEntryBox,
        (f) =>
            f.date.isAfter(start.subtract(const Duration(days: 1))) &&
            f.date.isBefore(end.add(const Duration(days: 1))),
      );
    } catch (e) {
      throw DatabaseException('Failed to generate fuel report: $e');
    }
  }

  // Trip report
  Future<List<TripLog>> generateTripReport(DateTime start, DateTime end) async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) =>
            t.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
            t.startTime.isBefore(end.add(const Duration(days: 1))),
      );
    } catch (e) {
      throw DatabaseException('Failed to generate trip report: $e');
    }
  }

  // Vehicle performance report
  Future<Map<String, dynamic>> generateVehiclePerformanceReport(
    String vehicleId,
  ) async {
    try {
      final trips = await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.vehicleId == vehicleId,
      );

      final fuel = await HiveService().query<FuelEntry>(
        Constants.fuelEntryBox,
        (f) => f.vehicleId == vehicleId,
      );

      final maintenance = await HiveService().query<Maintenance>(
        Constants.maintenanceBox,
        (m) => m.vehicleId == vehicleId,
      );

      double totalDistance = trips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );
      double totalFuelCost = fuel.fold(0.0, (sum, f) => sum + f.totalCost);
      double totalMaintenanceCost = maintenance.fold(
        0.0,
        (sum, m) => sum + (m.cost ?? 0),
      );

      return {
        'vehicleId': vehicleId,
        'totalTrips': trips.length,
        'totalDistance': totalDistance,
        'totalFuelCost': totalFuelCost,
        'totalMaintenanceCost': totalMaintenanceCost,
        'avgFuelEfficiency': totalDistance > 0
            ? fuel.fold(0.0, (sum, f) => sum + f.liters) / totalDistance
            : 0,
        'maintenanceCount': maintenance.length,
        'lastMaintenance': maintenance.isNotEmpty
            ? maintenance
                  .map((m) => m.date)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      throw BusinessLogicException(
        'Failed to generate vehicle performance report: $e',
      );
    }
  }

  // Driver performance report
  Future<Map<String, dynamic>> generateDriverPerformanceReport(
    String driverId,
  ) async {
    try {
      final trips = await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.driverId == driverId,
      );

      final attendance = await HiveService().query<Attendance>(
        Constants.attendanceBox,
        (a) => a.driverId == driverId,
      );

      final presentDays = attendance.where((a) => a.status == 'present').length;
      double totalDistance = trips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );

      return {
        'driverId': driverId,
        'totalTrips': trips.length,
        'totalDistance': totalDistance,
        'attendanceRate': attendance.isNotEmpty
            ? presentDays / attendance.length
            : 0,
        'avgTripDistance': trips.isNotEmpty ? totalDistance / trips.length : 0,
        'lastTripDate': trips.isNotEmpty
            ? trips
                  .map((t) => t.startTime)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      throw BusinessLogicException(
        'Failed to generate driver performance report: $e',
      );
    }
  }

  // Export to CSV
  Future<String> exportReportToCsv(String reportType, dynamic data) async {
    try {
      switch (reportType) {
        case 'daily':
          return await CsvHelpers.exportToCsv<Map<String, dynamic>>(
            [data],
            'daily_report_${DateTime.now().millisecondsSinceEpoch}',
            ['Date', 'Total Trips', 'Fuel Cost', 'Distance', 'Attendance'],
            (d) => [
              d['date'].toString().split(' ')[0],
              d['totalTrips'],
              d['totalFuelCost'],
              d['totalDistance'],
              d['presentDrivers'],
            ],
          );
        case 'fuel':
          return await CsvHelpers.exportToCsv<FuelEntry>(
            data,
            'fuel_report_${DateTime.now().millisecondsSinceEpoch}',
            ['Date', 'Vehicle ID', 'Liters', 'Price/L', 'Total Cost', 'Vendor'],
            (f) => [
              f.date.toString().split(' ')[0],
              f.vehicleId,
              f.liters,
              f.pricePerLiter ?? 0,
              f.totalCost,
              f.vendor ?? '',
            ],
          );
        case 'monthly':
          return await CsvHelpers.exportToCsv<Map<String, dynamic>>(
            [data],
            'monthly_report_${DateTime.now().millisecondsSinceEpoch}',
            ['Period', 'Trips', 'Fuel Cost', 'Expenses', 'Distance', 'Cost/KM'],
            (d) => [
              d['period'],
              d['totalTrips'],
              d['totalFuelCost'],
              d['totalExpenses'],
              d['totalDistance'],
              d['costPerKm']?.toStringAsFixed(2) ?? '0',
            ],
          );
        default:
          throw BusinessLogicException('Unsupported report type: $reportType');
      }
    } catch (e) {
      throw ExportException('Failed to export report to CSV: $e');
    }
  }

  // Analytics: Fuel per KM
  Future<double> calculateFuelPerKm(
    String vehicleId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final trips = await generateTripReport(start, end);
      final vehicleTrips = trips.where((t) => t.vehicleId == vehicleId);
      double totalKm = vehicleTrips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );
      final fuel = await generateFuelReport(start, end);
      double totalLiters = fuel
          .where((f) => f.vehicleId == vehicleId)
          .fold(0.0, (sum, f) => sum + f.liters);

      return totalKm > 0 ? totalLiters / totalKm : 0;
    } catch (e) {
      throw BusinessLogicException('Failed to calculate fuel per KM: $e');
    }
  }

  // Anomalous detection
  Future<List<FuelEntry>> detectAnomalousFuel(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final fuel = await generateFuelReport(start, end);
      final avg = await _calculateAvgFuel();
      final threshold = AppConfig.anomalousFuelThreshold;

      return fuel.where((f) => f.liters > avg * threshold).toList();
    } catch (e) {
      throw BusinessLogicException(
        'Failed to detect anomalous fuel entries: $e',
      );
    }
  }

  // Maintenance due report
  Future<List<Vehicle>> getMaintenanceDueVehicles() async {
    try {
      final vehicles = await HiveService().getAll<Vehicle>(
        Constants.vehicleBox,
      );
      final maintenance = await HiveService().getAll<Maintenance>(
        Constants.maintenanceBox,
      );

      return vehicles.where((vehicle) {
        final vehicleMaintenance = maintenance
            .where((m) => m.vehicleId == vehicle.id)
            .toList();

        if (vehicleMaintenance.isEmpty) return true;

        final lastMaintenance = vehicleMaintenance
            .map((m) => m.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        final daysSinceMaintenance = DateTime.now()
            .difference(lastMaintenance)
            .inDays;
        return daysSinceMaintenance > 180; // 6 months threshold
      }).toList();
    } catch (e) {
      throw BusinessLogicException(
        'Failed to get maintenance due vehicles: $e',
      );
    }
  }

  // Budget vs Actual report
  Future<Map<String, dynamic>> generateBudgetVsActual(
    int year,
    int month,
  ) async {
    try {
      final monthlyReport = await generateMonthlyReport(year, month);
      final budget = Constants.monthlyFuelBudget; // From constants

      return {
        'period': monthlyReport['period'],
        'budget': budget,
        'actual': monthlyReport['totalFuelCost'],
        'variance': budget - monthlyReport['totalFuelCost'],
        'variancePercentage':
            (budget - monthlyReport['totalFuelCost']) / budget * 100,
        'isOverBudget': monthlyReport['totalFuelCost'] > budget,
      };
    } catch (e) {
      throw BusinessLogicException(
        'Failed to generate budget vs actual report: $e',
      );
    }
  }

  // Private method for avg fuel
  Future<double> _calculateAvgFuel() async {
    try {
      final allFuel = await HiveService().getAll<FuelEntry>(
        Constants.fuelEntryBox,
      );
      if (allFuel.isEmpty) return 0;
      return allFuel.fold(0.0, (sum, f) => sum + f.liters) / allFuel.length;
    } catch (e) {
      throw DatabaseException('Failed to calculate average fuel: $e');
    }
  }

  // Get report types
  List<String> getAvailableReportTypes() {
    return [
      'daily',
      'monthly',
      'fuel',
      'trip',
      'vehicle_performance',
      'driver_performance',
      'maintenance_due',
      'budget_vs_actual',
    ];
  }

  // Generate comprehensive fleet report
  Future<Map<String, dynamic>> generateFleetOverview() async {
    try {
      final vehicles = await HiveService().getAll<Vehicle>(
        Constants.vehicleBox,
      );
      final drivers = await HiveService().getAll<Driver>(Constants.driverBox);
      final trips = await HiveService().getAll<TripLog>(Constants.tripLogBox);
      final fuel = await HiveService().getAll<FuelEntry>(
        Constants.fuelEntryBox,
      );

      final activeVehicles = vehicles.where((v) => v.status == 'active').length;
      final activeDrivers = drivers.where((d) => d.status == 'active').length;
      final totalDistance = trips.fold(
        0.0,
        (sum, t) => sum + ((t.endKm ?? t.startKm) - t.startKm),
      );
      final totalFuelCost = fuel.fold(0.0, (sum, f) => sum + f.totalCost);

      return {
        'totalVehicles': vehicles.length,
        'activeVehicles': activeVehicles,
        'totalDrivers': drivers.length,
        'activeDrivers': activeDrivers,
        'totalDistance': totalDistance,
        'totalFuelCost': totalFuelCost,
        'avgFuelEfficiency': totalDistance > 0
            ? fuel.fold(0.0, (sum, f) => sum + f.liters) / totalDistance
            : 0,
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      throw BusinessLogicException('Failed to generate fleet overview: $e');
    }
  }
}
