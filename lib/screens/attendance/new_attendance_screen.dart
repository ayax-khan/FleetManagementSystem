import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../models/driver.dart';
import '../../providers/driver_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/excel_export_service.dart';
import 'today_attendance_dialog.dart';
import 'attendance_overview_screen.dart';

class NewAttendanceScreen extends ConsumerStatefulWidget {
  const NewAttendanceScreen({super.key});

  @override
  ConsumerState<NewAttendanceScreen> createState() => _NewAttendanceScreenState();
}

class _NewAttendanceScreenState extends ConsumerState<NewAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _selectedEndDate = DateTime.now();
  bool _showDateFilter = false;
  AttendanceStatus? _filterByStatus;

  @override
  void initState() {
    super.initState();
    // Force load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProvider.notifier).loadDrivers();
      ref.read(attendanceProvider.notifier).loadAttendances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceOverviewScreen(),
                ),
              );
            },
            tooltip: '30-Day Overview',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportAttendanceData,
            tooltip: 'Export Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _refreshData();
                  break;
                case 'settings':
                  _showAttendanceSettings();
                  break;
                case 'reports':
                  _showReportsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.assessment),
                    SizedBox(width: 8),
                    Text('Reports'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by driver name, employee ID...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                          IconButton(
                            icon: Icon(
                              _showDateFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                              color: _showDateFilter ? const Color(0xFF1565C0) : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _showDateFilter = !_showDateFilter;
                              });
                            },
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Filter Options (expandable)
                if (_showDateFilter) ...[
                  const SizedBox(height: 12),
                  _buildFilterSection(),
                ],
              ],
            ),
          ),

          // Main Content - Attendance Table
          Expanded(
            child: _buildWeeklyAttendanceTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTodayAttendanceDialog,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.today),
        label: const Text('Today Attendance'),
      ),
    );
  }

  Widget _buildWeeklyAttendanceTable() {
    final driverState = ref.watch(driverProvider);
    final attendanceState = ref.watch(attendanceProvider);
    
    if (driverState.isLoading || attendanceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driverState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error loading drivers: ${driverState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(driverProvider.notifier).loadDrivers(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter drivers by search query and active status
    List<Driver> filteredDrivers = driverState.drivers
        .where((driver) => driver.status == DriverStatus.active)
        .where((driver) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return driver.fullName.toLowerCase().contains(query) ||
             driver.employeeId.toLowerCase().contains(query);
    }).toList();

    if (filteredDrivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group drivers by category
    Map<DriverCategory, List<Driver>> driversByCategory = {};
    for (final driver in filteredDrivers) {
      driversByCategory.putIfAbsent(driver.category, () => []).add(driver);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            _buildTableHeader(),
            const SizedBox(height: 16),
            
            // Driver Categories and Rows
            ...driversByCategory.entries.map((entry) => 
              _buildCategorySection(
                entry.key, 
                entry.value, 
                attendanceState.attendances,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Name Column
            const Expanded(
              flex: 3,
              child: Text(
                'Employee Name',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            // Weekday Columns
            ...weekDays.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final dayName = entry.value;
              final date = startOfWeek.add(Duration(days: dayIndex));
              
              return Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    DriverCategory category, 
    List<Driver> drivers, 
    List<Attendance> attendances,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(
                color: Color(0xFF1565C0),
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: const Color(0xFF1565C0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${category.displayName} (${drivers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
        
        // Driver Rows
        ...drivers.map((driver) => _buildDriverRow(driver, attendances)),
      ],
    );
  }

  Widget _buildDriverRow(Driver driver, List<Attendance> attendances) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Name Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${driver.employeeId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Weekday Status Columns
            ...List.generate(7, (dayIndex) {
              final date = startOfWeek.add(Duration(days: dayIndex));
              final dayAttendance = attendances.firstWhere(
                (att) => att.driverId == driver.id && 
                         att.date.year == date.year &&
                         att.date.month == date.month &&
                         att.date.day == date.day,
                orElse: () => Attendance(
                  id: '',
                  driverId: '',
                  driverName: '',
                  driverEmployeeId: '',
                  date: date,
                  status: AttendanceStatus.absent,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              
              return Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.center,
                  child: _buildAttendanceStatusIndicator(dayAttendance),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusIndicator(Attendance attendance) {
    if (attendance.id.isEmpty) {
      // No attendance record
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: const Text(
          '-',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Show status indicator
    String statusText = 'A'; // Default Absent
    Color statusColor = Colors.red;
    
    switch (attendance.status) {
      case AttendanceStatus.present:
        statusText = 'P';
        statusColor = Colors.green;
        break;
      case AttendanceStatus.absent:
        statusText = 'A';
        statusColor = Colors.red;
        break;
      case AttendanceStatus.late:
        statusText = 'L';
        statusColor = Colors.orange;
        break;
      case AttendanceStatus.leave:
        statusText = 'LV';
        statusColor = Colors.blue;
        break;
      case AttendanceStatus.halfDay:
        statusText = 'HD';
        statusColor = Colors.amber;
        break;
      case AttendanceStatus.sick:
        statusText = 'S';
        statusColor = Colors.purple;
        break;
      default:
        statusText = 'A';
        statusColor = Colors.red;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(DriverCategory category) {
    switch (category) {
      case DriverCategory.transportOfficial:
        return Icons.admin_panel_settings;
      case DriverCategory.generalDrivers:
        return Icons.local_shipping;
      case DriverCategory.shiftDrivers:
        return Icons.schedule;
      case DriverCategory.entitledDrivers:
        return Icons.star;
      case DriverCategory.regular:
        return Icons.person;
      case DriverCategory.trainee:
        return Icons.school;
      case DriverCategory.contractor:
        return Icons.business;
      case DriverCategory.partTime:
        return Icons.access_time;
    }
  }

  void _showTodayAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => const TodayAttendanceDialog(),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Options',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          // Date Range Picker
          Row(
            children: [
              Expanded(
                child: _buildDateRangePicker(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status Filter
          Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: 8),
              DropdownButton<AttendanceStatus?>(
                value: _filterByStatus,
                hint: const Text('All Statuses'),
                items: [
                  const DropdownMenuItem<AttendanceStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...AttendanceStatus.values.map(
                    (status) => DropdownMenuItem<AttendanceStatus>(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterByStatus = value;
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDateRange(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(' to '),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDateRange(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action Methods
  Future<void> _selectDateRange(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = date;
          if (_selectedEndDate.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = date;
          if (_selectedStartDate.isAfter(_selectedEndDate)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
      });
    }
  }

  void _applyFilters() {
    // Apply date range and status filters to attendance data
    ref.read(attendanceProvider.notifier).loadAttendancesForDateRange(
      _selectedStartDate,
      _selectedEndDate,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters applied successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStartDate = DateTime.now().subtract(const Duration(days: 6));
      _selectedEndDate = DateTime.now();
      _filterByStatus = null;
      _searchQuery = '';
      _searchController.clear();
    });
    
    ref.read(attendanceProvider.notifier).loadAttendances();
  }

  void _refreshData() {
    ref.read(driverProvider.notifier).loadDrivers();
    ref.read(attendanceProvider.notifier).loadAttendances();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _exportAttendanceData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );
      
      // Get current data
      final attendanceState = ref.read(attendanceProvider);
      final driverState = ref.read(driverProvider);
      
      // Export using Excel service
      final excelService = ExcelExportService();
      final filePath = await excelService.exportAttendanceData(
        attendances: attendanceState.attendances,
        drivers: driverState.drivers,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance data exported successfully!\nFile: ${filePath.split('/').last}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implement file sharing
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export failed - unable to create file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttendanceSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Settings'),
        content: const SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Work Hours'),
                subtitle: Text('8:00 AM - 5:00 PM'),
              ),
              ListTile(
                leading: Icon(Icons.timer),
                title: Text('Late Arrival Time'),
                subtitle: Text('After 9:00 AM'),
              ),
              ListTile(
                leading: Icon(Icons.calculate),
                title: Text('Overtime Calculation'),
                subtitle: Text('After 8 hours'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement settings save
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: SizedBox(
          width: 300,
          height: 250,
          child: Column(
            children: [
              const Text('Select report type:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Monthly Report'),
                subtitle: const Text('Detailed monthly attendance'),
                onTap: () => _generateReport('monthly'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Driver Report'),
                subtitle: const Text('Individual driver summary'),
                onTap: () => _generateReport('driver'),
              ),
              ListTile(
                leading: const Icon(Icons.timeline),
                title: const Text('Trend Analysis'),
                subtitle: const Text('Attendance trends over time'),
                onTap: () => _generateReport('trend'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _generateReport(String reportType) {
    Navigator.pop(context);
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Generating $reportType report...'),
          ],
        ),
      ),
    );
    
    // Simulate report generation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reportType report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}