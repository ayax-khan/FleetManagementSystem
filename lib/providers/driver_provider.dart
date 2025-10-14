import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/driver.dart';
import '../utils/debug_utils.dart';
import '../services/api_service.dart';

class DriverState {
  final List<Driver> drivers;
  final bool isLoading;
  final String? error;
  final Driver? selectedDriver;

  const DriverState({
    this.drivers = const [],
    this.isLoading = false,
    this.error,
    this.selectedDriver,
  });

  DriverState copyWith({
    List<Driver>? drivers,
    bool? isLoading,
    String? error,
    Driver? selectedDriver,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return DriverState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedDriver: clearSelected ? null : (selectedDriver ?? this.selectedDriver),
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final Uuid _uuid = const Uuid();
  final ApiService _apiService = ApiService();
  bool _isOperationInProgress = false;

  DriverNotifier() : super(const DriverState()) {
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    if (_isOperationInProgress) {
      DebugUtils.log('Load drivers blocked - operation in progress', 'DRIVER');
      return;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Loading drivers from backend API', 'DRIVER');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load from backend API
      final apiDrivers = await _apiService.getDrivers();
      
      // Convert API response to Driver objects
      final drivers = apiDrivers.map((json) => _mapApiDriverToModel(json)).toList();

      state = state.copyWith(
        drivers: drivers,
        isLoading: false,
      );

      DebugUtils.log('Loaded ${drivers.length} drivers from API', 'DRIVER');
    } catch (e) {
      DebugUtils.logError('Failed to load drivers from API', e);
      
      state = state.copyWith(
        drivers: [], // Empty list when backend is not available
        isLoading: false,
        error: 'Failed to connect to backend: $e\n\nPlease ensure the backend is running.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> addDriver(Driver driver) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Add driver blocked - operation in progress', 'DRIVER');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Adding driver: ${driver.fullName}', 'DRIVER');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Generate employee ID and prepare data for API
      final generatedEmployeeId = _generateEmployeeId(driver.category);
      DebugUtils.log('Generated employee ID: $generatedEmployeeId', 'DRIVER');
      
      DebugUtils.log('Creating driver copy with employee ID', 'DRIVER');
      final driverToCreate = driver.copyWith(
        employeeId: generatedEmployeeId,
      );
      
      DebugUtils.log('Converting driver to JSON', 'DRIVER');
      final driverData = driverToCreate.toJson();
      DebugUtils.log('Driver JSON keys: ${driverData.keys.toList()}', 'DRIVER');
      
      DebugUtils.log('Sending driver data to API: ${driverData.toString()}', 'DRIVER');

      // Send to backend API
      final createdDriverData = await _apiService.createDriver(driverData);
      DebugUtils.log('Received driver data from API: ${createdDriverData.toString()}', 'DRIVER');
      
      final newDriver = _mapApiDriverToModel(createdDriverData);

      // Add to local state
      final updatedDrivers = [...state.drivers, newDriver];
      
      state = state.copyWith(
        drivers: updatedDrivers,
        isLoading: false,
      );

      DebugUtils.log('Driver added successfully: ${newDriver.id}', 'DRIVER');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add driver: $e',
      );
      DebugUtils.logError('Failed to add driver', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> updateDriver(Driver driver) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Update driver blocked - operation in progress', 'DRIVER');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Updating driver: ${driver.fullName}', 'DRIVER');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      DebugUtils.log('Converting driver to JSON for update: ${driver.fullName}', 'DRIVER');
      final driverData = driver.toJson();
      DebugUtils.log('Update driver JSON keys: ${driverData.keys.toList()}', 'DRIVER');
      
      // Send update to backend API
      final updatedDriverData = await _apiService.updateDriver(driver.id, driverData);
      DebugUtils.log('Received updated driver data from API: ${updatedDriverData.toString()}', 'DRIVER');
      
      // Handle case where API returns empty data due to redirect or other issues
      if (updatedDriverData.isEmpty || updatedDriverData['id'] == null) {
        DebugUtils.log('API returned empty data, using original driver data', 'DRIVER');
        // Update local state with the driver data we sent
        final updatedDrivers = state.drivers.map((d) {
          return d.id == driver.id ? driver : d;
        }).toList();
        
        state = state.copyWith(
          drivers: updatedDrivers,
          isLoading: false,
          selectedDriver: driver,
        );
        
        DebugUtils.log('Driver updated successfully (local data): ${driver.id}', 'DRIVER');
        return true;
      }
      
      DebugUtils.log('Mapping updated driver data using _mapApiDriverToModel', 'DRIVER');
      final updatedDriver = _mapApiDriverToModel(updatedDriverData);

      // Update in local state
      final updatedDrivers = state.drivers.map((d) {
        return d.id == updatedDriver.id ? updatedDriver : d;
      }).toList();
      
      state = state.copyWith(
        drivers: updatedDrivers,
        isLoading: false,
        selectedDriver: updatedDriver,
      );

      DebugUtils.log('Driver updated successfully: ${updatedDriver.id}', 'DRIVER');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update driver: $e',
      );
      DebugUtils.logError('Failed to update driver', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Delete driver blocked - operation in progress', 'DRIVER');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Deleting driver: $driverId', 'DRIVER');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Send delete to backend API
      final success = await _apiService.deleteDriver(driverId);
      
      if (success) {
        // Remove from local state
        final updatedDrivers = state.drivers.where((d) => d.id != driverId).toList();
        
        state = state.copyWith(
          drivers: updatedDrivers,
          isLoading: false,
          clearSelected: state.selectedDriver?.id == driverId,
        );

        DebugUtils.log('Driver deleted successfully: $driverId', 'DRIVER');
        return true;
      } else {
        throw Exception('Backend deletion failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete driver: $e',
      );
      DebugUtils.logError('Failed to delete driver', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  void selectDriver(Driver driver) {
    DebugUtils.log('Driver selected: ${driver.fullName}', 'DRIVER');
    state = state.copyWith(selectedDriver: driver);
  }

  void clearSelection() {
    DebugUtils.log('Driver selection cleared', 'DRIVER');
    state = state.copyWith(clearSelected: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  // Generate employee ID based on category
  String _generateEmployeeId(DriverCategory category) {
    DebugUtils.log('Generating employee ID for category: ${category.name}', 'DRIVER');
    
    final categoryDrivers = state.drivers
        .where((d) => d.category == category)
        .toList();
    
    DebugUtils.log('Found ${categoryDrivers.length} drivers in category ${category.name}', 'DRIVER');
    
    String prefix;
    switch (category) {
      case DriverCategory.transportOfficial:
        prefix = 'TO';
        break;
      case DriverCategory.generalDrivers:
        prefix = 'GD';
        break;
      case DriverCategory.shiftDrivers:
        prefix = 'SD';
        break;
      case DriverCategory.entitledDrivers:
        prefix = 'ED';
        break;
      case DriverCategory.regular:
        prefix = 'RG';
        break;
      case DriverCategory.trainee:
        prefix = 'TR';
        break;
      case DriverCategory.contractor:
        prefix = 'CT';
        break;
      case DriverCategory.partTime:
        prefix = 'PT';
        break;
      default:
        prefix = 'DR';
    }
    
    // Find the highest existing number for this category
    int maxNumber = 0;
    final prefixLength = prefix.length;
    
    for (final driver in categoryDrivers) {
      final employeeId = driver.employeeId;
      if (employeeId.startsWith(prefix) && employeeId.length > prefixLength) {
        final numberPart = employeeId.substring(prefixLength);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    final nextNumber = maxNumber + 1;
    final generatedId = '$prefix${nextNumber.toString().padLeft(3, '0')}';
    
    DebugUtils.log('Generated employee ID: $generatedId', 'DRIVER');
    return generatedId;
  }

  // Helper methods for safe enum parsing
  DriverStatus _parseDriverStatus(dynamic statusValue) {
    if (statusValue == null) return DriverStatus.active;
    
    try {
      final statusStr = statusValue.toString().toLowerCase();
      
      // Try exact match first
      try {
        return DriverStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == statusStr,
        );
      } catch (e) {
        // Try display name match
        try {
          return DriverStatus.values.firstWhere(
            (e) => e.displayName.toLowerCase() == statusStr,
          );
        } catch (e) {
          DebugUtils.logError('Unknown driver status: $statusValue, using default', e);
          return DriverStatus.active;
        }
      }
    } catch (e) {
      DebugUtils.logError('Error parsing driver status: $statusValue', e);
      return DriverStatus.active;
    }
  }
  
  DriverCategory _parseDriverCategory(dynamic categoryValue) {
    if (categoryValue == null) return DriverCategory.regular;
    
    try {
      final categoryStr = categoryValue.toString().toLowerCase();
      
      // Try exact match first
      try {
        return DriverCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryStr,
        );
      } catch (e) {
        // Try display name match
        try {
          return DriverCategory.values.firstWhere(
            (e) => e.displayName.toLowerCase() == categoryStr,
          );
        } catch (e) {
          DebugUtils.logError('Unknown driver category: $categoryValue, using default', e);
          return DriverCategory.regular;
        }
      }
    } catch (e) {
      DebugUtils.logError('Error parsing driver category: $categoryValue', e);
      return DriverCategory.regular;
    }
  }
  
  LicenseCategory _parseLicenseCategory(dynamic licenseCategoryValue) {
    if (licenseCategoryValue == null) return LicenseCategory.lightVehicle;
    
    try {
      final licenseCategoryStr = licenseCategoryValue.toString().toLowerCase();
      
      // Try exact match first
      try {
        return LicenseCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == licenseCategoryStr,
        );
      } catch (e) {
        // Try display name match
        try {
          return LicenseCategory.values.firstWhere(
            (e) => e.displayName.toLowerCase() == licenseCategoryStr,
          );
        } catch (e) {
          DebugUtils.logError('Unknown license category: $licenseCategoryValue, using default', e);
          return LicenseCategory.lightVehicle;
        }
      }
    } catch (e) {
      DebugUtils.logError('Error parsing license category: $licenseCategoryValue', e);
      return LicenseCategory.lightVehicle;
    }
  }

  // Helper method to map API driver data to Flutter Driver model
  Driver _mapApiDriverToModel(Map<String, dynamic> apiData) {
    DebugUtils.log('Mapping API driver: ${apiData.toString()}', 'DRIVER');
    
    // Handle null or empty data
    if (apiData.isEmpty) {
      DebugUtils.logError('API data is empty, cannot map driver', null);
      throw Exception('Empty API response data');
    }
    
    try {
      final now = DateTime.now();
      
      // Safe enum parsing with helper methods
      final status = _parseDriverStatus(apiData['status']);
      final category = _parseDriverCategory(apiData['category']);
      final licenseCategory = _parseLicenseCategory(apiData['license_category']);
      
      // Safe date parsing
      DateTime parseDate(String? dateStr, DateTime fallback) {
        if (dateStr == null || dateStr.isEmpty) return fallback;
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          DebugUtils.logError('Failed to parse date: $dateStr', e);
          return fallback;
        }
      }
      
      // Parse the 'name' field from backend and split it into first and last names
      String fullNameFromBackend = apiData['name']?.toString() ?? '';
      List<String> nameParts = fullNameFromBackend.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts.first : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      // Parse emergency contact if it's in "Name: Number" format
      String? emergencyContact = apiData['emergency_contact']?.toString();
      String? emergencyContactName;
      String? emergencyContactNumber;
      
      if (emergencyContact != null && emergencyContact.contains(':')) {
        List<String> parts = emergencyContact.split(':');
        emergencyContactName = parts[0].trim();
        if (parts.length > 1) {
          emergencyContactNumber = parts[1].trim();
        }
      } else {
        emergencyContactName = emergencyContact;
      }
      
      return Driver(
        id: apiData['id']?.toString() ?? _uuid.v4(),
        firstName: firstName,
        lastName: lastName,
        employeeId: apiData['employee_id']?.toString() ?? '',
        cnic: apiData['cnic']?.toString() ?? '', // Backend doesn't have CNIC, using default
        phoneNumber: apiData['phone']?.toString() ?? '', // Backend uses 'phone'
        email: apiData['email']?.toString(),
        address: apiData['address']?.toString() ?? '',
        dateOfBirth: parseDate(apiData['date_of_birth']?.toString(), now.subtract(const Duration(days: 365 * 30))),
        joiningDate: parseDate(apiData['joining_date']?.toString(), now),
        status: status,
        category: category,
        licenseNumber: apiData['license_number']?.toString() ?? '',
        licenseCategory: licenseCategory,
        licenseExpiryDate: parseDate(apiData['license_expiry']?.toString(), now.add(const Duration(days: 365))), // Backend uses 'license_expiry'
        basicSalary: (apiData['basic_salary'] ?? 50000).toDouble(), // Default since backend doesn't have this
        vehicleAssigned: apiData['assigned_vehicle']?.toString(), // Backend uses 'assigned_vehicle'
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
        notes: apiData['notes']?.toString(),
        createdAt: parseDate(apiData['created_at']?.toString(), now),
        updatedAt: parseDate(apiData['updated_at']?.toString(), now),
      );
    } catch (e) {
      DebugUtils.logError('Failed to map API driver data: ${apiData.toString()}', e);
      // Return a fallback driver if mapping fails
      final now = DateTime.now();
      return Driver(
        id: _uuid.v4(),
        firstName: 'Error',
        lastName: 'Driver',
        employeeId: 'ERROR',
        cnic: '00000-0000000-0',
        phoneNumber: '0000-0000000',
        address: 'Unknown Address',
        dateOfBirth: now.subtract(const Duration(days: 365 * 30)),
        joiningDate: now,
        status: DriverStatus.active,
        category: DriverCategory.regular,
        licenseNumber: 'UNKNOWN',
        licenseCategory: LicenseCategory.lightVehicle,
        licenseExpiryDate: now.add(const Duration(days: 365)),
        basicSalary: 50000.0,
        notes: 'Mapping error - check backend data format',
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  // Search and filter methods
  List<Driver> searchDrivers(String query) {
    if (query.isEmpty) return state.drivers;

    final lowerQuery = query.toLowerCase();
    return state.drivers.where((driver) {
      return driver.firstName.toLowerCase().contains(lowerQuery) ||
             driver.lastName.toLowerCase().contains(lowerQuery) ||
             driver.fullName.toLowerCase().contains(lowerQuery) ||
             driver.employeeId.toLowerCase().contains(lowerQuery) ||
             driver.cnic.contains(query) ||
             driver.phoneNumber.contains(query) ||
             driver.licenseNumber.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Driver> filterByStatus(DriverStatus status) {
    return state.drivers.where((driver) => driver.status == status).toList();
  }

  List<Driver> filterByCategory(DriverCategory category) {
    return state.drivers.where((driver) => driver.category == category).toList();
  }

  List<Driver> getDriversWithExpiredLicenses() {
    return state.drivers.where((driver) => driver.isLicenseExpired).toList();
  }

  List<Driver> getDriversWithExpiringSoonLicenses() {
    return state.drivers.where((driver) => driver.isLicenseExpiringSoon && !driver.isLicenseExpired).toList();
  }

  List<Driver> getUnassignedDrivers() {
    return state.drivers.where((driver) => !driver.hasVehicleAssigned && driver.status == DriverStatus.active).toList();
  }

  // Statistics
  int get totalDrivers => state.drivers.length;
  int get activeDrivers => state.drivers.where((d) => d.status == DriverStatus.active).length;
  int get inactiveDrivers => state.drivers.where((d) => d.status == DriverStatus.inactive).length;
  int get suspendedDrivers => state.drivers.where((d) => d.status == DriverStatus.suspended).length;
  int get driversOnLeave => state.drivers.where((d) => d.status == DriverStatus.onLeave).length;
  int get expiredLicenses => getDriversWithExpiredLicenses().length;
  int get expiringSoonLicenses => getDriversWithExpiringSoonLicenses().length;

  double get averageAge {
    if (state.drivers.isEmpty) return 0;
    final totalAge = state.drivers.map((d) => d.ageInYears).reduce((a, b) => a + b);
    return totalAge / state.drivers.length;
  }

  double get averageExperience {
    if (state.drivers.isEmpty) return 0;
    final totalExp = state.drivers.map((d) => d.experienceInYears).reduce((a, b) => a + b);
    return totalExp / state.drivers.length;
  }

}

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier();
});

// Computed providers for filtered data
final activeDriversProvider = Provider<List<Driver>>((ref) {
  final driverState = ref.watch(driverProvider);
  return driverState.drivers.where((d) => d.status == DriverStatus.active).toList();
});

final driversWithExpiredLicensesProvider = Provider<List<Driver>>((ref) {
  final driverState = ref.watch(driverProvider);
  return driverState.drivers.where((d) => d.isLicenseExpired).toList();
});

final driversWithExpiringSoonLicensesProvider = Provider<List<Driver>>((ref) {
  final driverState = ref.watch(driverProvider);
  return driverState.drivers.where((d) => d.isLicenseExpiringSoon && !d.isLicenseExpired).toList();
});

final driverStatsProvider = Provider<Map<String, int>>((ref) {
  final driverState = ref.watch(driverProvider);
  return {
    'total': driverState.drivers.length,
    'active': driverState.drivers.where((d) => d.status == DriverStatus.active).length,
    'inactive': driverState.drivers.where((d) => d.status == DriverStatus.inactive).length,
    'suspended': driverState.drivers.where((d) => d.status == DriverStatus.suspended).length,
    'onLeave': driverState.drivers.where((d) => d.status == DriverStatus.onLeave).length,
    'expired_licenses': driverState.drivers.where((d) => d.isLicenseExpired).length,
    'expiring_soon': driverState.drivers.where((d) => d.isLicenseExpiringSoon && !d.isLicenseExpired).length,
  };
});