import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../models/driver.dart';
import '../../providers/driver_provider.dart';
import '../../providers/attendance_provider.dart';

class AttendanceOverviewScreen extends ConsumerStatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  ConsumerState<AttendanceOverviewScreen> createState() => _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends ConsumerState<AttendanceOverviewScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
          '30-Day Attendance Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchSection(),
          Expanded(child: _build30DayAttendanceTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDateRangeText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete attendance overview for all drivers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onTap: _selectMonth,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Change Month',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final attendanceState = ref.watch(attendanceProvider);
    final driverState = ref.watch(driverProvider);
    
    final activeDrivers = driverState.drivers
        .where((d) => d.status == DriverStatus.active)
        .length;
    
    final last30Days = attendanceState.attendances.where((a) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      return a.date.isAfter(thirtyDaysAgo) && a.date.isBefore(now.add(const Duration(days: 1)));
    }).toList();
    
    final presentCount = last30Days.where((a) => a.status == AttendanceStatus.present).length;
    final totalRecords = last30Days.length;
    final avgAttendance = totalRecords > 0 ? (presentCount / totalRecords * 100) : 0.0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Drivers', activeDrivers.toString(), Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Total Records', totalRecords.toString(), Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Avg. Attendance', '${avgAttendance.toStringAsFixed(1)}%', Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search drivers by name or employee ID...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _build30DayAttendanceTable() {
    final driverState = ref.watch(driverProvider);
    final attendanceState = ref.watch(attendanceProvider);

    if (driverState.isLoading || attendanceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTableHeader(),
            const SizedBox(height: 12),
            ...filteredDrivers.asMap().entries.map((entry) {
              final index = entry.key;
              final driver = entry.value;
              return _buildDriverRow(index + 1, driver, attendanceState.attendances);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    // Get the last 30 days
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 29; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header row with driver info and date labels
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Driver info section (fixed width)
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Driver Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                // Days section (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: days.map((date) => 
                        SizedBox(
                          width: 35,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Month labels
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 200), // Match driver info width
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: days.map((date) => 
                        SizedBox(
                          width: 35,
                          child: Text(
                            _getMonthLabel(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(int srNo, Driver driver, List<Attendance> attendances) {
    // Get the last 30 days
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 29; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    // Get attendance for this driver
    final driverAttendances = attendances
        .where((a) => a.driverId == driver.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Driver info section (fixed width)
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: driver.category.color,
                    child: Text(
                      driver.fullName.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          driver.employeeId,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Days section (scrollable)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: days.map((date) {
                    final dayAttendance = driverAttendances.firstWhere(
                      (a) => _isSameDay(a.date, date),
                      orElse: () => Attendance(
                        id: '',
                        driverId: driver.id,
                        driverName: driver.fullName,
                        driverEmployeeId: driver.employeeId,
                        date: date,
                        status: AttendanceStatus.absent,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    
                    return Container(
                      width: 35,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Center(
                        child: _buildAttendanceIndicator(dayAttendance.status),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceIndicator(AttendanceStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusText = 'P';
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusText = 'A';
        break;
      case AttendanceStatus.late:
        statusColor = Colors.orange;
        statusText = 'L';
        break;
      case AttendanceStatus.leave:
        statusColor = Colors.blue;
        statusText = 'LV';
        break;
      case AttendanceStatus.halfDay:
        statusColor = Colors.purple;
        statusText = 'H';
        break;
      case AttendanceStatus.sick:
        statusColor = Colors.pink;
        statusText = 'S';
        break;
      case AttendanceStatus.overtime:
        statusColor = Colors.indigo;
        statusText = 'O';
        break;
    }

    return Container(
      width: 24,
      height: 24,
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
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return '${thirtyDaysAgo.day}/${thirtyDaysAgo.month}/${thirtyDaysAgo.year} - ${now.day}/${now.month}/${now.year}';
  }

  String _getMonthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _selectMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting 30-day attendance data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}