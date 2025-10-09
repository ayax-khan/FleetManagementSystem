import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../../providers/fuel_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' as custom;
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/fuel/fuel_record_card.dart';
import '../../widgets/fuel/fuel_stats_card.dart';
import '../../widgets/fuel/fuel_filter_dialog.dart';
import 'add_fuel_record_screen.dart';
import 'fuel_detail_screen.dart';
import 'fuel_analytics_screen.dart';

class FuelListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/fuel';

  const FuelListScreen({super.key});

  @override
  ConsumerState<FuelListScreen> createState() => _FuelListScreenState();
}

class _FuelListScreenState extends ConsumerState<FuelListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuelState = ref.watch(fuelProvider);
    final fuelNotifier = ref.read(fuelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.pushNamed(context, FuelAnalyticsScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AddFuelRecordScreen.routeName);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'This Month'),
            Tab(text: 'Analytics'),
            Tab(text: 'Stations'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(fuelNotifier),
          _buildStatsOverview(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllFuelRecordsTab(),
                _buildThisMonthTab(),
                _buildAnalyticsTab(),
                _buildStationsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AddFuelRecordScreen.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters(FuelNotifier fuelNotifier) {
    return AppCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by vehicle, driver, station...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showFilterDialog(fuelNotifier),
                icon: const Icon(Icons.filter_list),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
              IconButton(
                onPressed: () {
                  fuelNotifier.clearFilter();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActiveFiltersChips(fuelNotifier),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(FuelNotifier fuelNotifier) {
    final filter = ref.watch(fuelProvider).filter;
    final chips = <Widget>[];

    if (filter.startDate != null || filter.endDate != null) {
      String dateRange = '';
      if (filter.startDate != null && filter.endDate != null) {
        dateRange = '${DateFormat('MMM d').format(filter.startDate!)} - ${DateFormat('MMM d').format(filter.endDate!)}';
      } else if (filter.startDate != null) {
        dateRange = 'From ${DateFormat('MMM d').format(filter.startDate!)}';
      } else if (filter.endDate != null) {
        dateRange = 'Until ${DateFormat('MMM d').format(filter.endDate!)}';
      }
      
      chips.add(
        Chip(
          label: Text(dateRange),
          onDeleted: () => fuelNotifier.updateFilter(
            filter.copyWith(startDate: null, endDate: null),
          ),
        ),
      );
    }

    if (filter.fuelTypes?.isNotEmpty == true) {
      chips.add(
        Chip(
          label: Text('${filter.fuelTypes!.length} fuel type(s)'),
          onDeleted: () => fuelNotifier.updateFilter(
            filter.copyWith(fuelTypes: null),
          ),
        ),
      );
    }

    if (filter.vehicleIds?.isNotEmpty == true) {
      chips.add(
        Chip(
          label: Text('${filter.vehicleIds!.length} vehicle(s)'),
          onDeleted: () => fuelNotifier.updateFilter(
            filter.copyWith(vehicleIds: null),
          ),
        ),
      );
    }

    if (filter.minAmount != null || filter.maxAmount != null) {
      String amountRange = '';
      if (filter.minAmount != null && filter.maxAmount != null) {
        amountRange = 'Rs ${filter.minAmount!.toStringAsFixed(0)} - Rs ${filter.maxAmount!.toStringAsFixed(0)}';
      } else if (filter.minAmount != null) {
        amountRange = 'Min Rs ${filter.minAmount!.toStringAsFixed(0)}';
      } else if (filter.maxAmount != null) {
        amountRange = 'Max Rs ${filter.maxAmount!.toStringAsFixed(0)}';
      }
      
      chips.add(
        Chip(
          label: Text(amountRange),
          onDeleted: () => fuelNotifier.updateFilter(
            filter.copyWith(minAmount: null, maxAmount: null),
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) => 
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: chip,
          )
        ).toList(),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final stats = ref.watch(fuelStatsProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FuelStatsCard(
              title: 'Total Records',
              value: stats['total_records'].toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FuelStatsCard(
              title: 'Total Cost',
              value: 'Rs ${NumberFormat('#,##0').format(stats['total_cost'])}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FuelStatsCard(
              title: 'Total Liters',
              value: '${stats['total_liters'].toStringAsFixed(1)}L',
              icon: Icons.local_gas_station,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFuelRecordsTab() {
    final fuelState = ref.watch(fuelProvider);
    
    if (fuelState.isLoading) {
      return const LoadingWidget(message: 'Loading fuel records...');
    }

    if (fuelState.error != null) {
      return custom.ErrorWidget(
        message: fuelState.error!,
        onRetry: () => ref.read(fuelProvider.notifier).loadFuelData(),
      );
    }

    List<FuelRecord> records = fuelState.fuelRecords;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      records = ref.read(fuelProvider.notifier).searchFuelRecords(_searchQuery);
    }

    // Apply active filters
    records = ref.read(fuelProvider.notifier).getFilteredFuelRecords(fuelState.filter);

    if (records.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.local_gas_station,
        title: 'No Fuel Records',
        subtitle: _searchQuery.isNotEmpty || _hasActiveFilters()
            ? 'No records match your search criteria'
            : 'Start by adding your first fuel record',
        actionLabel: 'Add Fuel Record',
        onAction: () {
          Navigator.pushNamed(context, AddFuelRecordScreen.routeName);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fuelProvider.notifier).loadFuelData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FuelRecordCard(
              record: record,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  FuelDetailScreen.routeName,
                  arguments: record.id,
                );
              },
              onDelete: () => _confirmDeleteRecord(record),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThisMonthTab() {
    final thisMonthRecords = ref.watch(thisMonthFuelRecordsProvider);
    final filteredRecords = _searchQuery.isNotEmpty
        ? ref.read(fuelProvider.notifier).searchFuelRecords(_searchQuery)
            .where((r) => thisMonthRecords.contains(r)).toList()
        : thisMonthRecords;

    if (filteredRecords.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_month,
        title: 'No Records This Month',
        subtitle: 'No fuel records found for the current month',
        actionLabel: 'Add Fuel Record',
        onAction: () {
          Navigator.pushNamed(context, AddFuelRecordScreen.routeName);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fuelProvider.notifier).loadFuelData(),
      child: Column(
        children: [
          _buildMonthlyStats(thisMonthRecords),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FuelRecordCard(
                    record: record,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        FuelDetailScreen.routeName,
                        arguments: record.id,
                      );
                    },
                    onDelete: () => _confirmDeleteRecord(record),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(List<FuelRecord> records) {
    final totalCost = records.fold(0.0, (sum, r) => sum + r.totalCost);
    final totalLiters = records.fold(0.0, (sum, r) => sum + r.quantity);
    final avgConsumption = records.where((r) => r.fuelConsumption != null)
        .fold(0.0, (sum, r) => sum + r.fuelConsumption!) / 
        records.where((r) => r.fuelConsumption != null).length;

    return AppCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMMM yyyy').format(DateTime.now())} Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Cost',
                    'Rs ${NumberFormat('#,##0').format(totalCost)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Liters',
                    '${totalLiters.toStringAsFixed(1)}L',
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Consumption',
                    avgConsumption.isNaN ? 'N/A' : '${avgConsumption.toStringAsFixed(1)}L/100km',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final topVehicles = ref.watch(topFuelConsumingVehiclesProvider);
    final alerts = ref.watch(fuelEfficiencyAlertsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Analytics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, FuelAnalyticsScreen.routeName);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickStatsGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (topVehicles.isNotEmpty) ...[
            AppCard(
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
                    ...topVehicles.take(3).map((analytics) => 
                      _buildVehicleAnalyticsItem(analytics)
                    ).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (alerts.isNotEmpty) ...[
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Fuel Efficiency Alerts',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...alerts.take(3).map((analytics) => 
                      _buildEfficiencyAlert(analytics)
                    ).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final stats = ref.watch(fuelStatsProvider);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildQuickStatCard(
          'Average Price',
          'Rs ${stats['average_price'].toStringAsFixed(2)}/L',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildQuickStatCard(
          'Total Distance',
          '${NumberFormat('#,##0').format(stats['total_distance'])} km',
          Icons.route,
          Colors.green,
        ),
        _buildQuickStatCard(
          'Avg Consumption',
          '${stats['average_consumption'].toStringAsFixed(1)}L/100km',
          Icons.speed,
          Colors.orange,
        ),
        _buildQuickStatCard(
          'Records',
          stats['total_records'].toString(),
          Icons.receipt,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAnalyticsItem(VehicleFuelAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs ${NumberFormat('#,##0').format(analytics.totalCost)} • ${analytics.totalQuantity.toStringAsFixed(1)}L',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${analytics.averageConsumption.toStringAsFixed(1)}L/100km',
            style: TextStyle(
              color: analytics.efficiencyRating.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyAlert(VehicleFuelAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 20),
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
                  'Poor fuel efficiency: ${analytics.averageConsumption.toStringAsFixed(1)}L/100km',
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
  }

  Widget _buildStationsTab() {
    final fuelState = ref.watch(fuelProvider);
    
    if (fuelState.isLoading) {
      return const LoadingWidget(message: 'Loading fuel stations...');
    }

    final stations = fuelState.fuelStations;
    
    if (stations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.local_gas_station,
        title: 'No Fuel Stations',
        subtitle: 'No fuel stations available',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fuelProvider.notifier).loadFuelData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              station.location,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(station.rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Current Prices:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: station.currentPrices.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: entry.key.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: entry.key.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.key.iconData, size: 16, color: entry.key.color),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key.displayName}: Rs ${entry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: entry.key.color,
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
        },
      ),
    );
  }

  void _showFilterDialog(FuelNotifier fuelNotifier) {
    showDialog(
      context: context,
      builder: (context) => FuelFilterDialog(
        currentFilter: ref.read(fuelProvider).filter,
        onApplyFilter: (filter) {
          fuelNotifier.updateFilter(filter);
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    final filter = ref.read(fuelProvider).filter;
    return filter.startDate != null ||
           filter.endDate != null ||
           filter.vehicleIds?.isNotEmpty == true ||
           filter.fuelTypes?.isNotEmpty == true ||
           filter.paymentMethods?.isNotEmpty == true ||
           filter.fuelStationIds?.isNotEmpty == true ||
           filter.minAmount != null ||
           filter.maxAmount != null;
  }

  Future<void> _confirmDeleteRecord(FuelRecord record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fuel Record'),
        content: Text(
          'Are you sure you want to delete this fuel record for ${record.vehicleName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref.read(fuelProvider.notifier).deleteFuelRecord(record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Fuel record deleted successfully'
                  : 'Failed to delete fuel record',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}