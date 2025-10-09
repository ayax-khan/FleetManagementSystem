import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import '../../providers/driver_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/debug_utils.dart';
import 'driver_form_screen.dart';

class DriverDetailScreen extends ConsumerWidget {
  final Driver driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final assignedVehicle = driver.vehicleAssigned != null
        ? vehicleState.vehicles.where((v) => v.id == driver.vehicleAssigned).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          driver.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editDriver(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
                case 'copy_info':
                  _copyDriverInfo(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'copy_info',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('Copy Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Driver', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card with Photo and Basic Info
            _buildHeaderCard(),
            
            const SizedBox(height: 16),
            
            // Quick Stats Row
            _buildQuickStatsRow(assignedVehicle),
            
            const SizedBox(height: 16),
            
            // Personal Information
            _buildInfoCard(
              title: 'Personal Information',
              icon: Icons.person,
              children: [
                _buildInfoRow('Full Name', driver.fullName),
                _buildInfoRow('Employee ID', driver.employeeId),
                _buildInfoRow('CNIC', driver.cnic),
                _buildInfoRow('Date of Birth', _formatDate(driver.dateOfBirth)),
                _buildInfoRow('Age', '${_calculateAge(driver.dateOfBirth)} years'),
                _buildInfoRow('Joining Date', _formatDate(driver.joiningDate)),
                _buildInfoRow('Experience', _calculateExperience(driver.joiningDate)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Contact Information
            _buildInfoCard(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                _buildInfoRow('Phone Number', driver.phoneNumber, isClickable: true, onTap: () => _callDriver(driver.phoneNumber)),
                if (driver.email != null)
                  _buildInfoRow('Email', driver.email!, isClickable: true, onTap: () => _emailDriver(driver.email!)),
                _buildInfoRow('Address', driver.address),
                if (driver.emergencyContactName != null)
                  _buildInfoRow('Emergency Contact', driver.emergencyContactName!),
                if (driver.emergencyContactNumber != null)
                  _buildInfoRow('Emergency Number', driver.emergencyContactNumber!, isClickable: true, onTap: () => _callDriver(driver.emergencyContactNumber!)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Employment Details
            _buildInfoCard(
              title: 'Employment Details',
              icon: Icons.work,
              children: [
                _buildStatusRow('Status', driver.status.displayName, driver.status.color, driver.status.icon),
                _buildStatusRow('Category', driver.category.displayName, driver.category.color, driver.category.icon),
                _buildInfoRow('Basic Salary', 'PKR ${_formatCurrency(driver.basicSalary)}'),
                if (driver.notes != null)
                  _buildInfoRow('Notes', driver.notes!),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // License Information
            _buildInfoCard(
              title: 'License Information',
              icon: Icons.credit_card,
              children: [
                _buildInfoRow('License Number', driver.licenseNumber),
                _buildStatusRow('License Category', driver.licenseCategory.displayName, driver.licenseCategory.color, driver.licenseCategory.icon),
                _buildInfoRow('Expiry Date', _formatDate(driver.licenseExpiryDate)),
                _buildExpiryStatusRow(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Vehicle Assignment
            _buildInfoCard(
              title: 'Vehicle Assignment',
              icon: Icons.directions_car,
              children: [
                if (assignedVehicle != null) ...[
                  _buildInfoRow('Vehicle', '${assignedVehicle.make} ${assignedVehicle.model}'),
                  _buildInfoRow('License Plate', assignedVehicle.licensePlate),
                  _buildInfoRow('Year', assignedVehicle.year.toString()),
                  _buildStatusRow('Vehicle Status', assignedVehicle.status.displayName, assignedVehicle.status.color, assignedVehicle.status.icon),
                ] else ...[
                  _buildInfoRow('Vehicle Assignment', 'No vehicle assigned'),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // System Information
            _buildInfoCard(
              title: 'System Information',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Created', _formatDateTime(driver.createdAt)),
                _buildInfoRow('Last Updated', _formatDateTime(driver.updatedAt)),
                _buildInfoRow('Driver ID', driver.id),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editDriver(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Driver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callDriver(driver.phoneNumber),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Driver'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1565C0),
              const Color(0xFF1976D2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Name and Employee ID
              Text(
                driver.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'ID: ${driver.employeeId}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: driver.status.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(driver.status.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      driver.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(Vehicle? assignedVehicle) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Experience',
            _calculateExperience(driver.joiningDate),
            Icons.timeline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'License',
            _isLicenseValid() ? 'Valid' : 'Expired',
            Icons.credit_card,
            _isLicenseValid() ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Vehicle',
            assignedVehicle != null ? 'Assigned' : 'None',
            Icons.directions_car,
            assignedVehicle != null ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
                ),
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

  Widget _buildInfoRow(String label, String value, {bool isClickable = false, VoidCallback? onTap}) {
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isClickable && onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, String emoji) {
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryStatusRow() {
    final isExpired = driver.licenseExpiryDate.isBefore(DateTime.now());
    final daysUntilExpiry = driver.licenseExpiryDate.difference(DateTime.now()).inDays;
    
    String statusText;
    Color statusColor;
    String statusIcon;
    
    if (isExpired) {
      statusText = 'Expired ${(-daysUntilExpiry)} days ago';
      statusColor = Colors.red;
      statusIcon = '🚫';
    } else if (daysUntilExpiry <= 30) {
      statusText = 'Expires in $daysUntilExpiry days';
      statusColor = Colors.orange;
      statusIcon = '⚠️';
    } else {
      statusText = 'Valid for $daysUntilExpiry days';
      statusColor = Colors.green;
      statusIcon = '✅';
    }

    return _buildStatusRow('License Status', statusText, statusColor, statusIcon);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _calculateExperience(DateTime joiningDate) {
    final now = DateTime.now();
    final difference = now.difference(joiningDate);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }

  bool _isLicenseValid() {
    return driver.licenseExpiryDate.isAfter(DateTime.now());
  }

  void _editDriver(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverFormScreen(driver: driver),
      ),
    );
  }

  void _callDriver(String phoneNumber) {
    DebugUtils.log('Calling driver: $phoneNumber', 'DRIVER_DETAIL');
    // In a real app, this would use url_launcher to make a phone call
    // launch('tel:$phoneNumber');
  }

  void _emailDriver(String email) {
    DebugUtils.log('Emailing driver: $email', 'DRIVER_DETAIL');
    // In a real app, this would use url_launcher to send an email
    // launch('mailto:$email');
  }

  void _copyDriverInfo(BuildContext context) {
    final info = '''
Driver Information:
Name: ${driver.fullName}
Employee ID: ${driver.employeeId}
CNIC: ${driver.cnic}
Phone: ${driver.phoneNumber}
${driver.email != null ? 'Email: ${driver.email}' : ''}
Address: ${driver.address}
Status: ${driver.status.displayName}
Category: ${driver.category.displayName}
License: ${driver.licenseNumber} (${driver.licenseCategory.displayName})
License Expiry: ${_formatDate(driver.licenseExpiryDate)}
Basic Salary: PKR ${_formatCurrency(driver.basicSalary)}
''';

    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver information copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Driver', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${driver.fullName} (${driver.employeeId})?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Close detail screen
                
                final success = await ref.read(driverProvider.notifier).deleteDriver(driver.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Driver deleted successfully' : 'Failed to delete driver'),
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