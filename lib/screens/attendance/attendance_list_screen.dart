import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/driver_provider.dart';
import '../../utils/debug_utils.dart';
import 'attendance_detail_screen.dart';
import 'check_in_out_screen.dart';
import 'attendance_analytics_screen.dart';
import '../../models/driver.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AttendanceStatus>? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedDay = DateTime.now();
    
    // Force reload attendance data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceProvider.notifier).loadAttendances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final attendanceStats = ref.watch(attendanceStatsProvider);
    final todayAttendances = ref.watch(todayAttendancesProvider);
    final thisMonthAttendances = ref.watch(thisMonthAttendancesProvider);
    final driversWorking = ref.watch(driversCurrentlyWorkingProvider);
    
    // Filter attendances based on search and filters
    List<Attendance> filteredAttendances = attendanceState.attendances;
    
    if (_searchQuery.isNotEmpty) {
      filteredAttendances = ref.read(attendanceProvider.notifier).searchAttendances(_searchQuery);
    }
    
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filteredAttendances = filteredAttendances.where((a) => _statusFilter!.contains(a.status)).toList();
    }

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
            icon: Icon(_showCalendar ? Icons.list : Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(attendanceProvider.notifier).loadAttendances();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export_excel':
                  _showComingSoonDialog('Export to Excel');
                  break;
                case 'import_data':
                  _showComingSoonDialog('Import from Excel/Google Sheets');
                  break;
                case 'summary_report':
                  _showSummaryReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_data',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'summary_report',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Color(0xFFFF9800)),
                    SizedBox(width: 8),
                    Text('Summary Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'All (${attendanceStats['total']})',
              icon: const Icon(Icons.list_alt, size: 16),
            ),
            Tab(
              text: 'Today (${todayAttendances.length})',
              icon: const Icon(Icons.today, size: 16),
            ),
            Tab(
              text: 'This Month (${thisMonthAttendances.length})',
              icon: const Icon(Icons.date_range, size: 16),
            ),
            Tab(
              text: 'Working (${driversWorking.length})',
              icon: const Icon(Icons.work, size: 16),
            ),
            Tab(
              text: 'Analytics',
              icon: const Icon(Icons.analytics, size: 16),
            ),
          ],
        ),
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
                  color: Colors.black.withOpacity(0.1),
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
                      hintText: 'Search by driver name, ID, status...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.filter_list, color: Colors.grey),
                            onPressed: () => _showFilterDialog(),
                          ),
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

                // Quick Stats Row
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickStat('Present', '${attendanceStats['present']}', Colors.green),
                    _buildQuickStat('Absent', '${attendanceStats['absent']}', Colors.red),
                    _buildQuickStat('Late', '${attendanceStats['late']}', Colors.orange),
                    _buildQuickStat('Working', '${driversWorking.length}', Colors.blue),
                  ],
                ),
              ],
            ),
          ),

          // Calendar (if enabled)
          if (_showCalendar)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar<Attendance>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  return attendanceState.attendances
                      .where((attendance) => isSameDay(attendance.date, day))
                      .toList();
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Color(0xFF1565C0),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAttendanceView(),
                _buildAttendanceList(todayAttendances, 'today'),
                _buildAttendanceList(thisMonthAttendances, 'month'),
                _buildWorkingDriversList(driversWorking),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CheckInOutScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.access_time),
        label: const Text('Check In/Out'),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList(List<Attendance> attendances, String type) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(attendanceProvider.notifier).loadAttendances();
      },
      child: attendances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyStateIcon(type),
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(type),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateSubMessage(type),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attendances.length,
              itemBuilder: (context, index) {
                final attendance = attendances[index];
                return _AttendanceCard(
                  attendance: attendance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceDetailScreen(attendance: attendance),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildWorkingDriversList(List<Attendance> workingAttendances) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(attendanceProvider.notifier).loadAttendances();
      },
      child: workingAttendances.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No drivers currently working', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('All drivers have checked out or haven\'t checked in yet', 
                       style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workingAttendances.length,
              itemBuilder: (context, index) {
                final attendance = workingAttendances[index];
                return _WorkingDriverCard(
                  attendance: attendance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceDetailScreen(attendance: attendance),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildAllAttendanceView() {
    final attendanceState = ref.watch(attendanceProvider);
    final filteredAttendances = _searchQuery.isNotEmpty 
        ? ref.read(attendanceProvider.notifier).searchAttendances(_searchQuery)
        : attendanceState.attendances;

    return Column(
      children: [
        // Quick Actions Row
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceAnalyticsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Advanced Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _show7DayView(),
                  icon: const Icon(Icons.calendar_view_week),
                  label: const Text('7-Day View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Attendance List
        Expanded(
          child: _buildAttendanceListWithCounts(filteredAttendances, 'all'),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final attendanceStats = ref.watch(attendanceStatsProvider);
    final summaries = ref.watch(attendanceSummariesProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Access to Advanced Analytics
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rocket_launch, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text(
                        'Advanced Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceAnalyticsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Open Attendance Analytics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Overall Stats
          _buildAnalyticsCard(
            'Overall Statistics',
            Icons.analytics,
            [
              _buildStatRow('Total Records', attendanceStats['total'].toString()),
              _buildStatRow('Present Days', attendanceStats['present'].toString()),
              _buildStatRow('Absent Days', attendanceStats['absent'].toString()),
              _buildStatRow('Leave Days', attendanceStats['leave'].toString()),
              _buildStatRow('Late Arrivals', attendanceStats['late'].toString()),
              _buildStatRow('Overtime Records', attendanceStats['overtime_records'].toString()),
              _buildStatRow('Total Hours', '${attendanceStats['total_hours'].toStringAsFixed(1)} hrs'),
              _buildStatRow('Avg Attendance', '${attendanceStats['avg_attendance'].toStringAsFixed(1)}%'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Driver Performance
          _buildAnalyticsCard(
            'Driver Performance (This Month)',
            Icons.people,
            summaries.take(5).map((summary) => 
              _buildPerformanceRow(
                summary.driverName, 
                summary.attendancePercentage, 
                summary.attendanceGradeColor
              )
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, IconData icon, List<Widget> children) {
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
                Icon(icon, color: const Color(0xFF1565C0)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${percentage.toStringAsFixed(1)}%', 
                   style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AttendanceStatus.values.map((status) {
                final isSelected = _statusFilter?.contains(status) ?? false;
                return FilterChip(
                  label: Text(status.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (_statusFilter == null) _statusFilter = [];
                      if (selected) {
                        _statusFilter!.add(status);
                      } else {
                        _statusFilter!.remove(status);
                      }
                      if (_statusFilter!.isEmpty) _statusFilter = null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _statusFilter = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSummaryReportDialog() {
    final summaries = ref.read(attendanceSummariesProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Summary Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summaries.isEmpty)
                const Text('No data available for this month')
              else
                ...summaries.map((summary) => ListTile(
                  title: Text(summary.driverName),
                  subtitle: Text('${summary.presentDays}/${summary.totalDays} days'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: summary.attendanceGradeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.attendancePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature feature will be available soon!\n\nThis will integrate with Google Sheets data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'today': return Icons.today;
      case 'month': return Icons.date_range;
      case 'working': return Icons.work;
      default: return Icons.list_alt;
    }
  }

  String _getEmptyStateMessage(String type) {
    switch (type) {
      case 'today': return 'No attendance records for today';
      case 'month': return 'No attendance records this month';
      case 'working': return 'No drivers currently working';
      default: return 'No attendance records found';
    }
  }

  String _getEmptyStateSubMessage(String type) {
    switch (type) {
      case 'today': return 'Drivers haven\'t checked in yet today';
      case 'month': return 'No attendance data for this month';
      case 'working': return 'All drivers have checked out';
      default: return 'Try adjusting your search or filters';
    }
  }

  void _show7DayView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_view_week, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  const Text(
                    '7-Day Attendance View',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _build7DayTable(startOfWeek),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build7DayTable(DateTime startOfWeek) {
    final attendances = ref.watch(attendanceProvider).attendances;
    final drivers = ref.watch(driverProvider).drivers.where((d) => d.status == DriverStatus.active).toList();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return SingleChildScrollView(
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
        ],
        rows: drivers.map((driver) {
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
                    date: DateTime.now(),
                    status: AttendanceStatus.absent,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                
                return DataCell(
                  dayAttendance.id.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: dayAttendance.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dayAttendance.status.icon,
                            style: TextStyle(color: dayAttendance.status.color),
                          ),
                        )
                      : const Text('-', style: TextStyle(color: Colors.grey)),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceListWithCounts(List<Attendance> attendances, String type) {
    // Group attendances by driver to show counts
    final driverAttendanceMap = <String, List<Attendance>>{};
    for (final attendance in attendances) {
      driverAttendanceMap.putIfAbsent(attendance.driverId, () => []).add(attendance);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(attendanceProvider.notifier).loadAttendances();
      },
      child: attendances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyStateIcon(type),
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(type),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateSubMessage(type),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attendances.length,
              itemBuilder: (context, index) {
                final attendance = attendances[index];
                final driverAttendances = driverAttendanceMap[attendance.driverId] ?? [];
                
                // Calculate stats
                final presentCount = driverAttendances.where((a) => a.status == AttendanceStatus.present).length;
                final absentCount = driverAttendances.where((a) => a.status == AttendanceStatus.absent).length;
                final lateCount = driverAttendances.where((a) => a.status == AttendanceStatus.late).length;
                
                return _AttendanceCardWithCounts(
                  attendance: attendance,
                  presentCount: presentCount,
                  absentCount: absentCount,
                  lateCount: lateCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceDetailScreen(attendance: attendance),
                      ),
                    );
                  },
                  onDelete: () => _showDeleteAttendanceDialog(attendance),
                );
              },
            ),
    );
  }

  void _showDeleteAttendanceDialog(Attendance attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Attendance Record'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the attendance record for ${attendance.driverName} on ${attendance.formattedDate}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(attendanceProvider.notifier).deleteAttendance(attendance.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Attendance record deleted successfully'
                          : 'Failed to delete attendance record',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback onTap;

  const _AttendanceCard({
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Driver Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: attendance.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        attendance.driverName.split(' ').map((n) => n[0]).join(''),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: attendance.status.color,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Driver Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.driverName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${attendance.driverEmployeeId} • ${attendance.formattedDate}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: attendance.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: attendance.status.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(attendance.status.icon, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          attendance.statusDisplayText,
                          style: TextStyle(
                            color: attendance.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Time Information
              Row(
                children: [
                  _buildTimeInfo(
                    'Check In',
                    attendance.checkInTimeFormatted,
                    Icons.login,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildTimeInfo(
                    'Check Out',
                    attendance.checkOutTimeFormatted,
                    Icons.logout,
                    Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildTimeInfo(
                    'Hours',
                    attendance.workingTimeFormatted,
                    Icons.schedule,
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceCardWithCounts extends StatefulWidget {
  final Attendance attendance;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AttendanceCardWithCounts({
    required this.attendance,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_AttendanceCardWithCounts> createState() => _AttendanceCardWithCountsState();
}

class _AttendanceCardWithCountsState extends State<_AttendanceCardWithCounts> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox for delete
                    Checkbox(
                      value: _isSelected,
                      onChanged: (value) {
                        setState(() {
                          _isSelected = value ?? false;
                        });
                      },
                    ),
                    
                    // Driver Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.attendance.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          widget.attendance.driverName.split(' ').map((n) => n[0]).join(''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.attendance.status.color,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Driver Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.attendance.driverName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.attendance.driverEmployeeId} • ${widget.attendance.formattedDate}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.attendance.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.attendance.status.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.attendance.status.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            widget.attendance.statusDisplayText,
                            style: TextStyle(
                              color: widget.attendance.status.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Delete Button
                    if (_isSelected)
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                
                // Attendance Counts
                Row(
                  children: [
                    _buildCountChip('Present', widget.presentCount, Colors.green),
                    const SizedBox(width: 8),
                    _buildCountChip('Absent', widget.absentCount, Colors.red),
                    const SizedBox(width: 8),
                    _buildCountChip('Late', widget.lateCount, Colors.orange),
                    const Spacer(),
                    // Time Information
                    _buildTimeInfo(
                      'Hours',
                      widget.attendance.workingTimeFormatted,
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkingDriverCard extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback onTap;

  const _WorkingDriverCard({
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final workingTime = DateTime.now().difference(attendance.checkInTime!);
    final hours = workingTime.inHours;
    final minutes = workingTime.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Working Indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.driverName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Checked in at ${attendance.checkInTimeFormatted}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                // Working Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hours}h ${minutes}m',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}