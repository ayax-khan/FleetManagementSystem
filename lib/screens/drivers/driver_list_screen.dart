import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/driver.dart';
import '../../providers/driver_provider.dart';
import 'driver_form_screen.dart';
import 'driver_detail_screen.dart';

class DriverListScreen extends ConsumerStatefulWidget {
  const DriverListScreen({super.key});

  @override
  ConsumerState<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends ConsumerState<DriverListScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DriverStatus? _statusFilter;
  DriverCategory? _categoryFilter;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final driverNotifier = ref.read(driverProvider.notifier);
    final driverStats = ref.watch(driverStatsProvider);
    
    // Filter drivers based on search and filters
    List<Driver> filteredDrivers = driverState.drivers;
    
    if (_searchQuery.isNotEmpty) {
      filteredDrivers = driverNotifier.searchDrivers(_searchQuery);
    }
    
    if (_statusFilter != null) {
      filteredDrivers = filteredDrivers.where((d) => d.status == _statusFilter).toList();
    }
    
    if (_categoryFilter != null) {
      filteredDrivers = filteredDrivers.where((d) => d.category == _categoryFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(driverProvider.notifier).loadDrivers();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export_attendance':
                  _showComingSoonDialog('Export Attendance to Excel');
                  break;
                case 'import_data':
                  _showComingSoonDialog('Import Data from Excel');
                  break;
                case 'license_alerts':
                  _showLicenseAlertsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_attendance',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Export Attendance'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_data',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'license_alerts',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Color(0xFFFF9800)),
                    SizedBox(width: 8),
                    Text('License Alerts'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'All (${driverStats['total']})',
              icon: const Icon(Icons.people, size: 16),
            ),
            Tab(
              text: 'Active (${driverStats['active']})',
              icon: const Icon(Icons.check_circle, size: 16),
            ),
            Tab(
              text: 'On Leave (${driverStats['onLeave']})',
              icon: const Icon(Icons.beach_access, size: 16),
            ),
            Tab(
              text: 'Alerts (${driverStats['expired_licenses']! + driverStats['expiring_soon']!})',
              icon: const Icon(Icons.warning, size: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, employee ID, CNIC, phone...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<DriverStatus?>(
                          value: _statusFilter,
                          hint: const Text(
                            'Status',
                            style: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(),
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value;
                            });
                          },
                          items: [
                            const DropdownMenuItem<DriverStatus?>(
                              value: null,
                              child: Text('All Status'),
                            ),
                            ...DriverStatus.values.map((status) {
                              return DropdownMenuItem<DriverStatus?>(
                                value: status,
                                child: Text('${status.icon} ${status.displayName}'),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Category Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<DriverCategory?>(
                          value: _categoryFilter,
                          hint: const Text(
                            'Category',
                            style: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(),
                          onChanged: (value) {
                            setState(() {
                              _categoryFilter = value;
                            });
                          },
                          items: [
                            const DropdownMenuItem<DriverCategory?>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...DriverCategory.values.map((category) {
                              return DropdownMenuItem<DriverCategory?>(
                                value: category,
                                child: Text('${category.icon} ${category.displayName}'),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDriverList(filteredDrivers, driverState, 'all'),
                _buildDriverList(
                  filteredDrivers.where((d) => d.status == DriverStatus.active).toList(), 
                  driverState, 
                  'active'
                ),
                _buildDriverList(
                  filteredDrivers.where((d) => d.status == DriverStatus.onLeave).toList(), 
                  driverState, 
                  'leave'
                ),
                _buildDriverList(
                  filteredDrivers.where((d) => d.isLicenseExpired || d.isLicenseExpiringSoon).toList(), 
                  driverState, 
                  'alerts'
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverFormScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Driver'),
      ),
    );
  }

  Widget _buildDriverList(List<Driver> drivers, DriverState driverState, String type) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(driverProvider.notifier).loadDrivers();
      },
      child: driverState.isLoading && driverState.drivers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : driverState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        driverState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(driverProvider.notifier).loadDrivers();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getEmptyStateIcon(type),
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyStateMessage(type),
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEmptyStateSubMessage(type),
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        return _DriverCard(
                          driver: driver,
                          onTap: () {
                            ref.read(driverProvider.notifier).selectDriver(driver);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverDetailScreen(driver: driver),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverFormScreen(driver: driver),
                              ),
                            );
                          },
                          onDelete: () {
                            _showDeleteDialog(context, driver);
                          },
                        );
                      },
                    ),
    );
  }

  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'active': return Icons.person_off;
      case 'leave': return Icons.beach_access;
      case 'alerts': return Icons.verified_user;
      default: return Icons.people_outline;
    }
  }

  String _getEmptyStateMessage(String type) {
    switch (type) {
      case 'active': return 'No active drivers';
      case 'leave': return 'No drivers on leave';
      case 'alerts': return 'No license alerts';
      default: return 'No drivers found';
    }
  }

  String _getEmptyStateSubMessage(String type) {
    switch (type) {
      case 'active': return 'All drivers are currently inactive or on leave';
      case 'leave': return 'All drivers are currently active or inactive';
      case 'alerts': return 'All driver licenses are valid and up to date';
      default: return 'Try adjusting your search or filters';
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  void _showDeleteDialog(BuildContext context, Driver driver) {
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

  void _showLicenseAlertsDialog() {
    final expiredDrivers = ref.read(driversWithExpiredLicensesProvider);
    final expiringSoonDrivers = ref.read(driversWithExpiringSoonLicensesProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('License Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expiredDrivers.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Expired Licenses:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
                const SizedBox(height: 8),
                ...expiredDrivers.map((driver) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.error, color: Colors.red, size: 20),
                  title: Text(driver.fullName),
                  subtitle: Text('${driver.employeeId} - Expired on ${driver.licenseExpiryDate.day}/${driver.licenseExpiryDate.month}/${driver.licenseExpiryDate.year}'),
                )),
                const SizedBox(height: 16),
              ],
              if (expiringSoonDrivers.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Expiring Soon:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
                const SizedBox(height: 8),
                ...expiringSoonDrivers.map((driver) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning, color: Colors.orange, size: 20),
                  title: Text(driver.fullName),
                  subtitle: Text('${driver.employeeId} - Expires on ${driver.licenseExpiryDate.day}/${driver.licenseExpiryDate.month}/${driver.licenseExpiryDate.year}'),
                )),
              ],
              if (expiredDrivers.isEmpty && expiringSoonDrivers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('All driver licenses are valid!', style: TextStyle(color: Colors.green)),
                ),
            ],
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature feature will be available soon!\n\nThis will integrate with Google Sheets data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatefulWidget {
  final Driver driver;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DriverCard({
    required this.driver,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _elevationAnimation.value,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFE3F2FD),
                            Colors.white,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Driver Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF1976D2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.driver.firstName[0]}${widget.driver.lastName[0]}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Driver Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.driver.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.driver.employeeId} • ${widget.driver.category.displayName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.driver.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.driver.status.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone Number
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.driver.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Driver Details
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    'License', 
                                    widget.driver.licenseCategory.code,
                                    _getLicenseStatusColor(),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    'Experience', 
                                    '${widget.driver.experienceInYears} years',
                                    const Color(0xFF10B981),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    'Vehicle', 
                                    widget.driver.hasVehicleAssigned ? 'Assigned' : 'None',
                                    widget.driver.hasVehicleAssigned ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Buttons & Alerts
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onEdit,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1565C0),
                                      side: const BorderSide(
                                        color: Color(0xFF1565C0),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: widget.onDelete,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                ),
                                if (widget.driver.isLicenseExpired || widget.driver.isLicenseExpiringSoon) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    widget.driver.isLicenseExpired ? Icons.error : Icons.warning,
                                    color: widget.driver.isLicenseExpired ? Colors.red : Colors.orange,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Color _getLicenseStatusColor() {
    if (widget.driver.isLicenseExpired) return Colors.red;
    if (widget.driver.isLicenseExpiringSoon) return Colors.orange;
    return const Color(0xFF3B82F6);
  }

  Color _getStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.active: return Colors.green;
      case DriverStatus.inactive: return Colors.orange;
      case DriverStatus.suspended: return Colors.red;
      case DriverStatus.onLeave: return Colors.blue;
      case DriverStatus.terminated: return Colors.red.shade800;
    }
  }
}

