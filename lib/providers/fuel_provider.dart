import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fuel.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../services/api_service.dart';
import '../utils/debug_utils.dart';
import 'vehicle_provider.dart';
import 'driver_provider.dart';

// Fuel State
class FuelState {
  final List<FuelRecord> fuelRecords;
  final List<FuelStation> fuelStations;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;
  final FuelFilter filter;

  const FuelState({
    this.fuelRecords = const [],
    this.fuelStations = const [],
    this.isLoading = false,
    this.error,
    required this.selectedDate,
    this.filter = const FuelFilter(),
  });

  FuelState copyWith({
    List<FuelRecord>? fuelRecords,
    List<FuelStation>? fuelStations,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    FuelFilter? filter,
  }) {
    return FuelState(
      fuelRecords: fuelRecords ?? this.fuelRecords,
      fuelStations: fuelStations ?? this.fuelStations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedDate: selectedDate ?? this.selectedDate,
      filter: filter ?? this.filter,
    );
  }
}

// Fuel Notifier
class FuelNotifier extends StateNotifier<FuelState> {
  final ApiService _apiService;
  final Ref _ref;

  FuelNotifier(this._apiService, this._ref) 
      : super(FuelState(selectedDate: DateTime.now())) {
    loadFuelData();
  }

  // Load all fuel data
  Future<void> loadFuelData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      DebugUtils.log('Loading fuel records and stations', 'FUEL');
      
      // Mock data for now - replace with API call later
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockFuelRecords = _generateMockFuelRecords();
      final mockFuelStations = _generateMockFuelStations();
      
      state = state.copyWith(
        fuelRecords: mockFuelRecords,
        fuelStations: mockFuelStations,
        isLoading: false,
      );
      
      DebugUtils.log('Loaded ${mockFuelRecords.length} fuel records and ${mockFuelStations.length} stations', 'FUEL');
    } catch (e) {
      DebugUtils.logError('Error loading fuel data', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load fuel data: $e',
      );
    }
  }

  // Alias for compatibility
  Future<void> loadFuelRecords() async {
    return loadFuelData();
  }

  // Add fuel record
  Future<bool> addFuelRecord(FuelRecord fuelRecord) async {
    try {
      DebugUtils.log('Adding fuel record: ${fuelRecord.id}', 'FUEL');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Calculate consumption data if previous record exists
      final calculatedRecord = _calculateConsumptionData(fuelRecord);
      
      final updatedRecords = [calculatedRecord, ...state.fuelRecords];
      
      state = state.copyWith(fuelRecords: updatedRecords);
      
      DebugUtils.log('Fuel record added successfully: ${fuelRecord.id}', 'FUEL');
      return true;
    } catch (e) {
      DebugUtils.logError('Error adding fuel record', e);
      return false;
    }
  }

  // Update fuel record
  Future<bool> updateFuelRecord(FuelRecord fuelRecord) async {
    try {
      DebugUtils.log('Updating fuel record: ${fuelRecord.id}', 'FUEL');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final existingIndex = state.fuelRecords.indexWhere((r) => r.id == fuelRecord.id);
      if (existingIndex >= 0) {
        final calculatedRecord = _calculateConsumptionData(fuelRecord);
        
        final updatedRecords = List<FuelRecord>.from(state.fuelRecords);
        updatedRecords[existingIndex] = calculatedRecord.copyWith(
          updatedAt: DateTime.now(),
        );
        
        state = state.copyWith(fuelRecords: updatedRecords);
        
        DebugUtils.log('Fuel record updated successfully: ${fuelRecord.id}', 'FUEL');
        return true;
      }
      return false;
    } catch (e) {
      DebugUtils.logError('Error updating fuel record', e);
      return false;
    }
  }

  // Delete fuel record
  Future<bool> deleteFuelRecord(String recordId) async {
    try {
      DebugUtils.log('Deleting fuel record: $recordId', 'FUEL');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedRecords = state.fuelRecords.where((r) => r.id != recordId).toList();
      
      state = state.copyWith(fuelRecords: updatedRecords);
      
      DebugUtils.log('Fuel record deleted successfully: $recordId', 'FUEL');
      return true;
    } catch (e) {
      DebugUtils.logError('Error deleting fuel record', e);
      return false;
    }
  }

  // Search fuel records
  List<FuelRecord> searchFuelRecords(String query) {
    if (query.isEmpty) return state.fuelRecords;
    
    final lowercaseQuery = query.toLowerCase();
    return state.fuelRecords.where((record) {
      return record.vehicleName.toLowerCase().contains(lowercaseQuery) ||
             record.vehicleLicensePlate.toLowerCase().contains(lowercaseQuery) ||
             record.driverName.toLowerCase().contains(lowercaseQuery) ||
             record.fuelStationName.toLowerCase().contains(lowercaseQuery) ||
             record.receiptNumber?.toLowerCase().contains(lowercaseQuery) == true ||
             record.notes?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  // Filter fuel records
  List<FuelRecord> getFilteredFuelRecords(FuelFilter filter) {
    var filtered = List<FuelRecord>.from(state.fuelRecords);
    
    if (filter.startDate != null) {
      filtered = filtered.where((r) => r.date.isAfter(filter.startDate!.subtract(const Duration(days: 1)))).toList();
    }
    
    if (filter.endDate != null) {
      filtered = filtered.where((r) => r.date.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
    }
    
    if (filter.vehicleIds != null && filter.vehicleIds!.isNotEmpty) {
      filtered = filtered.where((r) => filter.vehicleIds!.contains(r.vehicleId)).toList();
    }
    
    if (filter.driverIds != null && filter.driverIds!.isNotEmpty) {
      filtered = filtered.where((r) => filter.driverIds!.contains(r.driverId)).toList();
    }
    
    if (filter.fuelTypes != null && filter.fuelTypes!.isNotEmpty) {
      filtered = filtered.where((r) => filter.fuelTypes!.contains(r.fuelType)).toList();
    }
    
    if (filter.paymentMethods != null && filter.paymentMethods!.isNotEmpty) {
      filtered = filtered.where((r) => filter.paymentMethods!.contains(r.paymentMethod)).toList();
    }
    
    if (filter.fuelStationIds != null && filter.fuelStationIds!.isNotEmpty) {
      filtered = filtered.where((r) => filter.fuelStationIds!.contains(r.fuelStationId)).toList();
    }
    
    if (filter.minAmount != null) {
      filtered = filtered.where((r) => r.totalCost >= filter.minAmount!).toList();
    }
    
    if (filter.maxAmount != null) {
      filtered = filtered.where((r) => r.totalCost <= filter.maxAmount!).toList();
    }
    
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      filtered = searchFuelRecords(filter.searchQuery!);
    }
    
    return filtered;
  }

  // Update selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // Update filter
  void updateFilter(FuelFilter filter) {
    state = state.copyWith(filter: filter);
  }

  // Clear filter
  void clearFilter() {
    state = state.copyWith(filter: const FuelFilter());
  }

  // Get vehicle info helper
  Map<String, String> _getVehicleInfo(String vehicleId) {
    try {
      final vehicles = _ref.read(vehicleProvider).vehicles;
      final vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
      return {
        'name': '${vehicle.make} ${vehicle.model}',
        'licensePlate': vehicle.licensePlate,
      };
    } catch (e) {
      return {
        'name': 'Unknown Vehicle',
        'licensePlate': 'UNKNOWN',
      };
    }
  }

  // Get driver info helper
  Map<String, String> _getDriverInfo(String driverId) {
    try {
      final drivers = _ref.read(driverProvider).drivers;
      final driver = drivers.firstWhere((d) => d.id == driverId);
      return {
        'name': driver.fullName,
      };
    } catch (e) {
      return {
        'name': 'Unknown Driver',
      };
    }
  }

  // Calculate consumption data based on previous records
  FuelRecord _calculateConsumptionData(FuelRecord record) {
    // Find previous fuel record for the same vehicle
    final vehicleRecords = state.fuelRecords
        .where((r) => r.vehicleId == record.vehicleId && r.date.isBefore(record.date))
        .toList();
    
    if (vehicleRecords.isEmpty) {
      return record; // No previous record to compare with
    }
    
    // Sort by date and get the most recent
    vehicleRecords.sort((a, b) => b.date.compareTo(a.date));
    final previousRecord = vehicleRecords.first;
    
    final distanceTraveled = record.odometer - previousRecord.odometer;
    double? fuelConsumption;
    
    if (distanceTraveled > 0) {
      // Calculate consumption in L/100km
      fuelConsumption = (record.quantity / distanceTraveled) * 100;
    }
    
    return record.copyWith(
      previousOdometer: previousRecord.odometer,
      distanceTraveled: distanceTraveled > 0 ? distanceTraveled : null,
      fuelConsumption: fuelConsumption,
    );
  }

  // Generate mock fuel records
  List<FuelRecord> _generateMockFuelRecords() {
    final now = DateTime.now();
    final mockRecords = <FuelRecord>[];
    
    // Get some vehicles and drivers for mock data
    final vehicles = _ref.read(vehicleProvider).vehicles;
    final drivers = _ref.read(driverProvider).drivers;
    final stations = _generateMockFuelStations();
    
    if (vehicles.isEmpty || drivers.isEmpty || stations.isEmpty) return mockRecords;
    
    // Generate fuel records for last 60 days
    for (int i = 0; i < 60; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Random chance of fuel record each day
      if (i % 3 == 0) { // Every 3rd day on average
        for (final vehicle in vehicles.take(2)) { // Use first 2 vehicles
          final driver = drivers.first; // Use first driver
          final station = stations[i % stations.length];
          final fuelType = _getVehicleFuelType(vehicle);
          
          final quantity = 30 + (i % 40); // 30-70 liters
          final unitPrice = _getFuelPrice(fuelType, i);
          final odometer = 50000 + (i * 150) + (vehicle.hashCode % 1000);
          
          mockRecords.add(
            FuelRecord(
              id: '${vehicle.id}_${date.millisecondsSinceEpoch}',
              vehicleId: vehicle.id,
              vehicleName: '${vehicle.make} ${vehicle.model}',
              vehicleLicensePlate: vehicle.licensePlate,
              driverId: driver.id,
              driverName: driver.fullName,
              date: date,
              quantity: quantity.toDouble(),
              unitPrice: unitPrice,
              totalCost: quantity * unitPrice,
              fuelStationId: station.id,
              fuelStationName: station.name,
              fuelType: fuelType,
              odometer: odometer.toDouble(),
              paymentMethod: _getRandomPaymentMethod(i),
              receiptNumber: i % 5 == 0 ? 'R${1000 + i}' : null,
              location: station.location,
              notes: i % 7 == 0 ? 'Regular fill-up' : null,
              createdAt: date,
              updatedAt: date,
            ),
          );
        }
      }
    }
    
    // Sort by date (newest first) and calculate consumption
    mockRecords.sort((a, b) => b.date.compareTo(a.date));
    
    // Calculate consumption data for each record
    final calculatedRecords = <FuelRecord>[];
    for (int i = mockRecords.length - 1; i >= 0; i--) {
      final record = mockRecords[i];
      
      // Find previous record for the same vehicle
      final previousRecords = calculatedRecords
          .where((r) => r.vehicleId == record.vehicleId && r.date.isBefore(record.date))
          .toList();
      
      if (previousRecords.isNotEmpty) {
        previousRecords.sort((a, b) => b.date.compareTo(a.date));
        final previous = previousRecords.first;
        
        final distance = record.odometer - previous.odometer;
        final consumption = distance > 0 ? (record.quantity / distance) * 100 : null;
        
        calculatedRecords.add(record.copyWith(
          previousOdometer: previous.odometer,
          distanceTraveled: distance > 0 ? distance : null,
          fuelConsumption: consumption,
        ));
      } else {
        calculatedRecords.add(record);
      }
    }
    
    return calculatedRecords..sort((a, b) => b.date.compareTo(a.date));
  }

  // Generate mock fuel stations
  List<FuelStation> _generateMockFuelStations() {
    final now = DateTime.now();
    return [
      FuelStation(
        id: 'station_1',
        name: 'PSO',
        location: 'Main Street',
        latitude: 24.8607,
        longitude: 67.0011,
        phone: '+92-21-34567890',
        availableFuelTypes: [FuelType.petrol, FuelType.diesel, FuelType.cng],
        currentPrices: {
          FuelType.petrol: 272.89,
          FuelType.diesel: 283.63,
          FuelType.cng: 89.68,
        },
        rating: 4.2,
        createdAt: now,
        updatedAt: now,
      ),
      FuelStation(
        id: 'station_2',
        name: 'Shell',
        location: 'Commercial Area',
        latitude: 24.8615,
        longitude: 67.0025,
        phone: '+92-21-34567891',
        availableFuelTypes: [FuelType.petrol, FuelType.diesel],
        currentPrices: {
          FuelType.petrol: 274.50,
          FuelType.diesel: 285.20,
        },
        rating: 4.5,
        createdAt: now,
        updatedAt: now,
      ),
      FuelStation(
        id: 'station_3',
        name: 'Total',
        location: 'Highway Junction',
        latitude: 24.8590,
        longitude: 67.0040,
        phone: '+92-21-34567892',
        availableFuelTypes: [FuelType.petrol, FuelType.diesel, FuelType.cng],
        currentPrices: {
          FuelType.petrol: 273.75,
          FuelType.diesel: 284.40,
          FuelType.cng: 90.15,
        },
        rating: 4.0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  FuelType _getVehicleFuelType(Vehicle vehicle) {
    switch (vehicle.type) {
      case VehicleType.car:
        return FuelType.petrol;
      case VehicleType.truck:
      case VehicleType.bus:
        return FuelType.diesel;
      case VehicleType.van:
        return FuelType.cng;
      default:
        return FuelType.petrol;
    }
  }

  double _getFuelPrice(FuelType fuelType, int dayOffset) {
    final basePrice = {
      FuelType.petrol: 272.89,
      FuelType.diesel: 283.63,
      FuelType.cng: 89.68,
    };
    
    // Add some price variation over time
    final variation = (dayOffset % 10) * 0.5;
    return (basePrice[fuelType] ?? 272.89) + variation;
  }

  PaymentMethod _getRandomPaymentMethod(int seed) {
    switch (seed % 5) {
      case 0: return PaymentMethod.cash;
      case 1: return PaymentMethod.card;
      case 2: return PaymentMethod.fuelCard;
      case 3: return PaymentMethod.companyAccount;
      default: return PaymentMethod.digitalWallet;
    }
  }
}

// Provider
final fuelProvider = StateNotifierProvider<FuelNotifier, FuelState>((ref) {
  return FuelNotifier(ApiService(), ref);
});

// Computed providers for statistics
final fuelStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final fuelRecords = ref.watch(fuelProvider).fuelRecords;
  
  if (fuelRecords.isEmpty) {
    return {
      'total_records': 0,
      'total_cost': 0.0,
      'total_liters': 0.0,
      'average_price': 0.0,
      'total_distance': 0.0,
      'average_consumption': 0.0,
    };
  }
  
  final totalRecords = fuelRecords.length;
  final totalCost = fuelRecords.fold(0.0, (sum, r) => sum + r.totalCost);
  final totalLiters = fuelRecords.fold(0.0, (sum, r) => sum + r.quantity);
  final averagePrice = totalLiters > 0 ? totalCost / totalLiters : 0.0;
  
  final recordsWithDistance = fuelRecords.where((r) => r.distanceTraveled != null).toList();
  final totalDistance = recordsWithDistance.fold(0.0, (sum, r) => sum + r.distanceTraveled!);
  
  final recordsWithConsumption = fuelRecords.where((r) => r.fuelConsumption != null).toList();
  final averageConsumption = recordsWithConsumption.isNotEmpty
      ? recordsWithConsumption.fold(0.0, (sum, r) => sum + r.fuelConsumption!) / recordsWithConsumption.length
      : 0.0;
  
  return {
    'total_records': totalRecords,
    'total_cost': totalCost,
    'total_liters': totalLiters,
    'average_price': averagePrice,
    'total_distance': totalDistance,
    'average_consumption': averageConsumption,
  };
});

// This month's fuel records
final thisMonthFuelRecordsProvider = Provider<List<FuelRecord>>((ref) {
  final fuelRecords = ref.watch(fuelProvider).fuelRecords;
  final now = DateTime.now();
  
  return fuelRecords.where((record) {
    return record.date.year == now.year &&
           record.date.month == now.month;
  }).toList();
});

// Vehicle fuel analytics
final vehicleFuelAnalyticsProvider = Provider.family<VehicleFuelAnalytics?, String>((ref, vehicleId) {
  final fuelRecords = ref.watch(fuelProvider).fuelRecords;
  final vehicles = ref.watch(vehicleProvider).vehicles;
  
  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
  if (vehicle == null) return null;
  
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  
  return VehicleFuelAnalytics.fromRecords(
    vehicleId,
    '${vehicle.make} ${vehicle.model}',
    monthStart,
    monthEnd,
    fuelRecords,
  );
});

// Top fuel consuming vehicles
final topFuelConsumingVehiclesProvider = Provider<List<VehicleFuelAnalytics>>((ref) {
  final vehicles = ref.watch(vehicleProvider).vehicles;
  final fuelRecords = ref.watch(fuelProvider).fuelRecords;
  
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  
  final analytics = <VehicleFuelAnalytics>[];
  
  for (final vehicle in vehicles) {
    final vehicleAnalytics = VehicleFuelAnalytics.fromRecords(
      vehicle.id,
      '${vehicle.make} ${vehicle.model}',
      monthStart,
      monthEnd,
      fuelRecords,
    );
    
    if (vehicleAnalytics.totalCost > 0) {
      analytics.add(vehicleAnalytics);
    }
  }
  
  // Sort by total cost (highest first)
  analytics.sort((a, b) => b.totalCost.compareTo(a.totalCost));
  
  return analytics.take(5).toList();
});

// Fuel efficiency alerts
final fuelEfficiencyAlertsProvider = Provider<List<VehicleFuelAnalytics>>((ref) {
  final vehicles = ref.watch(vehicleProvider).vehicles;
  final fuelRecords = ref.watch(fuelProvider).fuelRecords;
  
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  
  final alerts = <VehicleFuelAnalytics>[];
  
  for (final vehicle in vehicles) {
    final vehicleAnalytics = VehicleFuelAnalytics.fromRecords(
      vehicle.id,
      '${vehicle.make} ${vehicle.model}',
      monthStart,
      monthEnd,
      fuelRecords,
    );
    
    // Alert if efficiency is poor or terrible
    if (vehicleAnalytics.averageConsumption > 0 && 
        (vehicleAnalytics.efficiencyRating == FuelEfficiencyRating.poor ||
         vehicleAnalytics.efficiencyRating == FuelEfficiencyRating.terrible)) {
      alerts.add(vehicleAnalytics);
    }
  }
  
  // Sort by consumption (worst first)
  alerts.sort((a, b) => b.averageConsumption.compareTo(a.averageConsumption));
  
  return alerts;
});