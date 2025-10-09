import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../models/driver.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/driver_provider.dart';
import '../../utils/debug_utils.dart';

class CheckInOutScreen extends ConsumerStatefulWidget {
  const CheckInOutScreen({super.key});

  @override
  ConsumerState<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends ConsumerState<CheckInOutScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDriverId;
  AttendanceAction _selectedAction = AttendanceAction.checkIn;
  AttendanceStatus? _selectedStatus;
  String? _locationInfo;
  String? _photoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider).drivers
        .where((driver) => driver.status == DriverStatus.active)
        .toList();
    final todayAttendances = ref.watch(todayAttendancesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check In/Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1565C0),
                      const Color(0xFF1976D2),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        _selectedAction == AttendanceAction.checkIn 
                            ? Icons.login 
                            : Icons.logout,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedAction.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCurrentDateTime(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Selection
            _buildSectionHeader('Action'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    AttendanceAction.checkIn,
                    Icons.login,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    AttendanceAction.checkOut,
                    Icons.logout,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Driver Selection
            _buildSectionHeader('Select Driver'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Driver',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                value: _selectedDriverId,
                items: drivers.map((driver) {
                  final todayAttendance = todayAttendances
                      .where((a) => a.driverId == driver.id)
                      .firstOrNull;
                  
                  final statusText = todayAttendance?.isCheckedIn == true
                      ? (todayAttendance?.isCheckedOut == true ? 'Completed' : 'Working')
                      : 'Not Checked In';
                      
                  return DropdownMenuItem<String>(
                    value: driver.id,
                    child: Text(
                      '${driver.fullName} (${driver.employeeId}) - $statusText',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDriverId = value;
                    // Auto-select appropriate action based on driver's current status
                    if (value != null) {
                      final todayAttendance = todayAttendances
                          .where((a) => a.driverId == value)
                          .firstOrNull;
                      
                      if (todayAttendance?.isCheckedIn == true && !todayAttendance!.isCheckedOut) {
                        _selectedAction = AttendanceAction.checkOut;
                      } else {
                        _selectedAction = AttendanceAction.checkIn;
                      }
                    }
                  });
                },
              ),
            ),
            
            if (_selectedDriverId != null) ...[
              const SizedBox(height: 16),
              _buildDriverStatusCard(
                drivers.firstWhere((d) => d.id == _selectedDriverId),
                todayAttendances.where((a) => a.driverId == _selectedDriverId).firstOrNull,
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Status Selection (for check-in)
            if (_selectedAction == AttendanceAction.checkIn) ...[
              _buildSectionHeader('Status'),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AttendanceStatus.present,
                  AttendanceStatus.late,
                  AttendanceStatus.halfDay,
                ].map((status) => _buildStatusChip(status)).toList(),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Location Information
            _buildSectionHeader('Location'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _locationInfo != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationInfo ?? 'Getting location...',
                      style: TextStyle(
                        color: _locationInfo != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF1565C0)),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Photo Capture
            _buildSectionHeader('Photo (Optional)'),
            const SizedBox(height: 12),
            
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: _capturePhoto,
                borderRadius: BorderRadius.circular(12),
                child: _photoPath != null
                    ? Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.photo, color: Colors.green, size: 32),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Photo captured', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Tap to retake', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to capture photo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notes
            _buildSectionHeader('Notes (Optional)'),
            const SizedBox(height: 12),
            
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Add notes or comments',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submitAttendance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_selectedAction == AttendanceAction.checkIn ? Icons.login : Icons.logout),
                          const SizedBox(width: 8),
                          Text(
                            _selectedAction.displayName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildActionButton(AttendanceAction action, IconData icon, Color color) {
    final isSelected = _selectedAction == action;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
          // Reset status when switching actions
          if (action == AttendanceAction.checkOut) {
            _selectedStatus = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              action.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStatusCard(Driver driver, Attendance? todayAttendance) {
    final hasCheckedIn = todayAttendance?.isCheckedIn == true;
    final hasCheckedOut = todayAttendance?.isCheckedOut == true;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text('Today\'s Status', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            if (todayAttendance == null) ...[
              _buildStatusItem('Check In', 'Not checked in', Icons.login, Colors.grey),
              _buildStatusItem('Check Out', 'Not checked out', Icons.logout, Colors.grey),
            ] else ...[
              _buildStatusItem(
                'Check In',
                hasCheckedIn ? todayAttendance!.checkInTimeFormatted : 'Not checked in',
                Icons.login,
                hasCheckedIn ? Colors.green : Colors.grey,
              ),
              _buildStatusItem(
                'Check Out',
                hasCheckedOut ? todayAttendance!.checkOutTimeFormatted : 'Not checked out',
                Icons.logout,
                hasCheckedOut ? Colors.red : Colors.grey,
              ),
              if (hasCheckedIn && !hasCheckedOut) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Currently Working',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 80, 
            child: Text(
              label, 
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text('${status.icon} ${status.displayName}'),
      selected: isSelected,
      selectedColor: status.color.withOpacity(0.2),
      checkmarkColor: status.color,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
    );
  }

  Color _getDriverStatusColor(Attendance? attendance) {
    if (attendance == null) return Colors.grey;
    if (attendance.isCheckedIn && !attendance.isCheckedOut) return Colors.green;
    if (attendance.isCheckedOut) return Colors.blue;
    return Colors.grey;
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }

  void _getCurrentLocation() {
    setState(() {
      _locationInfo = null;
    });
    
    // Mock location - replace with actual location service
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _locationInfo = 'Office Building, Floor 3, Room 301';
        });
      }
    });
  }

  void _capturePhoto() {
    // Mock photo capture - replace with actual camera functionality
    setState(() {
      _photoPath = 'mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo captured successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _canSubmit() {
    if (_isLoading || _selectedDriverId == null) return false;
    
    // For check-in, require status selection
    if (_selectedAction == AttendanceAction.checkIn && _selectedStatus == null) {
      return false;
    }
    
    return true;
  }

  Future<void> _submitAttendance() async {
    if (!_canSubmit()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final request = AttendanceRequest(
        driverId: _selectedDriverId!,
        action: _selectedAction,
        timestamp: DateTime.now(),
        location: _locationInfo,
        photoPath: _photoPath,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        status: _selectedStatus,
      );
      
      bool success;
      if (_selectedAction == AttendanceAction.checkIn) {
        success = await ref.read(attendanceProvider.notifier).checkIn(request);
      } else {
        success = await ref.read(attendanceProvider.notifier).checkOut(request);
      }
      
      if (success && mounted) {
        DebugUtils.log('${_selectedAction.displayName} successful for driver $_selectedDriverId', 'CHECK_IN_OUT');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedAction.displayName} successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _selectedDriverId = null;
          _selectedStatus = null;
          _photoPath = null;
          _notesController.clear();
          _selectedAction = AttendanceAction.checkIn;
        });
        
        // Navigate back
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_selectedAction.displayName.toLowerCase()}. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      DebugUtils.logError('Error during ${_selectedAction.displayName}', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}