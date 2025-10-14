import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/job.dart';

class JobDetailDialog extends StatelessWidget {
  final Job job;
  
  const JobDetailDialog({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    job.isPending ? Icons.pending_actions : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Job Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  job.status.icon,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  job.status.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Job ID: ${job.jobId}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context, job.jobId),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Vehicle and Driver Info
                    _buildInfoCard(
                      title: 'Assignment Details',
                      icon: Icons.assignment,
                      color: const Color(0xFF1565C0),
                      children: [
                        _buildInfoRow(
                          icon: Icons.directions_car,
                          label: 'Vehicle',
                          value: job.vehicleName,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Driver',
                          value: job.driverName,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trip Details
                    _buildInfoCard(
                      title: 'Trip Information',
                      icon: Icons.route,
                      color: Colors.purple,
                      children: [
                        _buildInfoRow(
                          icon: Icons.route,
                          label: 'Route',
                          value: job.route,
                          isMultiline: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.business_center,
                          label: 'Purpose',
                          value: job.purpose,
                          isMultiline: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Time Information
                    _buildInfoCard(
                      title: 'Time Information',
                      icon: Icons.access_time,
                      color: Colors.orange,
                      children: [
                        _buildInfoRow(
                          icon: Icons.logout,
                          label: 'Departure Time',
                          value: job.formattedTimeOut,
                        ),
                        if (job.isCompleted) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.login,
                            label: 'Return Time',
                            value: job.formattedTimeIn,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.timer,
                            label: 'Duration',
                            value: job.formattedDuration,
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Odometer Information
                    _buildInfoCard(
                      title: 'Distance & Fuel',
                      icon: Icons.speed,
                      color: Colors.green,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Odometer Out',
                                value: '${job.startingMeterReading.toStringAsFixed(1)} km',
                                icon: Icons.logout,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (job.isCompleted)
                              Expanded(
                                child: _buildStatCard(
                                  label: 'Odometer In',
                                  value: '${job.endingMeterReading!.toStringAsFixed(1)} km',
                                  icon: Icons.login,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        
                        if (job.isCompleted) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  label: 'Total Distance',
                                  value: job.formattedTotalKm,
                                  icon: Icons.straighten,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  label: 'Fuel Used',
                                  value: job.formattedFuelUsed,
                                  icon: Icons.local_gas_station,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.eco, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fuel Efficiency',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.formattedFuelEfficiency,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return const Color(0xFFf59e0b); // Orange
      case JobStatus.completed:
        return const Color(0xFF10b981); // Green
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job ID "$text" copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}