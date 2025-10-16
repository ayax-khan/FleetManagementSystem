import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import '../../providers/driver_provider.dart';
import '../../providers/vehicle_provider.dart';
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
  final Set<String> _selectedDriverIds = {};
  bool _isSelectionMode = false;

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
                            // Only show the required categories
                            ...[DriverCategory.transportOfficial, 
                                DriverCategory.generalDrivers,
                                DriverCategory.shiftDrivers,
                                DriverCategory.entitledDrivers].map((category) {
                              return DropdownMenuItem<DriverCategory?>(
                                value: category,
                                child: Text('${category.icon} ${category.displayName}'),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Add Category Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _showAddCategoryDialog(),
                          borderRadius: BorderRadius.circular(8),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Add Category',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
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
      floatingActionButton: _isSelectionMode && _selectedDriverIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkDeleteDialog(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.delete_sweep),
              label: Text('Delete ${_selectedDriverIds.length}'),
            )
          : FloatingActionButton.extended(
              onPressed: _categoryFilter != null ? () => _showAddDriverDialog(_categoryFilter!) : null,
              backgroundColor: _categoryFilter != null ? const Color(0xFF1565C0) : Colors.grey,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(_categoryFilter != null ? 'Add Driver' : 'Select Category First'),
            ),
    );
  }

  Widget _buildDriverList(List<Driver> drivers, DriverState driverState, String type) {
    return Column(
      children: [
        // Selection Controls
        if (drivers.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSelectionMode)
                  Text(
                    '${drivers.length} driver(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  )
                else
                  Text(
                    '${_selectedDriverIds.length} selected',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                Row(
                  children: [
                    if (!_isSelectionMode)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = true;
                          });
                        },
                        icon: const Icon(Icons.checklist, size: 18),
                        label: const Text('Select'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                        ),
                      ),
                    if (_isSelectionMode) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_selectedDriverIds.length == drivers.length) {
                              _selectedDriverIds.clear();
                            } else {
                              _selectedDriverIds.addAll(drivers.map((d) => d.id));
                            }
                          });
                        },
                        icon: Icon(
                          _selectedDriverIds.length == drivers.length
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                        ),
                        label: const Text('Select All'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedDriverIds.clear();
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
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
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        final isSelected = _selectedDriverIds.contains(driver.id);
                        return _DriverCard(
                          driver: driver,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedDriverIds.remove(driver.id);
                                } else {
                                  _selectedDriverIds.add(driver.id);
                                }
                              });
                            } else {
                              ref.read(driverProvider.notifier).selectDriver(driver);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverDetailScreen(driver: driver),
                                ),
                              );
                            }
                          },
                          onEdit: () {
                            _showEditDriverDialog(driver);
                          },
                          onDelete: () {
                            _showDeleteDialog(context, driver);
                          },
                        );
                      },
                    ),
          ),
        ),
      ],
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
    if (width > 1400) return 4;  // 4 cards on very large screens
    if (width > 1000) return 3;  // 3 cards on large screens
    if (width > 600) return 2;   // 2 cards on medium screens
    return 1;                    // 1 card on small screens
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
  
  void _showAddCategoryDialog() {
    final TextEditingController categoryNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Add New Category', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name for the new driver category:'),
            const SizedBox(height: 16),
            TextField(
              controller: categoryNameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., VIP Drivers',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final categoryName = categoryNameController.text.trim();
              if (categoryName.isNotEmpty) {
                // TODO: Add custom category logic
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$categoryName" will be added in the next update!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }
  
  void _showAddDriverDialog(DriverCategory selectedCategory) {
    showDialog(
      context: context,
      builder: (context) => _AddDriverDialog(selectedCategory: selectedCategory),
    );
  }
  
  void _showEditDriverDialog(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => _EditDriverDialog(driver: driver),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                'Delete Multiple Drivers',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${_selectedDriverIds.length} driver(s)?\n\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Deleting drivers...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                }

                int successCount = 0;
                final driverNotifier = ref.read(driverProvider.notifier);
                
                for (final driverId in _selectedDriverIds) {
                  final success = await driverNotifier.deleteDriver(driverId);
                  if (success) successCount++;
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        successCount == _selectedDriverIds.length
                            ? 'Successfully deleted $successCount driver(s)'
                            : 'Deleted $successCount of ${_selectedDriverIds.length} driver(s)',
                      ),
                      backgroundColor:
                          successCount == _selectedDriverIds.length
                              ? Colors.green
                              : Colors.orange,
                    ),
                  );

                  setState(() {
                    _selectedDriverIds.clear();
                    _isSelectionMode = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}

// Edit Driver Dialog (similar style to Add Driver Dialog)
class _EditDriverDialog extends ConsumerStatefulWidget {
  final Driver driver;

  const _EditDriverDialog({required this.driver});

  @override
  ConsumerState<_EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends ConsumerState<_EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _basicSalaryController = TextEditingController();
  
  LicenseCategory _selectedLicenseCategory = LicenseCategory.lightVehicle;
  DateTime? _joiningDate;
  DateTime? _licenseExpiryDate;
  String? _selectedVehicleId;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateFormWithDriverData();
  }
  
  void _populateFormWithDriverData() {
    final driver = widget.driver;
    _firstNameController.text = driver.firstName;
    _lastNameController.text = driver.lastName;
    _cnicController.text = driver.cnic;
    _phoneController.text = driver.phoneNumber;
    _addressController.text = driver.address;
    _licenseNumberController.text = driver.licenseNumber;
    _basicSalaryController.text = driver.basicSalary.toString();
    
    _selectedLicenseCategory = driver.licenseCategory;
    _joiningDate = driver.joiningDate;
    _licenseExpiryDate = driver.licenseExpiryDate;
    _selectedVehicleId = driver.vehicleAssigned;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _basicSalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Driver',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Employee ID: ${widget.driver.employeeId} • ${widget.driver.category.displayName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cnicController,
                              label: 'CNIC',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Employment Details
                      const Text(
                        'Employment Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectJoiningDate(),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Joining Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _joiningDate != null
                                      ? '${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}'
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _basicSalaryController,
                              label: 'Basic Salary (PKR)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final salary = double.tryParse(value);
                                if (salary == null || salary <= 0) {
                                  return 'Invalid salary';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // License Information
                      const Text(
                        'License Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _licenseNumberController,
                              label: 'License Number',
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField<LicenseCategory>(
                              label: 'License Category',
                              value: _selectedLicenseCategory,
                              items: LicenseCategory.values,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLicenseCategory = value!;
                                });
                              },
                              itemBuilder: (category) => Row(
                                children: [
                                  Text(category.icon),
                                  const SizedBox(width: 8),
                                  Text(category.displayName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: () => _selectLicenseExpiryDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'License Expiry Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _licenseExpiryDate != null
                                ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                                : 'Select expiry date',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Vehicle Assignment (Optional)
                      const Text(
                        'Vehicle Assignment (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDropdownField<String?>(
                        label: 'Assigned Vehicle',
                        value: _selectedVehicleId,
                        items: [null, ...vehicleState.vehicles.where((v) => v.status == VehicleStatus.active).map((v) => v.id)],
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                        itemBuilder: (vehicleId) {
                          if (vehicleId == null) {
                            return const Text('No Vehicle Assigned');
                          }
                          final vehicle = vehicleState.vehicles.firstWhere((v) => v.id == vehicleId);
                          return Text('${vehicle.make} ${vehicle.model} (${vehicle.licensePlate})');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateDriver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Update Driver',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectJoiningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _joiningDate = date;
      });
    }
  }

  Future<void> _selectLicenseExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 1095)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() {
        _licenseExpiryDate = date;
      });
    }
  }

  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_joiningDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select joining date'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_licenseExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select license expiry date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedDriver = widget.driver.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        cnic: _cnicController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        joiningDate: _joiningDate!,
        licenseNumber: _licenseNumberController.text.trim().toUpperCase(),
        licenseCategory: _selectedLicenseCategory,
        licenseExpiryDate: _licenseExpiryDate!,
        basicSalary: double.parse(_basicSalaryController.text.trim()),
        vehicleAssigned: _selectedVehicleId,
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(driverProvider.notifier).updateDriver(updatedDriver);

      if (success && mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating driver: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _DriverCard extends StatefulWidget {
  final Driver driver;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const _DriverCard({
    required this.driver,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
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
                child: Container(
                  decoration: widget.isSelected
                      ? BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1565C0),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        )
                      : null,
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
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Checkbox in selection mode
                          if (widget.isSelectionMode) ...[
                            Checkbox(
                              value: widget.isSelected,
                              onChanged: (_) => widget.onTap(),
                              activeColor: const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Driver Avatar
                          Container(
                            width: 40,
                            height: 40,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 10),
                          
                          // Driver Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.driver.fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.driver.employeeId} • ${widget.driver.category.displayName}',
                                  style: const TextStyle(
                                    fontSize: 11,
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
                              horizontal: 6, 
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.driver.status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.driver.status.displayName,
                              style: const TextStyle(
                                fontSize: 9,
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone Number
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.driver.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Driver Details
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    'License', 
                                    widget.driver.licenseCategory.code,
                                    _getLicenseStatusColor(),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDetailRow(
                                    'Experience', 
                                    '${widget.driver.experienceInYears} yrs',
                                    const Color(0xFF10B981),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDetailRow(
                                    'Vehicle', 
                                    widget.driver.hasVehicleAssigned ? 'Yes' : 'None',
                                    widget.driver.hasVehicleAssigned ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Buttons & Alerts (hidden in selection mode)
                            if (!widget.isSelectionMode) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: widget.onEdit,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                      ),
                                      label: const Text('Edit', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF1565C0),
                                        side: const BorderSide(
                                          color: Color(0xFF1565C0),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    onPressed: widget.onDelete,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                    ),
                                  ),
                                  if (widget.driver.isLicenseExpired || widget.driver.isLicenseExpiringSoon) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      widget.driver.isLicenseExpired ? Icons.error : Icons.warning,
                                      color: widget.driver.isLicenseExpired ? Colors.red : Colors.orange,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ],
                  ),
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
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
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

// Simplified Add Driver Dialog
class _AddDriverDialog extends ConsumerStatefulWidget {
  final DriverCategory selectedCategory;

  const _AddDriverDialog({required this.selectedCategory});

  @override
  ConsumerState<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends ConsumerState<_AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _basicSalaryController = TextEditingController();
  
  LicenseCategory _selectedLicenseCategory = LicenseCategory.lightVehicle;
  DateTime? _joiningDate;
  DateTime? _licenseExpiryDate;
  String? _selectedVehicleId;
  
  bool _isLoading = false;
  String? _generatedEmployeeId;

  @override
  void initState() {
    super.initState();
    _joiningDate = DateTime.now();
    _generateEmployeeId();
  }

  void _generateEmployeeId() {
    // Generate employee ID based on category
    final driverState = ref.read(driverProvider);
    final categoryDrivers = driverState.drivers
        .where((d) => d.category == widget.selectedCategory)
        .toList();
    
    String prefix;
    switch (widget.selectedCategory) {
      case DriverCategory.transportOfficial:
        prefix = 'TO';
        break;
      case DriverCategory.generalDrivers:
        prefix = 'GD';
        break;
      case DriverCategory.shiftDrivers:
        prefix = 'SD';
        break;
      case DriverCategory.entitledDrivers:
        prefix = 'ED';
        break;
      default:
        prefix = 'DR';
    }
    
    // Find the highest existing number for this category
    int maxNumber = 0;
    final prefixLength = prefix.length;
    
    for (final driver in categoryDrivers) {
      final employeeId = driver.employeeId;
      if (employeeId.startsWith(prefix) && employeeId.length > prefixLength) {
        final numberPart = employeeId.substring(prefixLength);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    final nextNumber = maxNumber + 1;
    _generatedEmployeeId = '$prefix${nextNumber.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _basicSalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Driver',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Category: ${widget.selectedCategory.displayName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto-generated Employee ID display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge, color: Color(0xFF1565C0)),
                            const SizedBox(width: 8),
                            const Text('Employee ID: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              _generatedEmployeeId ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Personal Information
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cnicController,
                              label: 'CNIC',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Employment Details
                      const Text(
                        'Employment Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectJoiningDate(),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Joining Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _joiningDate != null
                                      ? '${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}'
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _basicSalaryController,
                              label: 'Basic Salary (PKR)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final salary = double.tryParse(value);
                                if (salary == null || salary <= 0) {
                                  return 'Invalid salary';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // License Information
                      const Text(
                        'License Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _licenseNumberController,
                              label: 'License Number',
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField<LicenseCategory>(
                              label: 'License Category',
                              value: _selectedLicenseCategory,
                              items: LicenseCategory.values,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLicenseCategory = value!;
                                });
                              },
                              itemBuilder: (category) => Row(
                                children: [
                                  Text(category.icon),
                                  const SizedBox(width: 8),
                                  Text(category.displayName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: () => _selectLicenseExpiryDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'License Expiry Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _licenseExpiryDate != null
                                ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                                : 'Select expiry date',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Vehicle Assignment (Optional)
                      const Text(
                        'Vehicle Assignment (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDropdownField<String?>(
                        label: 'Assigned Vehicle',
                        value: _selectedVehicleId,
                        items: [null, ...vehicleState.vehicles.where((v) => v.status == VehicleStatus.active).map((v) => v.id)],
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                        itemBuilder: (vehicleId) {
                          if (vehicleId == null) {
                            return const Text('No Vehicle Assigned');
                          }
                          final vehicle = vehicleState.vehicles.firstWhere((v) => v.id == vehicleId);
                          return Text('${vehicle.make} ${vehicle.model} (${vehicle.licensePlate})');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDriver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Add Driver',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectJoiningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _joiningDate = date;
      });
    }
  }

  Future<void> _selectLicenseExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 1095)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() {
        _licenseExpiryDate = date;
      });
    }
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_joiningDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select joining date'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_licenseExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select license expiry date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final driver = Driver(
        id: '', // Will be generated by provider
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeId: _generatedEmployeeId!,
        cnic: _cnicController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: null, // Not collected in simplified form
        address: _addressController.text.trim(),
        dateOfBirth: DateTime.now().subtract(const Duration(days: 9000)), // Default age ~25
        joiningDate: _joiningDate!,
        status: DriverStatus.active, // Default to active
        category: widget.selectedCategory,
        licenseNumber: _licenseNumberController.text.trim().toUpperCase(),
        licenseCategory: _selectedLicenseCategory,
        licenseExpiryDate: _licenseExpiryDate!,
        basicSalary: double.parse(_basicSalaryController.text.trim()),
        vehicleAssigned: _selectedVehicleId,
        emergencyContactName: null, // Not collected in simplified form
        emergencyContactNumber: null, // Not collected in simplified form
        notes: null, // Not collected in simplified form
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(driverProvider.notifier).addDriver(driver);

      if (success && mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding driver: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

