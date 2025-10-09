import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          vehicle.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleFormScreen(vehicle: vehicle),
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Edit'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Vehicle Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vehicle.type.icon,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle Name
                    Text(
                      vehicle.fullDisplayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vehicle.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(vehicle.status),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vehicle.status.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicle.status.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(vehicle.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.speed,
                              label: 'Mileage',
                              value: '${vehicle.currentMileage.toStringAsFixed(0)} km',
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.local_gas_station,
                              label: 'Fuel Capacity',
                              value: '${vehicle.fuelCapacity.toStringAsFixed(0)}L',
                              color: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.calendar_today,
                              label: 'Age',
                              value: '${vehicle.ageInYears} years',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Basic Information
                  _buildSectionCard(
                    title: 'Basic Information',
                    icon: Icons.info_outline,
                    children: [
                      _buildDetailRow('Make', vehicle.make),
                      _buildDetailRow('Model', vehicle.model),
                      _buildDetailRow('Year', vehicle.year),
                      _buildDetailRow('Type', '${vehicle.type.icon} ${vehicle.type.displayName}'),
                      _buildDetailRow('Color', vehicle.color),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Identification
                  _buildSectionCard(
                    title: 'Identification',
                    icon: Icons.badge,
                    children: [
                      _buildDetailRow('License Plate', vehicle.licensePlate),
                      _buildDetailRow('VIN', vehicle.vin),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Technical Details
                  _buildSectionCard(
                    title: 'Technical Details',
                    icon: Icons.settings,
                    children: [
                      _buildDetailRow(
                        'Current Mileage', 
                        '${vehicle.currentMileage.toStringAsFixed(1)} km',
                      ),
                      _buildDetailRow(
                        'Fuel Capacity', 
                        '${vehicle.fuelCapacity.toStringAsFixed(1)} L',
                      ),
                      _buildDetailRow('Vehicle Age', '${vehicle.ageInYears} years'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Purchase Information
                  if (vehicle.isPurchased)
                    _buildSectionCard(
                      title: 'Purchase Information',
                      icon: Icons.shopping_cart,
                      children: [
                        if (vehicle.purchaseDate != null)
                          _buildDetailRow(
                            'Purchase Date',
                            DateFormat('MMM dd, yyyy').format(vehicle.purchaseDate!),
                          ),
                        if (vehicle.purchasePrice != null)
                          _buildDetailRow(
                            'Purchase Price',
                            '\$${vehicle.purchasePrice!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  
                  if (vehicle.isPurchased) const SizedBox(height: 16),
                  
                  // Notes
                  if (vehicle.notes != null && vehicle.notes!.isNotEmpty)
                    _buildSectionCard(
                      title: 'Notes',
                      icon: Icons.note,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.notes!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  if (vehicle.notes != null && vehicle.notes!.isNotEmpty)
                    const SizedBox(height: 16),
                  
                  // System Information
                  _buildSectionCard(
                    title: 'System Information',
                    icon: Icons.computer,
                    children: [
                      _buildDetailRow(
                        'Created',
                        DateFormat('MMM dd, yyyy HH:mm').format(vehicle.createdAt),
                      ),
                      _buildDetailRow(
                        'Last Updated',
                        DateFormat('MMM dd, yyyy HH:mm').format(vehicle.updatedAt),
                      ),
                      _buildDetailRow('Vehicle ID', vehicle.id),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleFormScreen(vehicle: vehicle),
            ),
          );
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
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
                Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 20,
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return Colors.green;
      case VehicleStatus.inactive:
        return Colors.orange;
      case VehicleStatus.maintenance:
        return Colors.blue;
      case VehicleStatus.outOfService:
        return Colors.red;
      case VehicleStatus.sold:
        return Colors.purple;
      case VehicleStatus.accident:
        return Colors.red.shade700;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Delete Vehicle',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${vehicle.displayName}?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Close detail screen
                
                final success = await ref.read(vehicleProvider.notifier)
                    .deleteVehicle(vehicle.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                            ? 'Vehicle deleted successfully'
                            : 'Failed to delete vehicle',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}