import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../../providers/fuel_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' as custom;
import 'edit_fuel_record_screen.dart';

class FuelDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/fuel/detail';
  final String fuelRecordId;

  const FuelDetailScreen({
    super.key,
    required this.fuelRecordId,
  });

  @override
  ConsumerState<FuelDetailScreen> createState() => _FuelDetailScreenState();
}

class _FuelDetailScreenState extends ConsumerState<FuelDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final fuelState = ref.watch(fuelProvider);
    
    if (fuelState.isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading fuel record...'),
      );
    }

    final fuelRecord = fuelState.fuelRecords
        .where((record) => record.id == widget.fuelRecordId)
        .firstOrNull;

    if (fuelRecord == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fuel Record')),
        body: const custom.ErrorWidget(
          message: 'Fuel record not found',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Record Details'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                EditFuelRecordScreen.routeName,
                arguments: fuelRecord.id,
              );
            },
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _confirmDeleteRecord(fuelRecord);
                  break;
                case 'share':
                  _shareRecord(fuelRecord);
                  break;
                case 'duplicate':
                  _duplicateRecord(fuelRecord);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isDeleting
          ? const LoadingWidget(message: 'Deleting fuel record...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderCard(fuelRecord),
                  const SizedBox(height: 16),
                  _buildFuelDetailsCard(fuelRecord),
                  const SizedBox(height: 16),
                  _buildVehicleInfoCard(fuelRecord),
                  const SizedBox(height: 16),
                  _buildStationInfoCard(fuelRecord),
                  const SizedBox(height: 16),
                  if (fuelRecord.fuelConsumption != null)
                    _buildConsumptionAnalysisCard(fuelRecord),
                  if (fuelRecord.fuelConsumption != null)
                    const SizedBox(height: 16),
                  _buildPaymentInfoCard(fuelRecord),
                  const SizedBox(height: 16),
                  if (fuelRecord.notes != null || fuelRecord.receiptNumber != null)
                    _buildAdditionalInfoCard(fuelRecord),
                  if (fuelRecord.notes != null || fuelRecord.receiptNumber != null)
                    const SizedBox(height: 16),
                  _buildTimestampCard(fuelRecord),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            EditFuelRecordScreen.routeName,
            arguments: fuelRecord.id,
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildHeaderCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Fuel type icon and name
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: record.fuelType.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                record.fuelType.iconData,
                color: record.fuelType.color,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            
            // Vehicle name and date
            Text(
              record.vehicleName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              record.vehicleLicensePlate,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(record.date),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            
            // Main metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Quantity',
                    '${record.quantity.toStringAsFixed(1)}L',
                    Icons.local_gas_station,
                    record.fuelType.color,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total Cost',
                    'Rs ${NumberFormat('#,##0').format(record.totalCost)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Price/L',
                    'Rs ${record.unitPrice.toStringAsFixed(2)}',
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

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  Widget _buildFuelDetailsCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(record.fuelType.iconData, color: record.fuelType.color),
                const SizedBox(width: 8),
                Text(
                  'Fuel Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Fuel Type',
                    record.fuelType.displayName,
                    record.fuelType.iconData,
                    record.fuelType.color,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Odometer',
                    '${NumberFormat('#,##0').format(record.odometer)} km',
                    Icons.speed,
                    Colors.grey[700]!,
                  ),
                ),
              ],
            ),
            
            if (record.distanceTraveled != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Distance Traveled',
                      '${record.distanceTraveled!.toStringAsFixed(0)} km',
                      Icons.route,
                      Colors.purple,
                    ),
                  ),
                  if (record.previousOdometer != null)
                    Expanded(
                      child: _buildDetailItem(
                        'Previous Reading',
                        '${NumberFormat('#,##0').format(record.previousOdometer!)} km',
                        Icons.history,
                        Colors.grey[600]!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Vehicle & Driver',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.vehicleName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        record.vehicleLicensePlate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.driverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationInfoCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Fuel Station',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fuelStationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.location ?? 'Location not available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionAnalysisCard(FuelRecord record) {
    final consumption = record.fuelConsumption!;
    final efficiencyRating = _getEfficiencyRating(consumption);
    
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: efficiencyRating.color),
                const SizedBox(width: 8),
                Text(
                  'Fuel Consumption Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Consumption meter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: efficiencyRating.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: efficiencyRating.color.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        efficiencyRating.iconData,
                        color: efficiencyRating.color,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${consumption.toStringAsFixed(1)} L/100km',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: efficiencyRating.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    efficiencyRating.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: efficiencyRating.color,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Efficiency tips
            _buildEfficiencyTips(efficiencyRating),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyTips(FuelEfficiencyRating rating) {
    List<String> tips = [];
    
    switch (rating) {
      case FuelEfficiencyRating.excellent:
        tips = [
          'Excellent fuel efficiency! Keep up the good work.',
          'Your driving style is very fuel-efficient.',
        ];
        break;
      case FuelEfficiencyRating.good:
        tips = [
          'Good fuel efficiency. Minor improvements possible.',
          'Consider maintaining steady speeds on highways.',
        ];
        break;
      case FuelEfficiencyRating.average:
        tips = [
          'Average fuel efficiency. Room for improvement.',
          'Check tire pressure and reduce idling time.',
          'Consider gentle acceleration and braking.',
        ];
        break;
      case FuelEfficiencyRating.poor:
        tips = [
          'Poor fuel efficiency detected.',
          'Schedule vehicle maintenance check.',
          'Review driving habits and reduce aggressive driving.',
          'Check air filter and tire pressure.',
        ];
        break;
      case FuelEfficiencyRating.terrible:
        tips = [
          'Very poor fuel efficiency - immediate attention required.',
          'Schedule comprehensive vehicle inspection.',
          'Check for engine problems or worn components.',
          'Consider professional driving efficiency training.',
        ];
        break;
      case FuelEfficiencyRating.unknown:
        tips = [
          'Fuel efficiency data is unavailable.',
          'Ensure proper fuel tracking for accurate analysis.',
          'Record odometer readings for consumption calculations.',
        ];
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efficiency Tips:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  color: rating.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  tip,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPaymentInfoCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(record.paymentMethod.iconData, color: record.paymentMethod.color),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Payment Method',
                    record.paymentMethod.displayName,
                    record.paymentMethod.iconData,
                    record.paymentMethod.color,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Unit Price',
                    'Rs ${record.unitPrice.toStringAsFixed(2)}/L',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (record.receiptNumber != null) ...[
              _buildDetailItem(
                'Receipt Number',
                record.receiptNumber!,
                Icons.receipt_long,
                Colors.grey[700]!,
              ),
              if (record.notes != null) const SizedBox(height: 16),
            ],
            
            if (record.notes != null) ...[
              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampCard(FuelRecord record) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Record Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Created',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(record.createdAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Updated',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(record.updatedAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  FuelEfficiencyRating _getEfficiencyRating(double consumption) {
    if (consumption <= 6) return FuelEfficiencyRating.excellent;
    if (consumption <= 8) return FuelEfficiencyRating.good;
    if (consumption <= 12) return FuelEfficiencyRating.average;
    if (consumption <= 16) return FuelEfficiencyRating.poor;
    return FuelEfficiencyRating.terrible;
  }

  Future<void> _confirmDeleteRecord(FuelRecord record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fuel Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this fuel record?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.vehicleName} • ${DateFormat('MMM d, yyyy').format(record.date)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${record.quantity.toStringAsFixed(1)}L • Rs ${NumberFormat('#,##0').format(record.totalCost)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      setState(() {
        _isDeleting = true;
      });

      final success = await ref.read(fuelProvider.notifier).deleteFuelRecord(record.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fuel record deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete fuel record'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _shareRecord(FuelRecord record) {
    final shareText = '''
Fuel Record - ${record.vehicleName}
Date: ${DateFormat('MMM d, yyyy').format(record.date)}
Fuel: ${record.quantity.toStringAsFixed(1)}L ${record.fuelType.displayName}
Cost: Rs ${NumberFormat('#,##0').format(record.totalCost)}
Price/L: Rs ${record.unitPrice.toStringAsFixed(2)}
Station: ${record.fuelStationName}
Odometer: ${NumberFormat('#,##0').format(record.odometer)} km
Payment: ${record.paymentMethod.displayName}
${record.fuelConsumption != null ? 'Consumption: ${record.fuelConsumption!.toStringAsFixed(1)} L/100km' : ''}
${record.notes != null ? '\nNotes: ${record.notes}' : ''}

Generated by Fleet Management System
''';

    // In a real app, you would use a sharing plugin like share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _duplicateRecord(FuelRecord record) {
    // Navigate to add screen with pre-filled data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate functionality would navigate to add screen with pre-filled data'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}