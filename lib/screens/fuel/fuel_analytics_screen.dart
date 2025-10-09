import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../../models/vehicle.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' as custom;
import '../../widgets/common/empty_state_widget.dart';

class FuelAnalyticsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/fuel/analytics';

  const FuelAnalyticsScreen({super.key});

  @override
  ConsumerState<FuelAnalyticsScreen> createState() => _FuelAnalyticsScreenState();
}

class _FuelAnalyticsScreenState extends ConsumerState<FuelAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fuelState = ref.watch(fuelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Analytics'),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'settings':
                  _showAnalyticsSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Analytics Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Vehicles'),
            Tab(text: 'Efficiency'),
          ],
        ),
      ),
      body: fuelState.isLoading
          ? const LoadingWidget(message: 'Loading analytics data...')
          : fuelState.error != null
              ? custom.ErrorWidget(
                  message: fuelState.error!,
                  onRetry: () => ref.read(fuelProvider.notifier).loadFuelData(),
                )
              : Column(
                  children: [
                    _buildDateRangeHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildTrendsTab(),
                          _buildVehiclesTab(),
                          _buildEfficiencyTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('MMM d, yyyy').format(_selectedDateRange.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange.end)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.tune),
            label: const Text('Change Period'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredRecords = _getFilteredRecords();
    final stats = _calculateOverallStats(filteredRecords);

    if (filteredRecords.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.analytics,
        title: 'No Data Available',
        subtitle: 'No fuel records found for the selected period',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Grid
          _buildKeyMetricsGrid(stats),
          const SizedBox(height: 24),

          // Fuel Type Distribution
          _buildFuelTypeDistribution(filteredRecords),
          const SizedBox(height: 24),

          // Payment Method Breakdown
          _buildPaymentMethodBreakdown(filteredRecords),
          const SizedBox(height: 24),

          // Top Stations
          _buildTopStations(filteredRecords),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final filteredRecords = _getFilteredRecords();

    if (filteredRecords.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.trending_up,
        title: 'No Trend Data',
        subtitle: 'No fuel records found for trend analysis',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monthly Spending Trend
          _buildMonthlySpendingCard(filteredRecords),
          const SizedBox(height: 16),

          // Fuel Consumption Trend
          _buildConsumptionTrendCard(filteredRecords),
          const SizedBox(height: 16),

          // Frequency Analysis
          _buildFrequencyAnalysisCard(filteredRecords),
          const SizedBox(height: 16),

          // Price Fluctuation
          _buildPriceFluctuationCard(filteredRecords),
        ],
      ),
    );
  }

  Widget _buildVehiclesTab() {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final topVehicles = ref.watch(topFuelConsumingVehiclesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top Consuming Vehicles
          _buildTopConsumingVehiclesCard(topVehicles),
          const SizedBox(height: 16),

          // Vehicle Comparison
          _buildVehicleComparisonCard(vehicles),
          const SizedBox(height: 16),

          // Vehicle Performance
          _buildVehiclePerformanceCard(vehicles),
        ],
      ),
    );
  }

  Widget _buildEfficiencyTab() {
    final alerts = ref.watch(fuelEfficiencyAlertsProvider);
    final filteredRecords = _getFilteredRecords();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Efficiency Overview
          _buildEfficiencyOverviewCard(filteredRecords),
          const SizedBox(height: 16),

          // Efficiency Alerts
          if (alerts.isNotEmpty) ...[
            _buildEfficiencyAlertsCard(alerts),
            const SizedBox(height: 16),
          ],

          // Efficiency Distribution
          _buildEfficiencyDistributionCard(filteredRecords),
          const SizedBox(height: 16),

          // Improvement Recommendations
          _buildImprovementRecommendationsCard(filteredRecords),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Spent',
          'Rs ${NumberFormat('#,##0').format(stats['totalCost'])}',
          Icons.attach_money,
          Colors.green,
          '${stats['recordCount']} transactions',
        ),
        _buildMetricCard(
          'Fuel Consumed',
          '${stats['totalLiters'].toStringAsFixed(1)}L',
          Icons.local_gas_station,
          Colors.orange,
          'Avg: ${stats['avgLitersPerFill'].toStringAsFixed(1)}L/fill',
        ),
        _buildMetricCard(
          'Average Price',
          'Rs ${stats['avgPricePerLiter'].toStringAsFixed(2)}/L',
          Icons.trending_up,
          Colors.blue,
          'Range: Rs ${stats['minPrice'].toStringAsFixed(2)} - ${stats['maxPrice'].toStringAsFixed(2)}',
        ),
        _buildMetricCard(
          'Efficiency',
          '${stats['avgConsumption'].toStringAsFixed(1)}L/100km',
          Icons.speed,
          _getEfficiencyColor(stats['avgConsumption']),
          _getEfficiencyRating(stats['avgConsumption']).displayName,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelTypeDistribution(List<FuelRecord> records) {
    final fuelTypeStats = <FuelType, Map<String, dynamic>>{};
    
    for (final record in records) {
      fuelTypeStats[record.fuelType] = fuelTypeStats[record.fuelType] ?? {
        'count': 0,
        'totalCost': 0.0,
        'totalLiters': 0.0,
      };
      
      fuelTypeStats[record.fuelType]!['count']++;
      fuelTypeStats[record.fuelType]!['totalCost'] += record.totalCost;
      fuelTypeStats[record.fuelType]!['totalLiters'] += record.quantity;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel Type Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...fuelTypeStats.entries.map((entry) {
              final fuelType = entry.key;
              final stats = entry.value;
              final percentage = (stats['totalCost'] / records.fold(0.0, (sum, r) => sum + r.totalCost) * 100);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: fuelType.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(fuelType.iconData, size: 20, color: fuelType.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fuelType.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: fuelType.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 32),
                        Text(
                          '${stats['count']} fills • ${stats['totalLiters'].toStringAsFixed(1)}L • Rs ${NumberFormat('#,##0').format(stats['totalCost'])}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(fuelType.color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown(List<FuelRecord> records) {
    final paymentStats = <PaymentMethod, Map<String, dynamic>>{};
    
    for (final record in records) {
      paymentStats[record.paymentMethod] = paymentStats[record.paymentMethod] ?? {
        'count': 0,
        'totalCost': 0.0,
      };
      
      paymentStats[record.paymentMethod]!['count']++;
      paymentStats[record.paymentMethod]!['totalCost'] += record.totalCost;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentStats.entries.map((entry) {
                final method = entry.key;
                final stats = entry.value;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: method.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: method.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(method.iconData, size: 16, color: method.color),
                      const SizedBox(width: 6),
                      Text(
                        '${method.displayName}: ${stats['count']}',
                        style: TextStyle(
                          color: method.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStations(List<FuelRecord> records) {
    final stationStats = <String, Map<String, dynamic>>{};
    
    for (final record in records) {
      stationStats[record.fuelStationName] = stationStats[record.fuelStationName] ?? {
        'count': 0,
        'totalCost': 0.0,
        'totalLiters': 0.0,
      };
      
      stationStats[record.fuelStationName]!['count']++;
      stationStats[record.fuelStationName]!['totalCost'] += record.totalCost;
      stationStats[record.fuelStationName]!['totalLiters'] += record.quantity;
    }

    final sortedStations = stationStats.entries.toList()
      ..sort((a, b) => b.value['totalCost'].compareTo(a.value['totalCost']));

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Fuel Stations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedStations.take(5).map((entry) {
              final stationName = entry.key;
              final stats = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${stats['count']} visits • ${stats['totalLiters'].toStringAsFixed(1)}L',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs ${NumberFormat('#,##0').format(stats['totalCost'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingCard(List<FuelRecord> records) {
    final monthlyData = <String, double>{};
    
    for (final record in records) {
      final monthKey = DateFormat('MMM yyyy').format(record.date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + record.totalCost;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (monthlyData.isEmpty)
              const Center(
                child: Text('No data available for trend analysis'),
              )
            else
              Column(
                children: monthlyData.entries.map((entry) {
                  final maxSpending = monthlyData.values.reduce((a, b) => a > b ? a : b);
                  final percentage = entry.value / maxSpending;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Rs ${NumberFormat('#,##0').format(entry.value)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTrendCard(List<FuelRecord> records) {
    final recordsWithConsumption = records
        .where((r) => r.fuelConsumption != null)
        .toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel Consumption Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recordsWithConsumption.isEmpty)
              const Center(
                child: Text('No consumption data available'),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrendItem(
                    'Average',
                    '${(recordsWithConsumption.fold(0.0, (sum, r) => sum + r.fuelConsumption!) / recordsWithConsumption.length).toStringAsFixed(1)}L/100km',
                    Icons.trending_flat,
                    Colors.blue,
                  ),
                  _buildTrendItem(
                    'Best',
                    '${recordsWithConsumption.map((r) => r.fuelConsumption!).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}L/100km',
                    Icons.trending_down,
                    Colors.green,
                  ),
                  _buildTrendItem(
                    'Worst',
                    '${recordsWithConsumption.map((r) => r.fuelConsumption!).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}L/100km',
                    Icons.trending_up,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyAnalysisCard(List<FuelRecord> records) {
    final totalDays = _selectedDateRange.duration.inDays;
    final avgDaysBetweenFills = totalDays / (records.length > 0 ? records.length : 1);
    final lastFillDate = records.isNotEmpty 
        ? records.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
        : null;
    final daysSinceLastFill = lastFillDate != null 
        ? DateTime.now().difference(lastFillDate).inDays 
        : 0;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refueling Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFrequencyItem(
                    'Total Fills',
                    '${records.length}',
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildFrequencyItem(
                    'Avg Interval',
                    '${avgDaysBetweenFills.toStringAsFixed(1)} days',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildFrequencyItem(
                    'Since Last',
                    '$daysSinceLastFill days',
                    Icons.history,
                    daysSinceLastFill > avgDaysBetweenFills * 1.5 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPriceFluctuationCard(List<FuelRecord> records) {
    final priceData = records.map((r) => r.unitPrice).toList()..sort();
    final minPrice = priceData.isNotEmpty ? priceData.first : 0.0;
    final maxPrice = priceData.isNotEmpty ? priceData.last : 0.0;
    final avgPrice = priceData.isNotEmpty 
        ? priceData.reduce((a, b) => a + b) / priceData.length 
        : 0.0;
    final fluctuation = maxPrice - minPrice;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceItem(
                    'Lowest',
                    'Rs ${minPrice.toStringAsFixed(2)}',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPriceItem(
                    'Average',
                    'Rs ${avgPrice.toStringAsFixed(2)}',
                    Icons.horizontal_rule,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPriceItem(
                    'Highest',
                    'Rs ${maxPrice.toStringAsFixed(2)}',
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildPriceItem(
                    'Range',
                    'Rs ${fluctuation.toStringAsFixed(2)}',
                    Icons.swap_vert,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopConsumingVehiclesCard(List<VehicleFuelAnalytics> topVehicles) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Fuel Consuming Vehicles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topVehicles.isEmpty)
              const Center(
                child: Text('No vehicle data available'),
              )
            else
              ...topVehicles.map((analytics) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: analytics.efficiencyRating.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          analytics.efficiencyRating.iconData,
                          color: analytics.efficiencyRating.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analytics.vehicleName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${analytics.totalQuantity.toStringAsFixed(1)}L • ${analytics.averageConsumption.toStringAsFixed(1)}L/100km',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(analytics.totalCost)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleComparisonCard(List<Vehicle> vehicles) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              const Center(
                child: Text('No vehicles available for comparison'),
              )
            else ...[
              const Text(
                'Comparing fuel efficiency across your fleet:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...vehicles.take(5).map((vehicle) {
                final analytics = ref.watch(vehicleFuelAnalyticsProvider(vehicle.id));
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getVehicleIcon(vehicle.type),
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (analytics != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: analytics.efficiencyRating.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${analytics.averageConsumption.toStringAsFixed(1)}L/100km',
                            style: TextStyle(
                              color: analytics.efficiencyRating.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ] else
                        const Text(
                          'No data',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePerformanceCard(List<Vehicle> vehicles) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    'Total Vehicles',
                    '${vehicles.length}',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    'Active',
                    '${vehicles.where((v) => v.status == VehicleStatus.active).length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    'Maintenance',
                    '${vehicles.where((v) => v.status == VehicleStatus.maintenance).length}',
                    Icons.build,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEfficiencyOverviewCard(List<FuelRecord> records) {
    final recordsWithConsumption = records
        .where((r) => r.fuelConsumption != null)
        .toList();
    
    final efficiencyCategories = <FuelEfficiencyRating, int>{};
    for (final record in recordsWithConsumption) {
      final rating = _getEfficiencyRating(record.fuelConsumption!);
      efficiencyCategories[rating] = (efficiencyCategories[rating] ?? 0) + 1;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (efficiencyCategories.isEmpty)
              const Center(
                child: Text('No efficiency data available'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FuelEfficiencyRating.values.map((rating) {
                  final count = efficiencyCategories[rating] ?? 0;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rating.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rating.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rating.iconData, size: 16, color: rating.color),
                        const SizedBox(width: 6),
                        Text(
                          '${rating.displayName}: $count',
                          style: TextStyle(
                            color: rating.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyAlertsCard(List<VehicleFuelAnalytics> alerts) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Efficiency Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts.map((analytics) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analytics.vehicleName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Poor efficiency: ${analytics.averageConsumption.toStringAsFixed(1)}L/100km',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyDistributionCard(List<FuelRecord> records) {
    final recordsWithConsumption = records
        .where((r) => r.fuelConsumption != null)
        .toList();

    if (recordsWithConsumption.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Efficiency Distribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No efficiency data available'),
              ),
            ],
          ),
        ),
      );
    }

    final consumptionValues = recordsWithConsumption
        .map((r) => r.fuelConsumption!)
        .toList()..sort();

    final ranges = <String, int>{
      '0-6 L/100km': 0,
      '6-8 L/100km': 0,
      '8-12 L/100km': 0,
      '12-16 L/100km': 0,
      '16+ L/100km': 0,
    };

    for (final consumption in consumptionValues) {
      if (consumption <= 6) {
        ranges['0-6 L/100km'] = ranges['0-6 L/100km']! + 1;
      } else if (consumption <= 8) {
        ranges['6-8 L/100km'] = ranges['6-8 L/100km']! + 1;
      } else if (consumption <= 12) {
        ranges['8-12 L/100km'] = ranges['8-12 L/100km']! + 1;
      } else if (consumption <= 16) {
        ranges['12-16 L/100km'] = ranges['12-16 L/100km']! + 1;
      } else {
        ranges['16+ L/100km'] = ranges['16+ L/100km']! + 1;
      }
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ranges.entries.map((entry) {
              final percentage = entry.value / recordsWithConsumption.length * 100;
              final color = _getRangeColor(entry.key);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementRecommendationsCard(List<FuelRecord> records) {
    final recordsWithConsumption = records
        .where((r) => r.fuelConsumption != null)
        .toList();

    final avgConsumption = recordsWithConsumption.isNotEmpty
        ? recordsWithConsumption.fold(0.0, (sum, r) => sum + r.fuelConsumption!) / recordsWithConsumption.length
        : 0.0;

    final recommendations = _getRecommendations(avgConsumption, recordsWithConsumption.length);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Improvement Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<FuelRecord> _getFilteredRecords() {
    final allRecords = ref.read(fuelProvider).fuelRecords;
    return allRecords.where((record) {
      return record.date.isAfter(_selectedDateRange.start.subtract(const Duration(days: 1))) &&
             record.date.isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _calculateOverallStats(List<FuelRecord> records) {
    if (records.isEmpty) {
      return {
        'totalCost': 0.0,
        'totalLiters': 0.0,
        'avgPricePerLiter': 0.0,
        'avgConsumption': 0.0,
        'avgLitersPerFill': 0.0,
        'recordCount': 0,
        'minPrice': 0.0,
        'maxPrice': 0.0,
      };
    }

    final totalCost = records.fold(0.0, (sum, r) => sum + r.totalCost);
    final totalLiters = records.fold(0.0, (sum, r) => sum + r.quantity);
    final avgPricePerLiter = totalLiters > 0 ? totalCost / totalLiters : 0.0;
    
    final recordsWithConsumption = records.where((r) => r.fuelConsumption != null).toList();
    final avgConsumption = recordsWithConsumption.isNotEmpty
        ? recordsWithConsumption.fold(0.0, (sum, r) => sum + r.fuelConsumption!) / recordsWithConsumption.length
        : 0.0;
    
    final avgLitersPerFill = totalLiters / records.length;
    final prices = records.map((r) => r.unitPrice).toList()..sort();
    
    return {
      'totalCost': totalCost,
      'totalLiters': totalLiters,
      'avgPricePerLiter': avgPricePerLiter,
      'avgConsumption': avgConsumption,
      'avgLitersPerFill': avgLitersPerFill,
      'recordCount': records.length,
      'minPrice': prices.first,
      'maxPrice': prices.last,
    };
  }

  Color _getEfficiencyColor(double consumption) {
    if (consumption <= 6) return Colors.green;
    if (consumption <= 8) return Colors.lightGreen;
    if (consumption <= 12) return Colors.orange;
    if (consumption <= 16) return Colors.red;
    return Colors.red.shade800;
  }

  FuelEfficiencyRating _getEfficiencyRating(double consumption) {
    if (consumption <= 6) return FuelEfficiencyRating.excellent;
    if (consumption <= 8) return FuelEfficiencyRating.good;
    if (consumption <= 12) return FuelEfficiencyRating.average;
    if (consumption <= 16) return FuelEfficiencyRating.poor;
    return FuelEfficiencyRating.terrible;
  }

  Color _getRangeColor(String range) {
    switch (range) {
      case '0-6 L/100km': return Colors.green;
      case '6-8 L/100km': return Colors.lightGreen;
      case '8-12 L/100km': return Colors.orange;
      case '12-16 L/100km': return Colors.red;
      case '16+ L/100km': return Colors.red.shade800;
      default: return Colors.grey;
    }
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car: return Icons.directions_car;
      case VehicleType.truck: return Icons.local_shipping;
      case VehicleType.van: return Icons.airport_shuttle;
      case VehicleType.bus: return Icons.directions_bus;
      case VehicleType.motorcycle: return Icons.two_wheeler;
      case VehicleType.trailer: return Icons.rv_hookup;
    }
  }

  List<String> _getRecommendations(double avgConsumption, int recordCount) {
    final recommendations = <String>[];
    
    if (recordCount < 5) {
      recommendations.add('Continue tracking fuel consumption to get more accurate insights.');
    }
    
    if (avgConsumption > 12) {
      recommendations.addAll([
        'Schedule regular vehicle maintenance to improve fuel efficiency.',
        'Check tire pressure monthly - properly inflated tires can improve efficiency by up to 3%.',
        'Consider driver training on fuel-efficient driving techniques.',
        'Remove excess weight from vehicles to reduce fuel consumption.',
      ]);
    } else if (avgConsumption > 8) {
      recommendations.addAll([
        'Maintain steady speeds on highways to optimize fuel consumption.',
        'Reduce idling time - turn off engines during long stops.',
        'Plan routes efficiently to minimize total distance traveled.',
      ]);
    } else {
      recommendations.addAll([
        'Great fuel efficiency! Keep up the good driving habits.',
        'Share best practices with other drivers in your fleet.',
        'Consider this vehicle as a benchmark for fleet efficiency.',
      ]);
    }
    
    recommendations.addAll([
      'Use fuel cards for better expense tracking and potential discounts.',
      'Monitor fuel price trends to identify the best refueling times.',
      'Consider fuel-efficient routes using GPS navigation.',
    ]);
    
    return recommendations;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _exportData() {
    // In a real app, you would implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAnalyticsSettings() {
    // In a real app, you would show analytics settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics settings would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}