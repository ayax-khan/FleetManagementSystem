// lib/ui/screens/maintenance_screen.dart
import 'package:fleet_management/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/maintenance.dart';
import '../../models/vehicle.dart';
import '../../repositories/vehicle_repo.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<Maintenance> _maintenances = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  Maintenance? _editingMaintenance;
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _vendorController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();
  final _partsController = TextEditingController();
  DateTime? _date;
  String? _selectedVehicle;
  String? _selectedStatus;
  List<String> _partsReplaced = [];
  String _filterStatus = 'all';
  String _searchQuery = '';

  final List<String> _statusOptions = ['pending', 'completed', 'cancelled'];
  final VehicleRepo _vehicleRepo = VehicleRepo();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _maintenances = await HiveService().getAll<Maintenance>('maintenances');
      _vehicles = await _vehicleRepo.getAllVehicles();
      _sortMaintenances();
    } catch (e) {
      _showSnackBar('Failed to load data: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _sortMaintenances() {
    _maintenances.sort((a, b) => b.date.compareTo(a.date));
  }

  List<Maintenance> get _filteredMaintenances {
    var filtered = _maintenances;

    // Filter by status
    if (_filterStatus != 'all') {
      filtered = filtered.where((m) => m.status == _filterStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final vehicle = _vehicles.firstWhere(
          (v) => v.id == m.vehicleId,
          orElse: () => Vehicle(
            id: '',
            registrationNumber: 'Unknown',
            makeType: '',
            status: 'active',
          ),
        );
        return m.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true ||
            m.vendor?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                true ||
            vehicle.registrationNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    return filtered;
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

  void _showAddEditDialog({Maintenance? maintenance}) {
    _editingMaintenance = maintenance;

    // Initialize form fields
    if (maintenance != null) {
      _descriptionController.text = maintenance.description ?? '';
      _costController.text = maintenance.cost?.toString() ?? '';
      _vendorController.text = maintenance.vendor ?? '';
      _odometerController.text =
          maintenance.odometerAtMaintenance?.toString() ?? '';
      _notesController.text = maintenance.notes ?? '';
      _date = maintenance.date;
      _selectedVehicle = maintenance.vehicleId;
      _selectedStatus = maintenance.status ?? 'pending';
      _partsReplaced = maintenance.partsReplaced ?? [];
    } else {
      _descriptionController.clear();
      _costController.clear();
      _vendorController.clear();
      _odometerController.clear();
      _notesController.clear();
      _date = DateTime.now();
      _selectedVehicle = null;
      _selectedStatus = 'pending';
      _partsReplaced = [];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _editingMaintenance == null
                    ? 'Add Maintenance'
                    : 'Edit Maintenance',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedVehicle,
                      items: _vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(vehicle.registrationNumber),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedVehicle = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Vehicle *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null ? 'Vehicle is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'Cost (Rs)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: const InputDecoration(
                              labelText: 'Odometer',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vendorController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor/Workshop',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedStatus = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parts Replaced',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_partsReplaced.isNotEmpty)
                            ..._partsReplaced.map(
                              (part) => ListTile(
                                title: Text(part),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      _partsReplaced.remove(part);
                                    });
                                  },
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _partsController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add part name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (_partsController.text.trim().isNotEmpty) {
                                    setDialogState(() {
                                      _partsReplaced.add(
                                        _partsController.text.trim(),
                                      );
                                      _partsController.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _date == null
                            ? 'Select Date *'
                            : 'Date: ${DateFormat('yyyy-MM-dd').format(_date!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => _date = picked);
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
                  onPressed: () => _saveMaintenance(setDialogState),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMaintenance(Function setDialogState) async {
    // Validate required fields
    if (_selectedVehicle == null) {
      _showSnackBar('Please select a vehicle', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('Description is required', isError: true);
      return;
    }
    if (_date == null) {
      _showSnackBar('Date is required', isError: true);
      return;
    }

    try {
      final maintenance = Maintenance(
        id: _editingMaintenance?.id,
        vehicleId: _selectedVehicle!,
        date: _date!,
        description: _descriptionController.text.trim(),
        cost: double.tryParse(_costController.text),
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        odometerAtMaintenance: double.tryParse(_odometerController.text),
        status: _selectedStatus,
        partsReplaced: _partsReplaced.isNotEmpty ? _partsReplaced : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_editingMaintenance == null) {
        await HiveService().add<Maintenance>('maintenances', maintenance);
        _showSnackBar('Maintenance record added successfully');
      } else {
        await HiveService().update<Maintenance>(
          'maintenances',
          _editingMaintenance!.id!,
          maintenance,
        );
        _showSnackBar('Maintenance record updated successfully');
      }

      _clearForm();
      Navigator.pop(context);
      await _loadData();
    } catch (e) {
      _showSnackBar('Failed to save maintenance: $e', isError: true);
    }
  }

  void _clearForm() {
    _editingMaintenance = null;
    _descriptionController.clear();
    _costController.clear();
    _vendorController.clear();
    _odometerController.clear();
    _notesController.clear();
    _partsController.clear();
    _date = null;
    _selectedVehicle = null;
    _selectedStatus = 'pending';
    _partsReplaced = [];
  }

  Future<void> _deleteMaintenance(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this maintenance record?',
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
        await HiveService().delete<Maintenance>('maintenances', id);
        _showSnackBar('Maintenance record deleted successfully');
        await _loadData();
      } catch (e) {
        _showSnackBar('Failed to delete maintenance: $e', isError: true);
      }
    }
  }

  String _getVehicleRegistration(String vehicleId) {
    try {
      final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
      return vehicle.registrationNumber;
    } catch (e) {
      return 'Unknown Vehicle';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatsCard() {
    final total = _maintenances.length;
    final completed = _maintenances
        .where((m) => m.status == 'completed')
        .length;
    final pending = _maintenances.where((m) => m.status == 'pending').length;
    final totalCost = _maintenances
        .where((m) => m.status == 'completed')
        .fold(0.0, (sum, m) => sum + (m.cost ?? 0));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', total.toString(), Colors.blue),
            _buildStatItem('Completed', completed.toString(), Colors.green),
            _buildStatItem('Pending', pending.toString(), Colors.orange),
            _buildStatItem(
              'Total Cost',
              'Rs ${totalCost.toStringAsFixed(0)}',
              Colors.purple,
            ),
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
        title: const Text('Maintenance Records'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                    hintText: 'Search by description, vendor, or vehicle...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
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
                            child: Text(status.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
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

          // Maintenances List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMaintenances.isEmpty
                ? const Center(
                    child: Text(
                      'No maintenance records found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMaintenances.length,
                    itemBuilder: (context, index) {
                      final maintenance = _filteredMaintenances[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            maintenance.description ?? 'Maintenance',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle: ${_getVehicleRegistration(maintenance.vehicleId)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Vendor: ${maintenance.vendor ?? "N/A"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd').format(maintenance.date)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (maintenance.cost != null)
                                Text(
                                  'Cost: Rs ${maintenance.cost!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
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
                                  color: _getStatusColor(
                                    maintenance.status ?? 'pending',
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (maintenance.status ?? 'pending')
                                      .toUpperCase(),
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
                                  if (value == 'edit') {
                                    _showAddEditDialog(
                                      maintenance: maintenance,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteMaintenance(maintenance.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () =>
                              _showAddEditDialog(maintenance: maintenance),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Maintenance Record',
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _vendorController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    _partsController.dispose();
    super.dispose();
  }
}
