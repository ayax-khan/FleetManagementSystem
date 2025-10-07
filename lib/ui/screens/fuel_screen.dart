// lib/ui/screens/fuel_screen.dart
import 'package:fleet_management/services/hive_service.dart';
import 'package:flutter/material.dart';
import '../../models/fuel_entry.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import '../../repositories/vehicle_repo.dart'; // For vehicles

class FuelScreen extends StatefulWidget {
  const FuelScreen({Key? key}) : super(key: key);

  @override
  _FuelScreenState createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  List<FuelEntry> _fuelEntries = [];
  bool _isLoading = false;
  FuelEntry? _editingEntry;
  final _litersController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _vendorController = TextEditingController();
  DateTime? _date;
  String? _selectedVehicle;
  String? _selectedDriver;
  String _shift = 'morning';

  @override
  void initState() {
    super.initState();
    _loadFuelEntries();
  }

  Future<void> _loadFuelEntries() async {
    setState(() => _isLoading = true);
    _fuelEntries = await HiveService().getAll<FuelEntry>('fuelEntries');
    setState(() => _isLoading = false);
  }

  void _showAddEditDialog({FuelEntry? entry}) {
    _editingEntry = entry;
    if (entry != null) {
      _litersController.text = entry.liters.toString();
      _pricePerLiterController.text = entry.pricePerLiter?.toString() ?? '';
      _totalCostController.text = entry.totalCost.toString();
      _vendorController.text = entry.vendor ?? '';
      _date = entry.date;
      _selectedVehicle = entry.vehicleId;
      _selectedDriver = entry.driverId;
      _shift = entry.shift ?? 'morning';
    } else {
      // Clear
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _editingEntry == null ? 'Add Fuel Entry' : 'Edit Fuel Entry',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedVehicle,
                  items: [], // From vehicles
                  onChanged: (value) => _selectedVehicle = value,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedDriver,
                  items: [], // From drivers
                  onChanged: (value) => _selectedDriver = value,
                  decoration: const InputDecoration(labelText: 'Driver'),
                ),
                TextFormField(
                  controller: _litersController,
                  decoration: const InputDecoration(labelText: 'Liters'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pricePerLiterController,
                  decoration: const InputDecoration(
                    labelText: 'Price per Liter',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    double liters =
                        double.tryParse(_litersController.text) ?? 0;
                    double price = double.tryParse(value) ?? 0;
                    _totalCostController.text = (liters * price)
                        .toStringAsFixed(2);
                  },
                ),
                TextFormField(
                  controller: _totalCostController,
                  decoration: const InputDecoration(labelText: 'Total Cost'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _vendorController,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                ),
                ListTile(
                  title: Text(
                    _date == null
                        ? 'Date'
                        : DateFormat('yyyy-MM-dd').format(_date!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _shift,
                  items: ['morning', 'evening', 'night']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => _shift = value!,
                  decoration: const InputDecoration(labelText: 'Shift'),
                ),
                // Receipt upload
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(onPressed: _saveEntry, child: const Text('Save')),
          ],
        );
      },
    );
  }

  Future<void> _saveEntry() async {
    final entry = FuelEntry(
      vehicleId: _selectedVehicle ?? '',
      driverId: _selectedDriver,
      date: _date ?? DateTime.now(),
      liters: double.parse(_litersController.text),
      pricePerLiter: double.tryParse(_pricePerLiterController.text),
      totalCost: double.parse(_totalCostController.text),
      vendor: _vendorController.text,
      shift: _shift,
    );
    if (_editingEntry == null) {
      await HiveService().add<FuelEntry>('fuelEntries', entry);
    } else {
      await HiveService().update<FuelEntry>(
        'fuelEntries',
        _editingEntry!.id!,
        entry,
      );
    }
    Navigator.pop(context);
    _loadFuelEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel (POL)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _fuelEntries.length,
              itemBuilder: (context, index) {
                final f = _fuelEntries[index];
                return ListTile(
                  title: Text('Liters: ${f.liters} - Cost: Rs ${f.totalCost}'),
                  subtitle: Text('Date: ${f.date} - Vehicle: ${f.vehicleId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(entry: f),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await HiveService().delete<FuelEntry>(
                            'fuelEntries',
                            f.id!,
                          );
                          _loadFuelEntries();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Extend: Analytics, charts, total costs
}
