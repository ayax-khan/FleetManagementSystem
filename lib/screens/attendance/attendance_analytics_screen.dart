import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/driver.dart';
import '../../models/attendance.dart';
import '../../providers/driver_provider.dart';
import '../../providers/attendance_provider.dart';

class AttendanceAnalyticsScreen extends ConsumerStatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  ConsumerState<AttendanceAnalyticsScreen> createState() => _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends ConsumerState<AttendanceAnalyticsScreen> {
  DriverCategory? _selectedCategory;
  Map<String, Map<int, AttendanceStatus?>> _weeklyAttendance = {};
  List<Driver> _filteredDrivers = [];
  Map<String, bool> _isEditing = {};
  
  final List<DriverCategory> _availableCategories = [
    DriverCategory.transportOfficial,
    DriverCategory.generalDrivers,
    DriverCategory.shiftDrivers,
    DriverCategory.entitledDrivers,
  ];

  @override
  void initState() {
    super.initState();
    _initializeWeeklyAttendance();
  }

  void _initializeWeeklyAttendance() {
    // Initialize empty attendance for the week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // Get 7 days starting from Monday
    for (int i = 0; i < 7; i++) {
      // Will be filled when drivers are selected
    }
  }

  void _filterDriversByCategory(DriverCategory? category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == null) {
        _filteredDrivers = [];
        _weeklyAttendance = {};
        return;
      }
      
      final allDrivers = ref.read(driverProvider).drivers;
      _filteredDrivers = allDrivers.where((driver) => 
        driver.category == category && 
        driver.status == DriverStatus.active
      ).toList();
      
      _initializeWeeklyAttendanceForDrivers();
    });
  }

  void _initializeWeeklyAttendanceForDrivers() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    _weeklyAttendance = {};
    _isEditing = {};
    
    for (final driver in _filteredDrivers) {
      _weeklyAttendance[driver.id] = {};
      _isEditing[driver.id] = false;
      
      // Initialize with null (no attendance marked)
      for (int i = 0; i < 7; i++) {
        _weeklyAttendance[driver.id]![i] = null;
      }
    }
  }

  void _updateAttendance(String driverId, int dayIndex, AttendanceStatus? status) {
    if (!(_isEditing[driverId] ?? false)) return;
    
    setState(() {
      _weeklyAttendance[driverId]![dayIndex] = status;
    });
  }

  void _saveWeeklyAttendance(String driverId) {
    setState(() {
      _isEditing[driverId] = false;
    });
    
    // Here you would typically save to the backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance saved for ${_filteredDrivers.firstWhere((d) => d.id == driverId).fullName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildWeeklyAttendanceTable() {
    if (_selectedCategory == null || _filteredDrivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a driver category to view attendance',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(
            label: Text('Driver', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...weekDays.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final dayName = entry.value;
            final date = startOfWeek.add(Duration(days: dayIndex));
            
            return DataColumn(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
          const DataColumn(
            label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: _filteredDrivers.map((driver) {
          final isEditing = _isEditing[driver.id] ?? false;
          
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      driver.employeeId,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ...List.generate(7, (dayIndex) {
                final status = _weeklyAttendance[driver.id]?[dayIndex];
                
                return DataCell(
                  isEditing
                      ? _buildAttendanceDropdown(driver.id, dayIndex, status)
                      : _buildAttendanceDisplay(status),
                );
              }),
              DataCell(
                isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.save, color: Colors.green),
                            onPressed: () => _saveWeeklyAttendance(driver.id),
                            tooltip: 'Save',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _isEditing[driver.id] = false;
                                _initializeWeeklyAttendanceForDrivers();
                              });
                            },
                            tooltip: 'Cancel',
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _isEditing[driver.id] = true;
                          });
                        },
                        tooltip: 'Edit Attendance',
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceDropdown(String driverId, int dayIndex, AttendanceStatus? currentStatus) {
    return DropdownButton<AttendanceStatus?>(
      value: currentStatus,
      hint: const Text('-'),
      isDense: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('-'),
        ),
        ...AttendanceStatus.values.map((status) => DropdownMenuItem(
          value: status,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status.icon),
              const SizedBox(width: 4),
              Text(status.displayName),
            ],
          ),
        )),
      ],
      onChanged: (status) => _updateAttendance(driverId, dayIndex, status),
    );
  }

  Widget _buildAttendanceDisplay(AttendanceStatus? status) {
    if (status == null) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Driver Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<DriverCategory?>(
                    value: _selectedCategory,
                    hint: const Text('Choose a category...'),
                    isExpanded: true,
                    underline: Container(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('-- Select Category --'),
                      ),
                      ..._availableCategories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 8),
                            Text(category.displayName),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                '${ref.watch(driverProvider).drivers.where((d) => d.category == category && d.status == DriverStatus.active).length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: category.color.withOpacity(0.2),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      )),
                    ],
                    onChanged: _filterDriversByCategory,
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredDrivers.length} drivers found in ${_selectedCategory!.displayName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Weekly Attendance Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_view_week, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          const Text(
                            'Weekly Attendance Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const Spacer(),
                          if (_selectedCategory != null) ...[
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text(
                              'Click edit to mark attendance',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildWeeklyAttendanceTable(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}