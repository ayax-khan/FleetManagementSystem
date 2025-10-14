import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../utils/debug_utils.dart';
import '../services/api_service.dart';

class VehicleState {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? error;
  final Vehicle? selectedVehicle;

  const VehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
    this.selectedVehicle,
  });

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? error,
    Vehicle? selectedVehicle,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedVehicle: clearSelected ? null : (selectedVehicle ?? this.selectedVehicle),
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final Uuid _uuid = const Uuid();
  final ApiService _apiService = ApiService();
  bool _isOperationInProgress = false;

  VehicleNotifier() : super(const VehicleState()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    if (_isOperationInProgress) {
      DebugUtils.log('Load vehicles blocked - operation in progress', 'VEHICLE');
      return;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Loading vehicles from backend API', 'VEHICLE');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load from backend API
      final apiVehicles = await _apiService.getVehicles();
      
      // Convert API response to Vehicle objects
      final vehicles = apiVehicles.map((json) => _mapApiVehicleToModel(json)).toList();

      state = state.copyWith(
        vehicles: vehicles,
        isLoading: false,
      );

      DebugUtils.log('Loaded ${vehicles.length} vehicles from API', 'VEHICLE');
    } catch (e) {
      DebugUtils.logError('Failed to load vehicles from API', e);
      
      state = state.copyWith(
        vehicles: [], // Empty list when backend is not available
        isLoading: false,
        error: 'Failed to connect to backend: $e\n\nPlease ensure the backend is running.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> addVehicle(Vehicle vehicle) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Add vehicle blocked - operation in progress', 'VEHICLE');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Adding vehicle: ${vehicle.displayName}', 'VEHICLE');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      // Generate new ID and timestamps
      final newVehicle = vehicle.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to list
      final updatedVehicles = [...state.vehicles, newVehicle];
      
      state = state.copyWith(
        vehicles: updatedVehicles,
        isLoading: false,
      );

      DebugUtils.log('Vehicle added successfully: ${newVehicle.id}', 'VEHICLE');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add vehicle: $e',
      );
      DebugUtils.logError('Failed to add vehicle', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Update vehicle blocked - operation in progress', 'VEHICLE');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Updating vehicle: ${vehicle.displayName}', 'VEHICLE');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      // Update timestamps
      final updatedVehicle = vehicle.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in list
      final updatedVehicles = state.vehicles.map((v) {
        return v.id == updatedVehicle.id ? updatedVehicle : v;
      }).toList();
      
      state = state.copyWith(
        vehicles: updatedVehicles,
        isLoading: false,
        selectedVehicle: updatedVehicle,
      );

      DebugUtils.log('Vehicle updated successfully: ${updatedVehicle.id}', 'VEHICLE');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update vehicle: $e',
      );
      DebugUtils.logError('Failed to update vehicle', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Delete vehicle blocked - operation in progress', 'VEHICLE');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Deleting vehicle: $vehicleId', 'VEHICLE');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove from list
      final updatedVehicles = state.vehicles.where((v) => v.id != vehicleId).toList();
      
      state = state.copyWith(
        vehicles: updatedVehicles,
        isLoading: false,
        clearSelected: state.selectedVehicle?.id == vehicleId,
      );

      DebugUtils.log('Vehicle deleted successfully: $vehicleId', 'VEHICLE');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete vehicle: $e',
      );
      DebugUtils.logError('Failed to delete vehicle', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  void selectVehicle(Vehicle vehicle) {
    DebugUtils.log('Vehicle selected: ${vehicle.displayName}', 'VEHICLE');
    state = state.copyWith(selectedVehicle: vehicle);
  }

  void clearSelection() {
    DebugUtils.log('Vehicle selection cleared', 'VEHICLE');
    state = state.copyWith(clearSelected: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Search and filter methods
  List<Vehicle> searchVehicles(String query) {
    if (query.isEmpty) return state.vehicles;

    final lowerQuery = query.toLowerCase();
    return state.vehicles.where((vehicle) {
      return vehicle.make.toLowerCase().contains(lowerQuery) ||
             vehicle.model.toLowerCase().contains(lowerQuery) ||
             vehicle.licensePlate.toLowerCase().contains(lowerQuery) ||
             vehicle.year.contains(query) ||
             vehicle.vin.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Vehicle> filterByStatus(VehicleStatus status) {
    return state.vehicles.where((vehicle) => vehicle.status == status).toList();
  }

  List<Vehicle> filterByType(VehicleType type) {
    return state.vehicles.where((vehicle) => vehicle.type == type).toList();
  }

  // Statistics
  int get totalVehicles => state.vehicles.length;
  int get activeVehicles => state.vehicles.where((v) => v.status == VehicleStatus.active).length;
  int get inactiveVehicles => state.vehicles.where((v) => v.status == VehicleStatus.inactive).length;
  int get maintenanceVehicles => state.vehicles.where((v) => v.status == VehicleStatus.maintenance).length;

  double get averageAge {
    if (state.vehicles.isEmpty) return 0;
    final totalAge = state.vehicles.map((v) => v.ageInYears).reduce((a, b) => a + b);
    return totalAge / state.vehicles.length;
  }

  // Helper method to map API vehicle data to Flutter Vehicle model
  Vehicle _mapApiVehicleToModel(Map<String, dynamic> apiData) {
    DebugUtils.log('Mapping API vehicle: ${apiData.toString()}', 'VEHICLE');
    
    try {
      // The backend stores vehicles from Excel with field names like registration_number, make_type, etc.
      // We need to map these to our Flutter Vehicle model
      
      final now = DateTime.now();
      
      return Vehicle(
        id: apiData['id']?.toString() ?? _uuid.v4(),
        make: _extractMake(apiData['make_type']?.toString() ?? 'Unknown'),
        model: _extractModel(apiData['make_type']?.toString() ?? 'Unknown'),
        year: apiData['model_year']?.toString() ?? now.year.toString(),
        licensePlate: apiData['registration_number']?.toString() ?? 'N/A',
        vin: apiData['chassis_number']?.toString() ?? 'N/A',
        type: VehicleType.car, // Default to car, could be improved with logic
        status: VehicleStatus.active, // Default to active
        fuelCapacity: (apiData['engine_cc'] ?? 0).toDouble() / 100, // Rough estimate
        currentMileage: (apiData['current_odometer'] ?? 0).toDouble(),
        color: apiData['color']?.toString() ?? 'N/A',
        purchaseDate: apiData['purchase_date'] != null 
            ? DateTime.tryParse(apiData['purchase_date']) 
            : null,
        purchasePrice: apiData['purchase_price']?.toDouble(),
        notes: 'Imported from Excel',
        createdAt: apiData['created_at'] != null 
            ? DateTime.tryParse(apiData['created_at']) ?? now 
            : now,
        updatedAt: apiData['updated_at'] != null 
            ? DateTime.tryParse(apiData['updated_at']) ?? now 
            : now,
      );
    } catch (e) {
      DebugUtils.logError('Failed to map API vehicle data: ${apiData.toString()}', e);
      // Return a fallback vehicle if mapping fails
      final now = DateTime.now();
      return Vehicle(
        id: _uuid.v4(),
        make: 'Unknown',
        model: 'Unknown',
        year: now.year.toString(),
        licensePlate: 'N/A',
        vin: 'N/A',
        type: VehicleType.car,
        status: VehicleStatus.active,
        fuelCapacity: 50.0,
        currentMileage: 0.0,
        color: 'N/A',
        notes: 'Import error - check data',
        createdAt: now,
        updatedAt: now,
      );
    }
  }
  
  // Helper to extract make from "make_type" field
  String _extractMake(String makeType) {
    if (makeType.contains(' ')) {
      return makeType.split(' ')[0];
    }
    return makeType;
  }
  
  // Helper to extract model from "make_type" field  
  String _extractModel(String makeType) {
    if (makeType.contains(' ')) {
      final parts = makeType.split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
    }
    return 'Model';
  }

  // Mock data generator
  List<Vehicle> _generateMockVehicles() {
    final now = DateTime.now();
    return [
      Vehicle(
        id: '1',
        make: 'Toyota',
        model: 'Camry',
        year: '2022',
        licensePlate: 'ABC-123',
        vin: '1HGBH41JXMN109186',
        type: VehicleType.car,
        status: VehicleStatus.active,
        fuelCapacity: 60.0,
        currentMileage: 15000.0,
        color: 'White',
        purchaseDate: DateTime(2022, 6, 15),
        purchasePrice: 28000.0,
        notes: 'Company vehicle for executives',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Vehicle(
        id: '2',
        make: 'Ford',
        model: 'F-150',
        year: '2021',
        licensePlate: 'XYZ-789',
        vin: '1FTFW1ET5DFC10312',
        type: VehicleType.truck,
        status: VehicleStatus.active,
        fuelCapacity: 98.0,
        currentMileage: 32000.0,
        color: 'Blue',
        purchaseDate: DateTime(2021, 8, 20),
        purchasePrice: 45000.0,
        notes: 'Heavy duty work truck',
        createdAt: now.subtract(const Duration(days: 400)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Vehicle(
        id: '3',
        make: 'Honda',
        model: 'Civic',
        year: '2020',
        licensePlate: 'DEF-456',
        vin: '2HGFC2F59LH123456',
        type: VehicleType.car,
        status: VehicleStatus.maintenance,
        fuelCapacity: 47.0,
        currentMileage: 45000.0,
        color: 'Silver',
        purchaseDate: DateTime(2020, 3, 10),
        purchasePrice: 22000.0,
        notes: 'Currently in for oil change and tire rotation',
        createdAt: now.subtract(const Duration(days: 500)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  return VehicleNotifier();
});

// Computed providers for filtered data
final activeVehiclesProvider = Provider<List<Vehicle>>((ref) {
  final vehicleState = ref.watch(vehicleProvider);
  return vehicleState.vehicles.where((v) => v.status == VehicleStatus.active).toList();
});

final vehicleStatsProvider = Provider<Map<String, int>>((ref) {
  final vehicleState = ref.watch(vehicleProvider);
  return {
    'total': vehicleState.vehicles.length,
    'active': vehicleState.vehicles.where((v) => v.status == VehicleStatus.active).length,
    'inactive': vehicleState.vehicles.where((v) => v.status == VehicleStatus.inactive).length,
    'maintenance': vehicleState.vehicles.where((v) => v.status == VehicleStatus.maintenance).length,
  };
});