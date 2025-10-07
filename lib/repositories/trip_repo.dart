// lib/repositories/trip_repo.dart
import '../services/hive_service.dart';
import '../models/trip_log.dart';
import '../core/utils/validators.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/errors/app_exceptions.dart';

class TripRepo {
  static final TripRepo _instance = TripRepo._internal();
  factory TripRepo() => _instance;
  TripRepo._internal();

  Future<void> addTrip(TripLog trip) async {
    try {
      if (!Validators.isValidTripKm(trip.startKm, trip.endKm)) {
        throw ValidationException({
          'endKm': 'End KM must be greater than start KM',
        });
      }
      await HiveService().add<TripLog>(Constants.tripLogBox, trip);
      Logger.info('Trip added: ${trip.id}');
    } catch (e) {
      Logger.error('Failed to add trip', error: e);
      rethrow;
    }
  }

  Future<TripLog?> getTrip(String id) async {
    try {
      return await HiveService().get<TripLog>(Constants.tripLogBox, id);
    } catch (e) {
      Logger.error('Failed to get trip: $id', error: e);
      throw DatabaseException('Failed to get trip: $e');
    }
  }

  Future<List<TripLog>> getAllTrips() async {
    try {
      return await HiveService().getAll<TripLog>(Constants.tripLogBox);
    } catch (e) {
      Logger.error('Failed to get all trips', error: e);
      throw DatabaseException('Failed to get trips: $e');
    }
  }

  Future<void> updateTrip(String id, TripLog trip) async {
    try {
      if (!Validators.isValidTripKm(trip.startKm, trip.endKm)) {
        throw ValidationException({
          'endKm': 'End KM must be greater than start KM',
        });
      }
      await HiveService().update<TripLog>(Constants.tripLogBox, id, trip);
      Logger.info('Trip updated: $id');
    } catch (e) {
      Logger.error('Failed to update trip: $id', error: e);
      rethrow;
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await HiveService().delete<TripLog>(Constants.tripLogBox, id);
      Logger.info('Trip deleted: $id');
    } catch (e) {
      Logger.error('Failed to delete trip: $id', error: e);
      throw DatabaseException('Failed to delete trip: $e');
    }
  }

  // Get trips by vehicle
  Future<List<TripLog>> getTripsByVehicle(String vehicleId) async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.vehicleId == vehicleId,
      );
    } catch (e) {
      Logger.error('Failed to get trips by vehicle: $vehicleId', error: e);
      throw DatabaseException('Failed to get trips by vehicle: $e');
    }
  }

  // Get trips by driver
  Future<List<TripLog>> getTripsByDriver(String driverId) async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.driverId == driverId,
      );
    } catch (e) {
      Logger.error('Failed to get trips by driver: $driverId', error: e);
      throw DatabaseException('Failed to get trips by driver: $e');
    }
  }

  // Get ongoing trips
  Future<List<TripLog>> getOngoingTrips() async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.status == 'ongoing',
      );
    } catch (e) {
      Logger.error('Failed to get ongoing trips', error: e);
      throw DatabaseException('Failed to get ongoing trips: $e');
    }
  }

  // Get completed trips
  Future<List<TripLog>> getCompletedTrips() async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) => t.status == 'completed',
      );
    } catch (e) {
      Logger.error('Failed to get completed trips', error: e);
      throw DatabaseException('Failed to get completed trips: $e');
    }
  }

  // Complete trip
  Future<void> completeTrip(String id, double endKm, DateTime endTime) async {
    try {
      final trip = await getTrip(id);
      if (trip != null) {
        if (endKm <= trip.startKm) {
          throw ValidationException({
            'endKm': 'End KM must be greater than start KM',
          });
        }

        trip.endKm = endKm;
        trip.endTime = endTime;
        trip.status = 'completed';
        await updateTrip(id, trip);
        Logger.info('Trip completed: $id');
      } else {
        throw DataNotFoundException('Trip');
      }
    } catch (e) {
      Logger.error('Failed to complete trip: $id', error: e);
      rethrow;
    }
  }

  // Start trip
  Future<void> startTrip(String id, double startKm, DateTime startTime) async {
    try {
      final trip = await getTrip(id);
      if (trip != null) {
        trip.startKm = startKm;
        trip.startTime = startTime;
        trip.status = 'ongoing';
        await updateTrip(id, trip);
        Logger.info('Trip started: $id');
      } else {
        throw DataNotFoundException('Trip');
      }
    } catch (e) {
      Logger.error('Failed to start trip: $id', error: e);
      rethrow;
    }
  }

  // Calculate total KM for period
  Future<double> calculateTotalKm(DateTime start, DateTime end) async {
    try {
      final trips = await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) =>
            t.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
            t.startTime.isBefore(end.add(const Duration(days: 1))),
      );

      double totalKm = 0.0;
      for (final trip in trips) {
        if (trip.endKm != null) {
          totalKm += (trip.endKm! - trip.startKm);
        }
      }
      return totalKm;
    } catch (e) {
      Logger.error('Failed to calculate total KM', error: e);
      throw DatabaseException('Failed to calculate total KM: $e');
    }
  }

  // Calculate total KM for vehicle
  Future<double> calculateVehicleTotalKm(
    String vehicleId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final trips = await getTripsByVehicle(vehicleId);
      final filteredTrips = trips.where(
        (t) =>
            t.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
            t.startTime.isBefore(end.add(const Duration(days: 1))),
      );

      double totalKm = 0.0;
      for (final trip in filteredTrips) {
        if (trip.endKm != null) {
          totalKm += (trip.endKm! - trip.startKm);
        }
      }
      return totalKm;
    } catch (e) {
      Logger.error(
        'Failed to calculate vehicle total KM: $vehicleId',
        error: e,
      );
      throw DatabaseException('Failed to calculate vehicle total KM: $e');
    }
  }

  // Get trips by date range
  Future<List<TripLog>> getTripsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await HiveService().query<TripLog>(
        Constants.tripLogBox,
        (t) =>
            t.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
            t.startTime.isBefore(end.add(const Duration(days: 1))),
      );
    } catch (e) {
      Logger.error('Failed to get trips by date range', error: e);
      throw DatabaseException('Failed to get trips by date range: $e');
    }
  }

  // Get recent trips
  Future<List<TripLog>> getRecentTrips({int limit = 10}) async {
    try {
      final allTrips = await getAllTrips();
      allTrips.sort((a, b) => b.startTime.compareTo(a.startTime));
      return allTrips.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to get recent trips', error: e);
      throw DatabaseException('Failed to get recent trips: $e');
    }
  }

  // Search trips
  Future<List<TripLog>> searchTrips(String query) async {
    try {
      final allTrips = await getAllTrips();
      return allTrips
          .where(
            (trip) =>
                trip.vehicleId.toLowerCase().contains(query.toLowerCase()) ||
                trip.driverId.toLowerCase().contains(query.toLowerCase()) ||
                trip.purpose?.toLowerCase().contains(query.toLowerCase()) ==
                    true ||
                trip.routeTaken?.toLowerCase().contains(query.toLowerCase()) ==
                    true,
          )
          .toList();
    } catch (e) {
      Logger.error('Failed to search trips: $query', error: e);
      throw DatabaseException('Failed to search trips: $e');
    }
  }

  // Get trips statistics
  Future<Map<String, dynamic>> getTripsStats(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final trips = await getTripsByDateRange(start, end);
      final completedTrips = trips.where((t) => t.status == 'completed').length;
      final ongoingTrips = trips.where((t) => t.status == 'ongoing').length;
      final totalDistance = await calculateTotalKm(start, end);
      final avgDistance = completedTrips > 0
          ? totalDistance / completedTrips
          : 0;

      return {
        'totalTrips': trips.length,
        'completedTrips': completedTrips,
        'ongoingTrips': ongoingTrips,
        'totalDistance': totalDistance,
        'averageDistance': avgDistance,
        'period': '$start to $end',
      };
    } catch (e) {
      Logger.error('Failed to get trips statistics', error: e);
      throw DatabaseException('Failed to get trips statistics: $e');
    }
  }

  // Validate trip data
  static String? validateTrip(TripLog trip) {
    String? error = Validators.requiredField(trip.vehicleId, 'Vehicle');
    if (error != null) return error;

    error = Validators.requiredField(trip.driverId, 'Driver');
    if (error != null) return error;

    if (!Validators.isValidOdometer(trip.startKm)) {
      return 'Invalid start KM';
    }

    if (trip.endKm != null &&
        !Validators.isValidTripKm(trip.startKm, trip.endKm)) {
      return 'End KM must be greater than start KM';
    }

    if (!Validators.isValidTripStatus(trip.status)) {
      return 'Invalid trip status';
    }

    return null;
  }
}
