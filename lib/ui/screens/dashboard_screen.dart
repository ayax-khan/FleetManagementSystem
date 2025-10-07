// lib/ui/screens/dashboard_screen.dart
import 'package:fleet_management/models/fuel_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Changed from charts_flutter
import '../../controllers/dashboard_controller.dart';
import '../widgets/kpi_card.dart';
import '../widgets/data_table.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>(
      create: (_) => DashboardController(),
      child: Consumer<DashboardController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.refresh,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: MediaQuery.of(context).size.width > 1200
                        ? 3
                        : 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      KpiCard(
                        title: 'Total Vehicles',
                        value: controller.totalVehicles.toString(),
                        subtitle: '${controller.activeVehicles} active',
                        icon: Icons.local_shipping,
                        color: Colors.blue,
                      ),
                      KpiCard(
                        title: 'Total Drivers',
                        value: controller.totalDrivers.toString(),
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                      KpiCard(
                        title: 'Active Jobs',
                        value: controller.activeJobs.toString(),
                        subtitle: 'Ongoing',
                        icon: Icons.assignment,
                        color: Colors.green,
                      ),
                      KpiCard(
                        title: "Today's Fuel",
                        value:
                            'Rs ${controller.todayFuelCost.toStringAsFixed(0)}',
                        subtitle: 'Fuel cost today',
                        icon: Icons.local_gas_station,
                        color: Colors.orange,
                      ),
                      KpiCard(
                        title: 'Month Fuel',
                        value:
                            'Rs ${controller.monthFuelCost.toStringAsFixed(0)}',
                        subtitle: "This month's total",
                        icon: Icons.trending_up,
                        color: Colors.red,
                      ),
                      KpiCard(
                        title: 'Avg Fuel/Day',
                        value:
                            'Rs ${controller.avgFuelPerDay.toStringAsFixed(0)}',
                        subtitle: 'Daily average',
                        icon: Icons.bar_chart,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fuel Costs - Last 7 Days',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 300,
                                  child: BarChart(
                                    _createFuelChart(controller.fuelData),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Trips',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (controller.recentTrips.isEmpty)
                                  const Center(child: Text('No recent trips'))
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: controller.recentTrips.length,
                                    itemBuilder: (context, index) {
                                      final trip =
                                          controller.recentTrips[index];
                                      return ListTile(
                                        title: Text(trip.purpose ?? 'Trip'),
                                        subtitle: Text(
                                          '${trip.startKm} - ${trip.endKm ?? 'Ongoing'} KM',
                                        ),
                                        trailing: Chip(
                                          label: Text(trip.status),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Anomalies & Reminders',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<FuelEntry>>(
                    future: controller.getAnomalies(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return CustomDataTable(
                          headers: ['Date', 'Vehicle', 'Liters', 'Cost'],
                          rows: snapshot.data!
                              .map(
                                (f) => [
                                  f.date.toString().split(' ')[0],
                                  f.vehicleId,
                                  f.liters.toString(),
                                  f.totalCost.toString(),
                                ],
                              )
                              .toList(),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BarChartData _createFuelChart(List<Map<String, dynamic>> data) {
    return BarChartData(
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['date'].toString().substring(
                      5,
                    ), // Show only MM-DD
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('Rs ${value.toInt()}');
            },
            reservedSize: 40,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: (item['cost'] as num).toDouble(),
              color: Colors.blue,
              width: 16,
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(show: false),
    );
  }
}
