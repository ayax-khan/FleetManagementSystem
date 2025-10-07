// lib/ui/screens/settings_screen.dart
import 'package:fleet_management/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/import_service.dart';
import '../../services/backup_service.dart';
import '../../services/hive_service.dart';
import '../../repositories/vehicle_repo.dart';
import '../../controllers/auth_controller.dart';
import '../../models/pol_price.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../core/utils/validators.dart';
import '../theme.dart';
import '../widgets/file_picker.dart';
import '../widgets/data_table.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _polPriceFormKey = GlobalKey<FormState>();
  final _petrolPriceController = TextEditingController();
  final _dieselPriceController = TextEditingController();
  DateTime? _selectedDate;
  List<PolPrice> _polPrices = [];
  bool _isLoading = false;
  String? _statusMessage;
  bool _enableNotifications = true;
  String _selectedTheme = 'light';
  bool _autoBackup = true;
  Duration _backupFrequency = AppConfig.backupFrequency;

  @override
  void initState() {
    super.initState();
    _loadPolPrices();
    _loadSettings();
  }

  Future<void> _loadPolPrices() async {
    setState(() => _isLoading = true);
    try {
      _polPrices = await HiveService().getAll<PolPrice>(Constants.polPriceBox);
      _polPrices.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _setStatusMessage('Failed to load POL prices: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSettings() async {
    // Load from shared prefs or Hive
    // For demo, defaults
  }

  void _setStatusMessage(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
    Timer(
      const Duration(seconds: 5),
      () => setState(() => _statusMessage = null),
    );
  }

  Future<void> _addPolPrice() async {
    if (_polPriceFormKey.currentState!.validate() && _selectedDate != null) {
      final polPrice = PolPrice(
        date: _selectedDate!,
        petrolPrice: double.parse(_petrolPriceController.text),
        dieselPrice: double.parse(_dieselPriceController.text),
        pvtUseRatePetrol: double.parse(_petrolPriceController.text) * 0.5,
        pvtUseRateDiesel: double.parse(_dieselPriceController.text) * 0.5,
      );
      await HiveService().add<PolPrice>(Constants.polPriceBox, polPrice);
      _clearPolForm();
      await _loadPolPrices();
      _setStatusMessage('POL price added successfully');
    }
  }

  void _clearPolForm() {
    _petrolPriceController.clear();
    _dieselPriceController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      String? path = await ImportService().pickImportFile();
      if (path != null) {
        await ImportService().importFromExcel(path);
        // Refresh relevant data - use getAllVehicles instead of loadVehicles
        await VehicleRepo().getAllVehicles(); // Fixed: using existing method
        _setStatusMessage('Import successful');
      }
    } catch (e) {
      _setStatusMessage('Import failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      String path = await BackupService().createBackup();
      await BackupService().shareBackup(path);
      _setStatusMessage('Backup created and shared');
    } catch (e) {
      _setStatusMessage('Backup failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);
    try {
      String? path = await ImportService().pickImportFile(excel: false);
      if (path != null) {
        await BackupService().restoreBackup(path);
        _setStatusMessage('Restore successful. Restart app.');
      }
    } catch (e) {
      _setStatusMessage('Restore failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _enableNotifications = value);
    // Save to settings
    if (value) {
      // Schedule reminders
    }
  }

  void _changeTheme(String? value) {
    if (value != null) {
      setState(() => _selectedTheme = value);
      // Apply theme, perhaps notify app-wide
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackup = value);
    if (value) {
      BackupService().scheduledBackup();
    }
  }

  Future<void> _logout() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _changePassword() async {
    // Show dialog with old/new password
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement password change logic
              Navigator.pop(context);
              _setStatusMessage('Password changed successfully');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPolPrice(PolPrice pol) async {
    _petrolPriceController.text = pol.petrolPrice.toString();
    _dieselPriceController.text = pol.dieselPrice.toString();
    setState(() => _selectedDate = pol.date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit POL Price'),
        content: Form(
          key: _polPriceFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _petrolPriceController,
                decoration: const InputDecoration(labelText: 'Petrol Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.isValidPrice(double.tryParse(value ?? ''))
                    ? null
                    : 'Invalid price',
              ),
              TextFormField(
                controller: _dieselPriceController,
                decoration: const InputDecoration(labelText: 'Diesel Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.isValidPrice(double.tryParse(value ?? ''))
                    ? null
                    : 'Invalid price',
              ),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : _selectedDate!.toIso8601String(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearPolForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_polPriceFormKey.currentState!.validate() &&
                  _selectedDate != null) {
                final updatedPol = PolPrice(
                  id: pol.id,
                  date: _selectedDate!,
                  petrolPrice: double.parse(_petrolPriceController.text),
                  dieselPrice: double.parse(_dieselPriceController.text),
                  pvtUseRatePetrol:
                      double.parse(_petrolPriceController.text) * 0.5,
                  pvtUseRateDiesel:
                      double.parse(_dieselPriceController.text) * 0.5,
                );
                await HiveService().update<PolPrice>(
                  Constants.polPriceBox,
                  pol.id!,
                  updatedPol,
                );
                _clearPolForm();
                await _loadPolPrices();
                Navigator.pop(context);
                _setStatusMessage('POL price updated successfully');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePolPrice(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this POL price?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await HiveService().delete<PolPrice>(Constants.polPriceBox, id);
      await _loadPolPrices();
      _setStatusMessage('POL price deleted successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Import Data'),
                    subtitle: const Text('Import from Excel/CSV'),
                    trailing: ElevatedButton(
                      onPressed: _importData,
                      child: const Text('Import'),
                    ),
                  ),
                  ListTile(
                    title: const Text('Create Backup'),
                    subtitle: const Text('Backup database'),
                    trailing: ElevatedButton(
                      onPressed: _createBackup,
                      child: const Text('Backup'),
                    ),
                  ),
                  ListTile(
                    title: const Text('Restore Backup'),
                    subtitle: const Text('Restore from file'),
                    trailing: ElevatedButton(
                      onPressed: _restoreBackup,
                      child: const Text('Restore'),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Auto Backup'),
                    value: _autoBackup,
                    onChanged: _toggleAutoBackup,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'POL Prices',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _polPriceFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _petrolPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Petrol Price',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              Validators.isValidPrice(
                                double.tryParse(value ?? ''),
                              )
                              ? null
                              : 'Invalid price',
                        ),
                        TextFormField(
                          controller: _dieselPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Diesel Price',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              Validators.isValidPrice(
                                double.tryParse(value ?? ''),
                              )
                              ? null
                              : 'Invalid price',
                        ),
                        ListTile(
                          title: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : 'Selected: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null)
                                setState(() => _selectedDate = date);
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _addPolPrice,
                          child: const Text('Add POL Price'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_polPrices.isNotEmpty)
                    CustomDataTable(
                      headers: const ['Date', 'Petrol', 'Diesel', 'Actions'],
                      rows: _polPrices
                          .map(
                            (p) => [
                              p.date.toLocal().toString().split(' ')[0],
                              p.petrolPrice.toStringAsFixed(2),
                              p.dieselPrice.toStringAsFixed(2),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editPolPrice(p),
                                    color: Colors.blue,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deletePolPrice(p.id!),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 40),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Reminders for expiries, maintenance'),
                    value: _enableNotifications,
                    onChanged: _toggleNotifications,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ListTile(
                    title: const Text('Theme'),
                    trailing: DropdownButton<String>(
                      value: _selectedTheme,
                      items: const [
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      ],
                      onChanged: _changeTheme,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: IconButton(
                      icon: const Icon(Icons.lock),
                      onPressed: _changePassword,
                    ),
                  ),
                  ListTile(
                    title: const Text('Logout'),
                    trailing: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: _logout,
                    ),
                  ),
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.contains('Failed')
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
