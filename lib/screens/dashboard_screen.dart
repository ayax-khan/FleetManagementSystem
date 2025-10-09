import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/fuel_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/chart_card.dart';
import '../widgets/dashboard/recent_activity_card.dart';
import '../widgets/common/loading_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _fuelData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load data from providers
      final vehicleState = ref.read(vehicleProvider);
      final driverState = ref.read(driverProvider);
      final fuelState = ref.read(fuelProvider);
      final attendanceState = ref.read(attendanceProvider);

      // Calculate statistics
      final totalVehicles = vehicleState.vehicles.length;
      final activeVehicles = vehicleState.vehicles
          .where((v) => v.status.name == 'active')
          .length;
      final totalDrivers = driverState.drivers.length;
      final totalAttendances = attendanceState.attendances.length;

      // Calculate fuel statistics
      final today = DateTime.now();
      final todayFuel = fuelState.fuelRecords
          .where((f) => isSameDay(f.date, today))
          .fold(0.0, (sum, f) => sum + f.totalCost);
      
      final monthStart = DateTime(today.year, today.month, 1);
      final monthFuel = fuelState.fuelRecords
          .where((f) => f.date.isAfter(monthStart.subtract(const Duration(days: 1))))
          .fold(0.0, (sum, f) => sum + f.totalCost);

      final avgFuelPerDay = monthFuel / today.day;

      // Prepare fuel chart data for last 7 days
      final last7Days = <Map<String, dynamic>>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayFuel = fuelState.fuelRecords
            .where((f) => isSameDay(f.date, date))
            .fold(0.0, (sum, f) => sum + f.totalCost);
        
        last7Days.add({
          'date': DateFormat('MMM d').format(date),
          'cost': dayFuel,
        });
      }

      setState(() {
        _stats = {
          'totalVehicles': totalVehicles,
          'activeVehicles': activeVehicles,
          'totalDrivers': totalDrivers,
          'totalAttendances': totalAttendances,
          'todayFuel': todayFuel,
          'monthFuel': monthFuel,
          'avgFuelPerDay': avgFuelPerDay,
        };
        _fuelData = last7Days;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading dashboard...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Fleet overview and real-time metrics',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.8,
                children: [
                  StatCard(
                    title: 'Total Vehicles',
                    value: '${_stats['totalVehicles'] ?? 0}',
                    subtitle: '${_stats['activeVehicles'] ?? 0} active',
                    icon: Icons.directions_car,
                    color: const Color(0xFF3B82F6),
                    trend: true,
                  ),
                  StatCard(
                    title: 'Total Drivers',
                    value: '${_stats['totalDrivers'] ?? 0}',
                    subtitle: 'All registered drivers',
                    icon: Icons.people,
                    color: const Color(0xFF8B5CF6),
                  ),
                  StatCard(
                    title: 'Attendance Records',
                    value: '${_stats['totalAttendances'] ?? 0}',
                    subtitle: 'Total records',
                    icon: Icons.access_time,
                    color: const Color(0xFF10B981),
                    trend: true,
                  ),
                  StatCard(
                    title: "Today's Fuel",
                    value: 'Rs ${(_stats['todayFuel'] ?? 0.0).toStringAsFixed(0)}',
                    subtitle: 'Fuel cost today',
                    icon: Icons.local_gas_station,
                    color: const Color(0xFFF59E0B),
                  ),
                  StatCard(
                    title: 'Month Fuel',
                    value: 'Rs ${(_stats['monthFuel'] ?? 0.0).toStringAsFixed(0)}',
                    subtitle: "This month's total",
                    icon: Icons.trending_up,
                    color: const Color(0xFFEF4444),
                    trend: true,
                  ),
                  StatCard(
                    title: 'Avg Fuel/Day',
                    value: 'Rs ${(_stats['avgFuelPerDay'] ?? 0.0).toStringAsFixed(0)}',
                    subtitle: 'Daily average',
                    icon: Icons.analytics,
                    color: const Color(0xFF6366F1),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Charts and Recent Activity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fuel Cost Chart
              Expanded(
                child: ChartCard(
                  title: 'Fuel Costs - Last 7 Days',
                  data: _fuelData,
                ),
              ),
              const SizedBox(width: 24),
              // Recent Activity
              Expanded(
                child: RecentActivityCard(
                  fuelRecords: ref.watch(fuelProvider).fuelRecords,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
