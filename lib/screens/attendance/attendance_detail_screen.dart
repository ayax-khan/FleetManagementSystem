import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/debug_utils.dart';

class AttendanceDetailScreen extends ConsumerWidget {
  final Attendance attendance;

  const AttendanceDetailScreen({super.key, required this.attendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attendance.driverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editAttendance(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
                case 'mark_overtime':
                  _toggleOvertimeStatus(context, ref);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'mark_overtime',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('Toggle Overtime'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Record', style: TextStyle(color: Colors.red)),
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
            // Header Card with Status
            _buildHeaderCard(),
            
            const SizedBox(height: 16),
            
            // Time Overview Card
            _buildTimeOverviewCard(),
            
            const SizedBox(height: 16),
            
            // Check-in Information
            _buildInfoCard(
              'Check-in Information',
              Icons.login,
              [
                _buildInfoRow('Time', attendance.checkInTimeFormatted),
                if (attendance.checkInLocation != null)
                  _buildInfoRow('Location', attendance.checkInLocation!),
                if (attendance.checkInPhoto != null)
                  _buildInfoRow('Photo', 'Available', 
                    trailing: TextButton(
                      onPressed: () => _viewPhoto(context, attendance.checkInPhoto!),
                      child: const Text('View'),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Check-out Information
            _buildInfoCard(
              'Check-out Information',
              Icons.logout,
              [
                _buildInfoRow('Time', attendance.checkOutTimeFormatted),
                if (attendance.checkOutLocation != null)
                  _buildInfoRow('Location', attendance.checkOutLocation!),
                if (attendance.checkOutPhoto != null)
                  _buildInfoRow('Photo', 'Available',
                    trailing: TextButton(
                      onPressed: () => _viewPhoto(context, attendance.checkOutPhoto!),
                      child: const Text('View'),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Working Hours Breakdown
            _buildInfoCard(
              'Working Hours Breakdown',
              Icons.schedule,
              [
                _buildInfoRow('Total Hours', attendance.workingTimeFormatted),
                _buildInfoRow('Regular Hours', '${attendance.calculatedRegularHours.toStringAsFixed(2)} hrs'),
                _buildInfoRow('Overtime Hours', '${attendance.calculatedOvertimeHours.toStringAsFixed(2)} hrs'),
                if (attendance.totalEarnings != null)
                  _buildInfoRow('Total Earnings', 'PKR ${_formatCurrency(attendance.totalEarnings!)}'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional Information
            _buildInfoCard(
              'Additional Information',
              Icons.info_outline,
              [
                _buildInfoRow('Employee ID', attendance.driverEmployeeId),
                _buildInfoRow('Date', attendance.formattedDate),
                _buildStatusRow('Status', attendance.status.displayName, attendance.status.color, attendance.status.icon),
                if (attendance.notes != null)
                  _buildInfoRow('Notes', attendance.notes!),
                _buildInfoRow('Created', _formatDateTime(attendance.createdAt)),
                _buildInfoRow('Last Updated', _formatDateTime(attendance.updatedAt)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAttendance(context, ref),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Record'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateReport(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Generate Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
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
              attendance.status.color,
              attendance.status.color.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Driver Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    attendance.driverName.split(' ').map((n) => n[0]).join(''),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Driver Name and ID
              Text(
                attendance.driverName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'ID: ${attendance.driverEmployeeId} • ${attendance.formattedDate}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attendance.status.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      attendance.statusDisplayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  Widget _buildTimeOverviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Time Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTimeStatCard(
                    'Check In',
                    attendance.checkInTimeFormatted,
                    Icons.login,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeStatCard(
                    'Check Out',
                    attendance.checkOutTimeFormatted,
                    Icons.logout,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeStat('Total', attendance.workingTimeFormatted, Colors.blue),
                  _buildTimeStat('Regular', '${attendance.calculatedRegularHours.toStringAsFixed(1)}h', Colors.green),
                  _buildTimeStat('Overtime', '${attendance.calculatedOvertimeHours.toStringAsFixed(1)}h', 
                    attendance.calculatedOvertimeHours > 0 ? Colors.orange : Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null) trailing,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _editAttendance(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to edit attendance screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be implemented soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewPhoto(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Photo'),
        content: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('Photo Preview', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('(Feature coming soon)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleOvertimeStatus(BuildContext context, WidgetRef ref) {
    final hasOvertime = attendance.calculatedOvertimeHours > 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasOvertime ? 'Remove Overtime Status' : 'Mark as Overtime'),
        content: Text(
          hasOvertime 
              ? 'This will remove the overtime status from this attendance record.'
              : 'This will mark this attendance record as overtime work.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement overtime status toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(hasOvertime ? 'Overtime status removed' : 'Marked as overtime'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Generate Report'),
          ],
        ),
        content: const Text('Select report format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF report generation will be available soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Excel export will be available soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Excel'),
          ),
        ],
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
              Text('Delete Attendance Record', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this attendance record for ${attendance.driverName}?\n\nDate: ${attendance.formattedDate}\n\nThis action cannot be undone.',
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
                
                final success = await ref.read(attendanceProvider.notifier).deleteAttendance(attendance.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Attendance record deleted successfully' : 'Failed to delete attendance record'),
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