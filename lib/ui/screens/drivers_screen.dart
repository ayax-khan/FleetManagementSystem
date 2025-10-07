// lib/ui/screens/drivers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/driver_repo.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import '../../repositories/vehicle_repo.dart';
import '../../core/utils/validators.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({Key? key}) : super(key: key);

  @override
  _DriversScreenState createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final DriverRepo _driverRepo = DriverRepo();
  final VehicleRepo _vehicleRepo = VehicleRepo();

  List<Driver> _drivers = [];
  List<Driver> _filteredDrivers = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all';
  Driver? _editingDriver;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _licenseExpiry;
  DateTime? _joiningDate;
  String? _selectedStatus;
  String? _selectedVehicle;

  final List<String> _statusOptions = ['active', 'on_leave', 'inactive'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _drivers = await _driverRepo.getAllDrivers();
      _vehicles = await _vehicleRepo.getAllVehicles();
      _applyFilters();
    } catch (e) {
      _showSnackBar('Failed to load drivers: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var filtered = _drivers;

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered
          .where((driver) => driver.status == _filterStatus)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((driver) {
        return driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            driver.employeeId?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true ||
            driver.licenseNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            driver.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                true;
      }).toList();
    }

    setState(() => _filteredDrivers = filtered);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddEditDialog({Driver? driver}) {
    _editingDriver = driver;

    // Initialize form fields
    if (driver != null) {
      _nameController.text = driver.name;
      _employeeIdController.text = driver.employeeId ?? '';
      _licenseController.text = driver.licenseNumber;
      _phoneController.text = driver.phone ?? '';
      _emergencyContactController.text = driver.emergencyContact ?? '';
      _addressController.text = driver.address ?? '';
      _licenseExpiry = driver.licenseExpiry;
      _joiningDate = driver.joiningDate;
      _selectedStatus = driver.status;
      _selectedVehicle = driver.assignedVehicle;
    } else {
      _nameController.clear();
      _employeeIdController.clear();
      _licenseController.clear();
      _phoneController.clear();
      _emergencyContactController.clear();
      _addressController.clear();
      _licenseExpiry = null;
      _joiningDate = null;
      _selectedStatus = 'active';
      _selectedVehicle = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _editingDriver == null ? 'Add Driver' : 'Edit Driver',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          Validators.requiredField(value, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          Validators.requiredField(value, 'License Number'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !Validators.isValidPhone(value)) {
                                return 'Invalid phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emergencyContactController,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Contact',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_capitalize(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedStatus = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicle,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No Vehicle Assigned'),
                        ),
                        ..._vehicles.where((v) => v.status == 'active').map((
                          vehicle,
                        ) {
                          return DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.registrationNumber} - ${vehicle.makeType}',
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedVehicle = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Assigned Vehicle',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _licenseExpiry == null
                            ? 'License Expiry Date'
                            : 'License Expiry: ${DateFormat('yyyy-MM-dd').format(_licenseExpiry!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _licenseExpiry ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => _licenseExpiry = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        _joiningDate == null
                            ? 'Joining Date'
                            : 'Joining Date: ${DateFormat('yyyy-MM-dd').format(_joiningDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _joiningDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => _joiningDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveDriver(setDialogState),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDriver(Function setDialogState) async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name is required', isError: true);
      return;
    }
    if (_licenseController.text.trim().isEmpty) {
      _showSnackBar('License number is required', isError: true);
      return;
    }
    if (!Validators.isValidLicenseNumber(_licenseController.text.trim())) {
      _showSnackBar('Invalid license number format', isError: true);
      return;
    }

    try {
      final driver = Driver(
        id: _editingDriver?.id,
        name: _nameController.text.trim(),
        employeeId: _employeeIdController.text.trim().isEmpty
            ? null
            : _employeeIdController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        licenseExpiry: _licenseExpiry,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        status: _selectedStatus ?? 'active',
        assignedVehicle: _selectedVehicle,
        joiningDate: _joiningDate,
      );

      if (_editingDriver == null) {
        await _driverRepo.addDriver(driver);
        _showSnackBar('Driver added successfully');
      } else {
        await _driverRepo.updateDriver(_editingDriver!.id!, driver);
        _showSnackBar('Driver updated successfully');
      }

      _clearForm();
      Navigator.pop(context);
      await _loadData();
    } catch (e) {
      _showSnackBar('Failed to save driver: $e', isError: true);
    }
  }

  void _clearForm() {
    _editingDriver = null;
    _nameController.clear();
    _employeeIdController.clear();
    _licenseController.clear();
    _phoneController.clear();
    _emergencyContactController.clear();
    _addressController.clear();
    _licenseExpiry = null;
    _joiningDate = null;
    _selectedStatus = 'active';
    _selectedVehicle = null;
  }

  Future<void> _deleteDriver(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this driver? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _driverRepo.deleteDriver(id);
        _showSnackBar('Driver deleted successfully');
        await _loadData();
      } catch (e) {
        _showSnackBar('Failed to delete driver: $e', isError: true);
      }
    }
  }

  void _showDriverDetails(Driver driver) {
    final assignedVehicle = _vehicles.firstWhere(
      (v) => v.id == driver.assignedVehicle,
      orElse: () => Vehicle(
        id: '',
        registrationNumber: 'Not Assigned',
        makeType: '',
        status: 'active',
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Employee ID', driver.employeeId ?? 'N/A'),
              _buildDetailItem('License Number', driver.licenseNumber),
              _buildDetailItem(
                'License Expiry',
                driver.licenseExpiry != null
                    ? DateFormat('yyyy-MM-dd').format(driver.licenseExpiry!)
                    : 'Not set',
              ),
              _buildDetailItem('Phone', driver.phone ?? 'N/A'),
              _buildDetailItem(
                'Emergency Contact',
                driver.emergencyContact ?? 'N/A',
              ),
              _buildDetailItem('Address', driver.address ?? 'N/A'),
              _buildDetailItem(
                'Joining Date',
                driver.joiningDate != null
                    ? DateFormat('yyyy-MM-dd').format(driver.joiningDate!)
                    : 'Not set',
              ),
              _buildDetailItem('Status', _capitalize(driver.status)),
              _buildDetailItem(
                'Assigned Vehicle',
                '${assignedVehicle.registrationNumber} - ${assignedVehicle.makeType}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'on_leave':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatsCard() {
    final total = _drivers.length;
    final active = _drivers.where((d) => d.status == 'active').length;
    final onLeave = _drivers.where((d) => d.status == 'on_leave').length;
    final assigned = _drivers.where((d) => d.assignedVehicle != null).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', total.toString(), Colors.blue),
            _buildStatItem('Active', active.toString(), Colors.green),
            _buildStatItem('On Leave', onLeave.toString(), Colors.orange),
            _buildStatItem('Assigned', assigned.toString(), Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search by name, employee ID, license, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter by Status:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All'),
                        ),
                        ..._statusOptions.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_capitalize(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Card
          _buildStatsCard(),

          // Drivers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDrivers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No drivers found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = _filteredDrivers[index];
                      final assignedVehicle = _vehicles.firstWhere(
                        (v) => v.id == driver.assignedVehicle,
                        orElse: () => Vehicle(
                          id: '',
                          registrationNumber: 'Not Assigned',
                          makeType: '',
                          status: 'active',
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              driver.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            driver.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('License: ${driver.licenseNumber}'),
                              if (driver.employeeId != null)
                                Text('Employee ID: ${driver.employeeId}'),
                              Text(
                                'Vehicle: ${assignedVehicle.registrationNumber}',
                              ),
                              if (driver.phone != null)
                                Text('Phone: ${driver.phone}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(driver.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _capitalize(driver.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: ListTile(
                                      leading: Icon(Icons.visibility),
                                      title: Text('View Details'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showDriverDetails(driver);
                                  } else if (value == 'edit') {
                                    _showAddEditDialog(driver: driver);
                                  } else if (value == 'delete') {
                                    _deleteDriver(driver.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () => _showDriverDetails(driver),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.person_add),
        tooltip: 'Add New Driver',
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
