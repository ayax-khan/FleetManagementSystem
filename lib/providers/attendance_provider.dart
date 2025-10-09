import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import '../models/driver.dart';
import '../services/api_service.dart';
import '../utils/debug_utils.dart';
import 'driver_provider.dart';

// Attendance State
class AttendanceState {
  final List<Attendance> attendances;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;
  final AttendanceFilter filter;

  const AttendanceState({
    this.attendances = const [],
    this.isLoading = false,
    this.error,
    required this.selectedDate,
    this.filter = const AttendanceFilter(),
  });

  AttendanceState copyWith({
    List<Attendance>? attendances,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    AttendanceFilter? filter,
  }) {
    return AttendanceState(
      attendances: attendances ?? this.attendances,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedDate: selectedDate ?? this.selectedDate,
      filter: filter ?? this.filter,
    );
  }
}

// Attendance Notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final ApiService _apiService;
  final Ref _ref;

  AttendanceNotifier(this._apiService, this._ref) 
      : super(AttendanceState(selectedDate: DateTime.now())) {
    loadAttendances();
  }

  // Load all attendances
  Future<void> loadAttendances() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      DebugUtils.log('Loading attendances', 'ATTENDANCE');
      
      // Mock data for now - replace with API call later
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockAttendances = _generateMockAttendances();
      
      state = state.copyWith(
        attendances: mockAttendances,
        isLoading: false,
      );
      
      DebugUtils.log('Loaded ${mockAttendances.length} attendance records', 'ATTENDANCE');
    } catch (e) {
      DebugUtils.logError('Error loading attendances', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendances: $e',
      );
    }
  }

  // Load attendances for a specific date range
  Future<void> loadAttendancesForDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      DebugUtils.log('Loading attendances for date range: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}', 'ATTENDANCE');
      
      // Mock filtering for now
      await Future.delayed(const Duration(milliseconds: 300));
      
      final allAttendances = _generateMockAttendances();
      final filteredAttendances = allAttendances.where((attendance) {
        return attendance.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               attendance.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      state = state.copyWith(
        attendances: filteredAttendances,
        isLoading: false,
        filter: state.filter.copyWith(startDate: startDate, endDate: endDate),
      );
      
      DebugUtils.log('Loaded ${filteredAttendances.length} attendance records for date range', 'ATTENDANCE');
    } catch (e) {
      DebugUtils.logError('Error loading attendances for date range', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendances: $e',
      );
    }
  }

  // Check in driver
  Future<bool> checkIn(AttendanceRequest request) async {
    try {
      DebugUtils.log('Checking in driver: ${request.driverId}', 'ATTENDANCE');
      
      // Mock check-in process
      await Future.delayed(const Duration(milliseconds: 300));
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if attendance already exists for today
      final existingIndex = state.attendances.indexWhere(
        (a) => a.driverId == request.driverId && 
               a.date.year == today.year && 
               a.date.month == today.month && 
               a.date.day == today.day
      );
      
      Attendance newAttendance;
      List<Attendance> updatedAttendances;
      
      if (existingIndex >= 0) {
        // Update existing attendance
        final existing = state.attendances[existingIndex];
        newAttendance = existing.copyWith(
          checkInTime: request.timestamp,
          checkInLocation: request.location,
          checkInPhoto: request.photoPath,
          status: request.status ?? AttendanceStatus.present,
          updatedAt: now,
        );
        
        updatedAttendances = List<Attendance>.from(state.attendances);
        updatedAttendances[existingIndex] = newAttendance;
      } else {
        // Create new attendance record
        final driver = _getDriverInfo(request.driverId);
        newAttendance = Attendance(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          driverId: request.driverId,
          driverName: driver['name']!,
          driverEmployeeId: driver['employeeId']!,
          date: today,
          checkInTime: request.timestamp,
          checkInLocation: request.location,
          checkInPhoto: request.photoPath,
          status: request.status ?? AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        );
        
        updatedAttendances = [newAttendance, ...state.attendances];
      }
      
      state = state.copyWith(attendances: updatedAttendances);
      
      DebugUtils.log('Driver checked in successfully: ${request.driverId}', 'ATTENDANCE');
      return true;
    } catch (e) {
      DebugUtils.logError('Error checking in driver', e);
      return false;
    }
  }

  // Check out driver
  Future<bool> checkOut(AttendanceRequest request) async {
    try {
      DebugUtils.log('Checking out driver: ${request.driverId}', 'ATTENDANCE');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Find existing attendance for today
      final existingIndex = state.attendances.indexWhere(
        (a) => a.driverId == request.driverId && 
               a.date.year == today.year && 
               a.date.month == today.month && 
               a.date.day == today.day
      );
      
      if (existingIndex >= 0) {
        final existing = state.attendances[existingIndex];
        final updatedAttendance = existing.copyWith(
          checkOutTime: request.timestamp,
          checkOutLocation: request.location,
          checkOutPhoto: request.photoPath,
          notes: request.notes,
          updatedAt: now,
        );
        
        final updatedAttendances = List<Attendance>.from(state.attendances);
        updatedAttendances[existingIndex] = updatedAttendance;
        
        state = state.copyWith(attendances: updatedAttendances);
        
        DebugUtils.log('Driver checked out successfully: ${request.driverId}', 'ATTENDANCE');
        return true;
      } else {
        DebugUtils.log('No check-in record found for driver: ${request.driverId}', 'ATTENDANCE');
        return false;
      }
    } catch (e) {
      DebugUtils.logError('Error checking out driver', e);
      return false;
    }
  }

  // Add/Update attendance record
  Future<bool> addOrUpdateAttendance(Attendance attendance) async {
    try {
      DebugUtils.log('Adding/updating attendance: ${attendance.id}', 'ATTENDANCE');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final existingIndex = state.attendances.indexWhere((a) => a.id == attendance.id);
      List<Attendance> updatedAttendances;
      
      if (existingIndex >= 0) {
        // Update existing
        updatedAttendances = List<Attendance>.from(state.attendances);
        updatedAttendances[existingIndex] = attendance.copyWith(
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new
        updatedAttendances = [
          attendance.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ...state.attendances
        ];
      }
      
      state = state.copyWith(attendances: updatedAttendances);
      
      DebugUtils.log('Attendance record saved successfully: ${attendance.id}', 'ATTENDANCE');
      return true;
    } catch (e) {
      DebugUtils.logError('Error saving attendance', e);
      return false;
    }
  }

  // Delete attendance record
  Future<bool> deleteAttendance(String attendanceId) async {
    try {
      DebugUtils.log('Deleting attendance: $attendanceId', 'ATTENDANCE');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedAttendances = state.attendances.where((a) => a.id != attendanceId).toList();
      
      state = state.copyWith(attendances: updatedAttendances);
      
      DebugUtils.log('Attendance deleted successfully: $attendanceId', 'ATTENDANCE');
      return true;
    } catch (e) {
      DebugUtils.logError('Error deleting attendance', e);
      return false;
    }
  }

  // Search attendances
  List<Attendance> searchAttendances(String query) {
    if (query.isEmpty) return state.attendances;
    
    final lowercaseQuery = query.toLowerCase();
    return state.attendances.where((attendance) {
      return attendance.driverName.toLowerCase().contains(lowercaseQuery) ||
             attendance.driverEmployeeId.toLowerCase().contains(lowercaseQuery) ||
             attendance.status.displayName.toLowerCase().contains(lowercaseQuery) ||
             attendance.formattedDate.contains(lowercaseQuery) ||
             (attendance.notes?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Filter attendances
  List<Attendance> getFilteredAttendances(AttendanceFilter filter) {
    var filtered = List<Attendance>.from(state.attendances);
    
    if (filter.startDate != null) {
      filtered = filtered.where((a) => a.date.isAfter(filter.startDate!.subtract(const Duration(days: 1)))).toList();
    }
    
    if (filter.endDate != null) {
      filtered = filtered.where((a) => a.date.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
    }
    
    if (filter.driverIds != null && filter.driverIds!.isNotEmpty) {
      filtered = filtered.where((a) => filter.driverIds!.contains(a.driverId)).toList();
    }
    
    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      filtered = filtered.where((a) => filter.statuses!.contains(a.status)).toList();
    }
    
    if (filter.hasOvertime == true) {
      filtered = filtered.where((a) => a.calculatedOvertimeHours > 0).toList();
    }
    
    if (filter.isLateArrival == true) {
      filtered = filtered.where((a) => a.status == AttendanceStatus.late).toList();
    }
    
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      filtered = searchAttendances(filter.searchQuery!);
    }
    
    return filtered;
  }

  // Update selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // Update filter
  void updateFilter(AttendanceFilter filter) {
    state = state.copyWith(filter: filter);
  }

  // Clear filter
  void clearFilter() {
    state = state.copyWith(filter: const AttendanceFilter());
    loadAttendances(); // Reload all data
  }

  // Get driver info helper
  Map<String, String> _getDriverInfo(String driverId) {
    try {
      final drivers = _ref.read(driverProvider).drivers;
      final driver = drivers.firstWhere((d) => d.id == driverId);
      return {
        'name': driver.fullName,
        'employeeId': driver.employeeId,
      };
    } catch (e) {
      return {
        'name': 'Unknown Driver',
        'employeeId': 'UNKNOWN',
      };
    }
  }

  // Generate mock data
  List<Attendance> _generateMockAttendances() {
    final now = DateTime.now();
    final mockAttendances = <Attendance>[];
    
    // Get some drivers for mock data
    final drivers = _ref.read(driverProvider).drivers;
    if (drivers.isEmpty) return mockAttendances;
    
    // Generate attendance for last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.weekday == 7) continue; // Skip Sundays
      
      for (final driver in drivers.take(3)) { // Use first 3 drivers
        final status = _getRandomStatus(i);
        final checkInTime = status == AttendanceStatus.absent || status == AttendanceStatus.leave 
            ? null 
            : DateTime(date.year, date.month, date.day, 8 + (i % 2), 30 + (i * 7) % 30);
        final checkOutTime = checkInTime != null 
            ? checkInTime.add(Duration(hours: 8 + (i % 3), minutes: 15 + (i * 11) % 45))
            : null;
        
        mockAttendances.add(
          Attendance(
            id: '${driver.id}_${date.millisecondsSinceEpoch}',
            driverId: driver.id,
            driverName: driver.fullName,
            driverEmployeeId: driver.employeeId,
            date: DateTime(date.year, date.month, date.day),
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            status: status,
            checkInLocation: checkInTime != null ? 'Office Location' : null,
            checkOutLocation: checkOutTime != null ? 'Office Location' : null,
            notes: i % 5 == 0 ? 'Extra work on project delivery' : null,
            totalEarnings: status == AttendanceStatus.absent ? 0 : 2500 + (i % 4) * 200,
            createdAt: date,
            updatedAt: date,
          ),
        );
      }
    }
    
    return mockAttendances..sort((a, b) => b.date.compareTo(a.date));
  }

  AttendanceStatus _getRandomStatus(int seed) {
    switch (seed % 10) {
      case 0: return AttendanceStatus.absent;
      case 1: return AttendanceStatus.late;
      case 2: return AttendanceStatus.halfDay;
      case 3: return AttendanceStatus.leave;
      case 4: return AttendanceStatus.sick;
      default: return AttendanceStatus.present;
    }
  }
}

// Provider
final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ApiService(), ref);
});

// Computed providers for statistics
final attendanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final attendances = ref.watch(attendanceProvider).attendances;
  
  if (attendances.isEmpty) {
    return {
      'total': 0,
      'present': 0,
      'absent': 0,
      'leave': 0,
      'late': 0,
      'overtime_records': 0,
      'total_hours': 0.0,
      'avg_attendance': 0.0,
    };
  }
  
  final total = attendances.length;
  final present = attendances.where((a) => a.status == AttendanceStatus.present).length;
  final absent = attendances.where((a) => a.status == AttendanceStatus.absent).length;
  final leave = attendances.where((a) => a.status == AttendanceStatus.leave).length;
  final late = attendances.where((a) => a.status == AttendanceStatus.late).length;
  final overtimeRecords = attendances.where((a) => a.calculatedOvertimeHours > 0).length;
  final totalHours = attendances.fold(0.0, (sum, a) => sum + a.totalHours);
  final avgAttendance = total > 0 ? (present / total * 100) : 0.0;
  
  return {
    'total': total,
    'present': present,
    'absent': absent,
    'leave': leave,
    'late': late,
    'overtime_records': overtimeRecords,
    'total_hours': totalHours,
    'avg_attendance': avgAttendance,
  };
});

// Today's attendances
final todayAttendancesProvider = Provider<List<Attendance>>((ref) {
  final attendances = ref.watch(attendanceProvider).attendances;
  final today = DateTime.now();
  
  return attendances.where((attendance) {
    return attendance.date.year == today.year &&
           attendance.date.month == today.month &&
           attendance.date.day == today.day;
  }).toList();
});

// This month's attendances
final thisMonthAttendancesProvider = Provider<List<Attendance>>((ref) {
  final attendances = ref.watch(attendanceProvider).attendances;
  final now = DateTime.now();
  
  return attendances.where((attendance) {
    return attendance.date.year == now.year &&
           attendance.date.month == now.month;
  }).toList();
});

// Attendance summaries by driver
final attendanceSummariesProvider = Provider<List<AttendanceSummary>>((ref) {
  final attendances = ref.watch(attendanceProvider).attendances;
  final now = DateTime.now();
  
  // Group by driver
  final attendanceByDriver = <String, List<Attendance>>{};
  for (final attendance in attendances) {
    if (attendance.date.year == now.year && attendance.date.month == now.month) {
      attendanceByDriver.putIfAbsent(attendance.driverId, () => []).add(attendance);
    }
  }
  
  // Create summaries
  final summaries = <AttendanceSummary>[];
  for (final entry in attendanceByDriver.entries) {
    final driverId = entry.key;
    final driverAttendances = entry.value;
    final driverName = driverAttendances.first.driverName;
    
    summaries.add(AttendanceSummary.fromAttendanceList(
      driverId,
      driverName,
      now.month,
      now.year,
      driverAttendances,
    ));
  }
  
  return summaries..sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
});

// Drivers with no check-in today
final driversNotCheckedInTodayProvider = Provider<List<Driver>>((ref) {
  final drivers = ref.watch(driverProvider).drivers.where((d) => d.status == DriverStatus.active).toList();
  final todayAttendances = ref.watch(todayAttendancesProvider);
  
  final checkedInDriverIds = todayAttendances
      .where((a) => a.isCheckedIn)
      .map((a) => a.driverId)
      .toSet();
  
  return drivers.where((driver) => !checkedInDriverIds.contains(driver.id)).toList();
});

// Drivers currently working (checked in but not checked out)
final driversCurrentlyWorkingProvider = Provider<List<Attendance>>((ref) {
  final todayAttendances = ref.watch(todayAttendancesProvider);
  
  return todayAttendances
      .where((attendance) => attendance.isCheckedIn && !attendance.isCheckedOut)
      .toList();
});