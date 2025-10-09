import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../../models/vehicle.dart';
import '../../models/driver.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/validators.dart';

class AddFuelRecordScreen extends ConsumerStatefulWidget {
  static const String routeName = '/fuel/add';

  const AddFuelRecordScreen({super.key});

  @override
  ConsumerState<AddFuelRecordScreen> createState() => _AddFuelRecordScreenState();
}

class _AddFuelRecordScreenState extends ConsumerState<AddFuelRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _odometerController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form values
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedFuelStationId;
  FuelType? _selectedFuelType;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // Auto-calculation flags
  bool _isCalculatingFromQuantityPrice = true;
  
  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onQuantityOrPriceChanged);
    _unitPriceController.addListener(_onQuantityOrPriceChanged);
    _totalCostController.addListener(_onTotalCostChanged);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onQuantityOrPriceChanged() {
    if (!_isCalculatingFromQuantityPrice) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    
    if (quantity > 0 && unitPrice > 0) {
      final totalCost = quantity * unitPrice;
      _isCalculatingFromQuantityPrice = false;
      _totalCostController.text = totalCost.toStringAsFixed(2);
      _isCalculatingFromQuantityPrice = true;
    }
  }

  void _onTotalCostChanged() {
    if (_isCalculatingFromQuantityPrice) return;
    
    final totalCost = double.tryParse(_totalCostController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    
    if (totalCost > 0 && quantity > 0) {
      final unitPrice = totalCost / quantity;
      _isCalculatingFromQuantityPrice = false;
      _unitPriceController.text = unitPrice.toStringAsFixed(2);
      _isCalculatingFromQuantityPrice = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final drivers = ref.watch(driverProvider).drivers;
    final fuelStations = ref.watch(fuelProvider).fuelStations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fuel Record'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveFuelRecord,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Saving fuel record...')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Information Card
                  _buildBasicInfoCard(vehicles, drivers),
                  const SizedBox(height: 16),
                  
                  // Fuel Station & Type Card
                  _buildFuelStationCard(fuelStations),
                  const SizedBox(height: 16),
                  
                  // Fuel Details Card
                  _buildFuelDetailsCard(),
                  const SizedBox(height: 16),
                  
                  // Payment & Receipt Card
                  _buildPaymentCard(),
                  const SizedBox(height: 16),
                  
                  // Additional Info Card
                  _buildAdditionalInfoCard(),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoCard(List<Vehicle> vehicles, List<Driver> drivers) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Vehicle Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Vehicle *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              value: _selectedVehicleId,
              validator: Validators.required,
              items: vehicles.map((vehicle) {
                return DropdownMenuItem(
                  value: vehicle.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${vehicle.make} ${vehicle.model}'),
                      Text(
                        vehicle.licensePlate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleId = value;
                  _updateFuelTypeForVehicle(vehicles);
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Driver Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Driver *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _selectedDriverId,
              validator: Validators.required,
              items: drivers.map((driver) {
                return DropdownMenuItem(
                  value: driver.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(driver.fullName),
                      Text(
                        'ID: ${driver.licenseNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDriverId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Date Selection
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelStationCard(List<FuelStation> fuelStations) {
    final selectedStation = fuelStations
        .where((station) => station.id == _selectedFuelStationId)
        .firstOrNull;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fuel Station & Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fuel Station Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Fuel Station *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              value: _selectedFuelStationId,
              validator: Validators.required,
              items: fuelStations.map((station) {
                return DropdownMenuItem(
                  value: station.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(station.name),
                      Text(
                        station.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFuelStationId = value;
                  _updatePriceForFuelType();
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Fuel Type Selection
            DropdownButtonFormField<FuelType>(
              decoration: const InputDecoration(
                labelText: 'Fuel Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.opacity),
              ),
              value: _selectedFuelType,
              validator: (value) => value == null ? 'Please select fuel type' : null,
              items: FuelType.values.map((fuelType) {
                // Filter based on selected station's available fuel types
                final isAvailable = selectedStation?.availableFuelTypes.contains(fuelType) ?? true;
                
                return DropdownMenuItem(
                  value: fuelType,
                  enabled: isAvailable,
                  child: Row(
                    children: [
                      Icon(fuelType.iconData, size: 20, color: isAvailable ? fuelType.color : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        fuelType.displayName,
                        style: TextStyle(
                          color: isAvailable ? null : Colors.grey,
                        ),
                      ),
                      if (selectedStation?.currentPrices[fuelType] != null) ...[
                        const Spacer(),
                        Text(
                          'Rs ${selectedStation!.currentPrices[fuelType]!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFuelType = value;
                  _updatePriceForFuelType();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelDetailsCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fuel Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quantity and Unit Price Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantity (Liters) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_gas_station),
                      suffixText: 'L',
                    ),
                    validator: (value) => Validators.positiveNumber(value, 'Quantity'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price per Liter *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rs ',
                    ),
                    validator: (value) => Validators.positiveNumber(value, 'Price per liter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total Cost
            TextFormField(
              controller: _totalCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Total Cost *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: 'Rs ',
                helperText: 'Auto-calculated or enter manually',
              ),
              validator: (value) => Validators.positiveNumber(value, 'Total cost'),
              onChanged: (value) {
                _isCalculatingFromQuantityPrice = false;
                _onTotalCostChanged();
                _isCalculatingFromQuantityPrice = true;
              },
            ),
            const SizedBox(height: 16),
            
            // Odometer Reading
            TextFormField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Odometer Reading *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
                suffixText: 'km',
                helperText: 'Current kilometer reading',
              ),
              validator: (value) => Validators.positiveNumber(value, 'Odometer reading'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Payment & Receipt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment Method Selection
            const Text(
              'Payment Method *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        method.iconData,
                        size: 16,
                        color: isSelected ? Colors.white : method.color,
                      ),
                      const SizedBox(width: 4),
                      Text(method.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                    }
                  },
                  selectedColor: method.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Receipt Number (Optional)
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'Receipt Number (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
                helperText: 'Enter if available for record keeping',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                hintText: 'Any additional notes about this fuel record...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveFuelRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text(
              'Save Fuel Record',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateFuelTypeForVehicle(List<Vehicle> vehicles) {
    if (_selectedVehicleId == null) return;
    
    final vehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId);
    
    // Auto-select fuel type based on vehicle type
    switch (vehicle.type) {
      case VehicleType.car:
        _selectedFuelType = FuelType.petrol;
        break;
      case VehicleType.truck:
      case VehicleType.bus:
        _selectedFuelType = FuelType.diesel;
        break;
      case VehicleType.van:
        _selectedFuelType = FuelType.cng;
        break;
      default:
        _selectedFuelType = FuelType.petrol;
    }
    
    _updatePriceForFuelType();
  }

  void _updatePriceForFuelType() {
    if (_selectedFuelStationId == null || _selectedFuelType == null) return;
    
    final fuelStations = ref.read(fuelProvider).fuelStations;
    final station = fuelStations
        .where((s) => s.id == _selectedFuelStationId)
        .firstOrNull;
    
    if (station?.currentPrices[_selectedFuelType] != null) {
      _unitPriceController.text = station!.currentPrices[_selectedFuelType]!.toStringAsFixed(2);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveFuelRecord() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get vehicle and driver info
      final vehicles = ref.read(vehicleProvider).vehicles;
      final drivers = ref.read(driverProvider).drivers;
      final fuelStations = ref.read(fuelProvider).fuelStations;
      
      final vehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId);
      final driver = drivers.firstWhere((d) => d.id == _selectedDriverId);
      final station = fuelStations.firstWhere((s) => s.id == _selectedFuelStationId);
      
      // Create fuel record
      final fuelRecord = FuelRecord(
        id: 'fuel_${DateTime.now().millisecondsSinceEpoch}',
        vehicleId: vehicle.id,
        vehicleName: '${vehicle.make} ${vehicle.model}',
        vehicleLicensePlate: vehicle.licensePlate,
        driverId: driver.id,
        driverName: driver.fullName,
        date: _selectedDate,
        quantity: double.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
        totalCost: double.parse(_totalCostController.text),
        fuelStationId: station.id,
        fuelStationName: station.name,
        fuelType: _selectedFuelType!,
        odometer: double.parse(_odometerController.text),
        paymentMethod: _selectedPaymentMethod,
        receiptNumber: _receiptNumberController.text.isEmpty
            ? null
            : _receiptNumberController.text,
        location: station.location,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the record
      final success = await ref.read(fuelProvider.notifier).addFuelRecord(fuelRecord);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fuel record saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to save fuel record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving fuel record: $e'),
            backgroundColor: Colors.red,
          ),
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