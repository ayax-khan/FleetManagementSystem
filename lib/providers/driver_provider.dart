import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/driver.dart';
import '../utils/debug_utils.dart';

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
    DebugUtils.log('Loading drivers', 'DRIVER');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulate API call - replace with actual API call later
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data for now
      final mockDrivers = _generateMockDrivers();

      state = state.copyWith(
        drivers: mockDrivers,
        isLoading: false,
      );

      DebugUtils.log('Loaded ${mockDrivers.length} drivers', 'DRIVER');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load drivers: $e',
      );
      DebugUtils.logError('Failed to load drivers', e);
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      // Generate new ID and timestamps
      final newDriver = driver.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to list
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      // Update timestamps
      final updatedDriver = driver.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in list
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove from list
      final updatedDrivers = state.drivers.where((d) => d.id != driverId).toList();
      
      state = state.copyWith(
        drivers: updatedDrivers,
        isLoading: false,
        clearSelected: state.selectedDriver?.id == driverId,
      );

      DebugUtils.log('Driver deleted successfully: $driverId', 'DRIVER');
      return true;
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

  // Mock data generator
  List<Driver> _generateMockDrivers() {
    final now = DateTime.now();
    return [
      Driver(
        id: '1',
        firstName: 'Ahmed',
        lastName: 'Ali',
        employeeId: 'EMP001',
        cnic: '12345-6789012-3',
        phoneNumber: '+92-300-1234567',
        email: 'ahmed.ali@company.com',
        address: 'House 123, Street 5, Lahore',
        dateOfBirth: DateTime(1985, 5, 15),
        joiningDate: DateTime(2020, 1, 15),
        status: DriverStatus.active,
        category: DriverCategory.senior,
        licenseNumber: 'LHR-12345678',
        licenseCategory: LicenseCategory.heavyVehicle,
        licenseExpiryDate: DateTime(2025, 12, 31),
        basicSalary: 45000.0,
        vehicleAssigned: '1', // Toyota Camry
        emergencyContactName: 'Fatima Ali',
        emergencyContactNumber: '+92-300-9876543',
        notes: 'Experienced driver with clean record',
        createdAt: now.subtract(const Duration(days: 800)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Driver(
        id: '2',
        firstName: 'Muhammad',
        lastName: 'Hassan',
        employeeId: 'EMP002',
        cnic: '54321-9876543-2',
        phoneNumber: '+92-301-2345678',
        email: 'hassan@company.com',
        address: 'Flat 45, Block B, Karachi',
        dateOfBirth: DateTime(1990, 8, 20),
        joiningDate: DateTime(2021, 6, 1),
        status: DriverStatus.active,
        category: DriverCategory.regular,
        licenseNumber: 'KHI-87654321',
        licenseCategory: LicenseCategory.lightVehicle,
        licenseExpiryDate: DateTime(2024, 11, 15), // Expiring soon
        basicSalary: 35000.0,
        vehicleAssigned: '2', // Ford F-150
        emergencyContactName: 'Sarah Hassan',
        emergencyContactNumber: '+92-301-1111111',
        notes: 'Good performance, punctual',
        createdAt: now.subtract(const Duration(days: 600)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Driver(
        id: '3',
        firstName: 'Usman',
        lastName: 'Khan',
        employeeId: 'EMP003',
        cnic: '11111-2222222-3',
        phoneNumber: '+92-302-3456789',
        address: 'Village Chak 123, Faisalabad',
        dateOfBirth: DateTime(1995, 12, 10),
        joiningDate: DateTime(2023, 3, 15),
        status: DriverStatus.onLeave,
        category: DriverCategory.trainee,
        licenseNumber: 'FSD-11223344',
        licenseCategory: LicenseCategory.motorcycle,
        licenseExpiryDate: DateTime(2026, 3, 20),
        basicSalary: 25000.0,
        emergencyContactName: 'Ali Khan',
        emergencyContactNumber: '+92-302-4444444',
        notes: 'On medical leave for 2 weeks',
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Driver(
        id: '4',
        firstName: 'Zainab',
        lastName: 'Sheikh',
        employeeId: 'EMP004',
        cnic: '33333-4444444-5',
        phoneNumber: '+92-303-4567890',
        email: 'zainab.sheikh@company.com',
        address: 'House 67, Model Town, Islamabad',
        dateOfBirth: DateTime(1988, 3, 25),
        joiningDate: DateTime(2019, 9, 10),
        status: DriverStatus.active,
        category: DriverCategory.senior,
        licenseNumber: 'ISB-55667788',
        licenseCategory: LicenseCategory.publicServiceVehicle,
        licenseExpiryDate: DateTime(2023, 8, 1), // Expired
        basicSalary: 50000.0,
        emergencyContactName: 'Omar Sheikh',
        emergencyContactNumber: '+92-303-7777777',
        notes: 'Female driver, specializes in passenger transport. License renewal required.',
        createdAt: now.subtract(const Duration(days: 1200)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
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