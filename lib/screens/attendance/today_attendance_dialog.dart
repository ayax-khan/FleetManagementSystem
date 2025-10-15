import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../models/driver.dart';
import '../../providers/driver_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/debug_utils.dart';
import '../../services/location_service.dart';
import 'widgets/photo_capture_dialog.dart';

class TodayAttendanceDialog extends ConsumerStatefulWidget {
  const TodayAttendanceDialog({super.key});

  @override
  ConsumerState<TodayAttendanceDialog> createState() => _TodayAttendanceDialogState();
}

class _TodayAttendanceDialogState extends ConsumerState<TodayAttendanceDialog> {
  final Map<String, AttendanceStatus> _attendanceSelections = {};
  final Map<String, bool> _driverVisibility = {}; // Track which drivers to show
  final Map<String, String> _capturedPhotos = {}; // Store photo paths
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _enableLocationVerification = true;
  bool _enablePhotoCapture = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadTodayAttendanceData();
  }

  Future<void> _initializeServices() async {
    await _locationService.initialize();
  }

  void _loadTodayAttendanceData() {
    setState(() => _isLoading = true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Ensure drivers and attendance data is loaded
        await ref.read(driverProvider.notifier).loadDrivers();
        await ref.read(attendanceProvider.notifier).loadAttendances();
        
        final drivers = ref.read(driverProvider).drivers
            .where((d) => d.status == DriverStatus.active)
            .toList();
        
        final todayAttendances = ref.read(attendanceProvider).attendances
            .where((a) => _isSameDay(a.date, _selectedDate))
            .toList();
        
        setState(() {
          // Initialize attendance selections
          _attendanceSelections.clear();
          _driverVisibility.clear();
          
          for (final driver in drivers) {
            // Check if driver already has attendance for today
            final existingAttendance = todayAttendances
                .where((a) => a.driverId == driver.id)
                .isNotEmpty
                    ? todayAttendances.where((a) => a.driverId == driver.id).first
                    : null;
            
            if (existingAttendance != null) {
              _attendanceSelections[driver.id] = existingAttendance.status;
              _driverVisibility[driver.id] = false; // Hide drivers who already have attendance
            } else {
              _driverVisibility[driver.id] = true; // Show drivers who don't have attendance
            }
          }
          
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        DebugUtils.logError('Failed to load attendance data', e);
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(child: _buildAttendanceTable()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getFormattedDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _getCurrentTimeStatus(),
            style: TextStyle(
              color: _isLateTime() ? Colors.orange.shade200 : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final driverState = ref.watch(driverProvider);
    
    if (driverState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleDrivers = driverState.drivers
        .where((d) => d.status == DriverStatus.active)
        .where((d) => _driverVisibility[d.id] == true)
        .toList();

    if (visibleDrivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'All drivers have been marked',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Attendance for today has been completed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text(
                  'Sr',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Days (Mon - Sun)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Driver Rows
          ...visibleDrivers.asMap().entries.map((entry) {
            final index = entry.key;
            final driver = entry.value;
            return _buildDriverAttendanceRow(index + 1, driver);
          }),
        ],
      ),
    );
  }

  Widget _buildDriverAttendanceRow(int srNo, Driver driver) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Serial Number
          SizedBox(
            width: 30,
            child: Text(
              '$srNo',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Driver Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  driver.employeeId,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Week Days with Checkboxes
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final dayLabel = entry.value;
                final date = startOfWeek.add(Duration(days: dayIndex));
                final isToday = _isSameDay(date, _selectedDate);
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.green : Colors.grey,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isToday)
                      _buildTodayCheckbox(driver)
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCheckbox(Driver driver) {
    final currentSelection = _attendanceSelections[driver.id];
    final isPresent = currentSelection == AttendanceStatus.present;
    final isLate = currentSelection == AttendanceStatus.late;
    
    return GestureDetector(
      onTap: () => _toggleAttendance(driver),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPresent || isLate 
              ? (isLate ? Colors.orange : Colors.green)
              : Colors.white,
          border: Border.all(
            color: isPresent || isLate 
                ? (isLate ? Colors.orange : Colors.green)
                : Colors.grey,
            width: 2,
          ),
        ),
        child: isPresent || isLate
            ? Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Future<void> _toggleAttendance(Driver driver) async {
    final current = _attendanceSelections[driver.id];
    
    if (current == AttendanceStatus.present || current == AttendanceStatus.late) {
      // Remove attendance
      setState(() {
        _attendanceSelections.remove(driver.id);
        _capturedPhotos.remove(driver.id);
      });
      return;
    }
    
    // Verify location if enabled
    if (_enableLocationVerification) {
      final locationResult = await _locationService.verifyAttendanceLocation();
      if (!locationResult.isValid) {
        if (mounted) {
          _showLocationVerificationDialog(locationResult.message);
        }
        return;
      }
    }
    
    // Capture photo if enabled
    if (_enablePhotoCapture) {
      await _showPhotoCapture(driver);
    } else {
      _markAttendance(driver);
    }
  }
  
  void _markAttendance(Driver driver) {
    setState(() {
      // Determine if it's late based on current time
      final now = DateTime.now();
      final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 0);
      
      _attendanceSelections[driver.id] = isLate 
          ? AttendanceStatus.late 
          : AttendanceStatus.present;
    });
  }

  Widget _buildActionButtons() {
    final hasSelections = _attendanceSelections.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Status Text
          Expanded(
            child: Text(
              hasSelections 
                  ? '${_attendanceSelections.length} drivers marked'
                  : 'No attendance marked',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          
          // Cancel Button
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          
          const SizedBox(width: 12),
          
          // Save Button
          ElevatedButton(
            onPressed: _isSaving || !hasSelections ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Attendance'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_attendanceSelections.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    try {
      final driverState = ref.read(driverProvider);
      final attendanceNotifier = ref.read(attendanceProvider.notifier);
      
      int savedCount = 0;
      int failedCount = 0;
      
      for (final entry in _attendanceSelections.entries) {
        final driverId = entry.key;
        final status = entry.value;
        
        final driver = driverState.drivers.firstWhere((d) => d.id == driverId);
        
        // Create attendance record
        final attendance = Attendance(
          id: '', // Will be generated by backend
          driverId: driverId,
          driverName: driver.fullName,
          driverEmployeeId: driver.employeeId,
          date: _selectedDate,
          checkInTime: status == AttendanceStatus.present || status == AttendanceStatus.late
              ? DateTime.now()
              : null,
          status: status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        try {
          await attendanceNotifier.recordAttendance(attendance);
          savedCount++;
        } catch (e) {
          failedCount++;
          DebugUtils.logError('Failed to save attendance for driver ${driver.fullName}', e);
        }
      }
      
      if (mounted) {
        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedCount > 0 
                  ? 'Successfully saved attendance for $savedCount drivers'
                      '${failedCount > 0 ? ' ($failedCount failed)' : ''}'
                  : 'Failed to save attendance records',
            ),
            backgroundColor: savedCount > 0 ? Colors.green : Colors.red,
          ),
        );
        
        if (savedCount > 0) {
          // Store the IDs of drivers whose attendance was just saved
          final savedDriverIds = _attendanceSelections.keys.toList();
          
          // Clear the current selections since they've been saved
          setState(() {
            _attendanceSelections.clear();
            
            // Hide drivers who now have attendance recorded
            for (final driverId in savedDriverIds) {
              _driverVisibility[driverId] = false;
            }
          });
          
          // Force a full reload of attendance data
          await ref.read(attendanceProvider.notifier).loadAttendances();
          
          // Reload dialog data to reflect the changes
          _loadTodayAttendanceData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      DebugUtils.logError('Error saving attendance', e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
      _loadTodayAttendanceData();
    }
  }

  String _getFormattedDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  String _getCurrentTimeStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 8) {
      return 'Early (${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
    } else if (hour == 8 || (hour == 9 && now.minute == 0)) {
      return 'On Time (${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
    } else {
      return 'Late (${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
    }
  }

  bool _isLateTime() {
    final now = DateTime.now();
    return now.hour > 9 || (now.hour == 9 && now.minute > 0);
  }
  
  Future<void> _showPhotoCapture(Driver driver) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhotoCaptureDialog(
        driverName: driver.fullName,
        attendanceType: 'check_in',
        onPhotoCapture: (photoPath) {
          setState(() {
            _capturedPhotos[driver.id] = photoPath;
          });
          _markAttendance(driver);
        },
      ),
    );
  }
  
  void _showLocationVerificationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Verification Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'You must be within the office area to mark attendance.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: !_enableLocationVerification,
                  onChanged: (value) {
                    setState(() {
                      _enableLocationVerification = !value;
                    });
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Override location verification (for testing)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _locationService.openLocationSettings();
              if (!result && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enable location services manually'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
