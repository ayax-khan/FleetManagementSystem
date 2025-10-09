import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../common/app_card.dart';

class FuelRecordCard extends StatelessWidget {
  final FuelRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FuelRecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Fuel type icon with color
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: record.fuelType.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    record.fuelType.iconData,
                    color: record.fuelType.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Vehicle and date info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.vehicleName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${record.vehicleLicensePlate} • ${DateFormat('MMM d, yyyy').format(record.date)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions menu
                if (onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
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
            
            const SizedBox(height: 16),
            
            // Fuel details row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Quantity',
                    '${record.quantity.toStringAsFixed(1)}L',
                    Icons.local_gas_station,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Total Cost',
                    'Rs ${NumberFormat('#,##0').format(record.totalCost)}',
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Price/L',
                    'Rs ${record.unitPrice.toStringAsFixed(2)}',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Station and driver info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.fuelStationName,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.driverName,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Payment method chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: record.paymentMethod.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.paymentMethod.iconData,
                        size: 12,
                        color: record.paymentMethod.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.paymentMethod.displayName,
                        style: TextStyle(
                          color: record.paymentMethod.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Consumption info if available
            if (record.fuelConsumption != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getConsumptionColor(record.fuelConsumption!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getConsumptionColor(record.fuelConsumption!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 16,
                      color: _getConsumptionColor(record.fuelConsumption!),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Consumption: ${record.fuelConsumption!.toStringAsFixed(1)}L/100km',
                      style: TextStyle(
                        color: _getConsumptionColor(record.fuelConsumption!),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (record.distanceTraveled != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${record.distanceTraveled!.toStringAsFixed(0)} km traveled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Odometer info
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.speed,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Odometer: ${NumberFormat('#,##0').format(record.odometer)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (record.receiptNumber != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.receipt,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Receipt: ${record.receiptNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            
            // Notes if available
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getConsumptionColor(double consumption) {
    if (consumption <= 6) return Colors.green;
    if (consumption <= 8) return Colors.orange;
    if (consumption <= 12) return Colors.red;
    return Colors.red.shade800;
  }
}