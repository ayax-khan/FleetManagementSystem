import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/debug_utils.dart';

class VehicleFormDialog extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormDialog({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final _fuelCapacityController = TextEditingController();
  final _currentMileageController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  VehicleType _selectedType = VehicleType.car;
  VehicleStatus _selectedStatus = VehicleStatus.active;
  String _selectedColor = VehicleColors.common.first;
  String _selectedMake = VehicleMakes.popular.first;
  DateTime? _purchaseDate;
  
  bool _isLoading = false;
  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFormWithVehicleData();
    }
  }

  void _populateFormWithVehicleData() {
    final vehicle = widget.vehicle!;
    try {
      _modelController.text = vehicle.model ?? '';
      _yearController.text = vehicle.year ?? DateTime.now().year.toString();
      _licensePlateController.text = vehicle.licensePlate ?? '';
      _vinController.text = vehicle.vin ?? '';
      _fuelCapacityController.text = vehicle.fuelCapacity.toString();
      _currentMileageController.text = vehicle.currentMileage.toString();
      _purchasePriceController.text = vehicle.purchasePrice?.toString() ?? '';
      _notesController.text = vehicle.notes ?? '';
      
      _selectedType = vehicle.type;
      _selectedStatus = vehicle.status;
      
      // Safely handle color selection
      _selectedColor = VehicleColors.common.contains(vehicle.color) 
          ? vehicle.color 
          : VehicleColors.common.first;
      
      // Safely handle make selection
      _selectedMake = VehicleMakes.popular.contains(vehicle.make) 
          ? vehicle.make 
          : VehicleMakes.popular.last; // 'Other'
      if (_selectedMake == 'Other') {
        _makeController.text = vehicle.make ?? '';
      }
      _purchaseDate = vehicle.purchaseDate;
    } catch (e) {
      print('Error populating vehicle form: $e');
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _fuelCapacityController.dispose();
    _currentMileageController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 800,
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        _selectedType.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditing 
                              ? 'Modify the vehicle details below'
                              : 'Fill in the vehicle information',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: () => _showDeleteDialog(),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 12),
                      
                      // Make and Model Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Make',
                              value: _selectedMake,
                              items: VehicleMakes.popular,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMake = value!;
                                  if (value != 'Other') {
                                    _makeController.clear();
                                  }
                                });
                              },
                              itemBuilder: (make) => Text(make),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_selectedMake == 'Other')
                            Expanded(
                              child: _buildTextField(
                                controller: _makeController,
                                label: 'Custom Make',
                                validator: (value) {
                                  if (_selectedMake == 'Other' && (value == null || value.isEmpty)) {
                                    return 'Please enter vehicle make';
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
                            flex: 2,
                            child: _buildTextField(
                              controller: _modelController,
                              label: 'Model',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter vehicle model';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _yearController,
                              label: 'Year',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final year = int.tryParse(value);
                                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                                  return 'Invalid year';
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
                            child: _buildDropdownField<VehicleType>(
                              label: 'Type',
                              value: _selectedType,
                              items: VehicleType.values,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                              itemBuilder: (type) => Row(
                                children: [
                                  Text(type.icon),
                                  const SizedBox(width: 8),
                                  Text(type.displayName),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField<VehicleStatus>(
                              label: 'Status',
                              value: _selectedStatus,
                              items: VehicleStatus.values,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                              itemBuilder: (status) => Row(
                                children: [
                                  Text(status.icon),
                                  const SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Identification Section
                      _buildSectionHeader('Identification'),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _licensePlateController,
                              label: 'License Plate',
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter license plate';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Color',
                              value: _selectedColor,
                              items: VehicleColors.common,
                              onChanged: (value) {
                                setState(() {
                                  _selectedColor = value!;
                                });
                              },
                              itemBuilder: (color) => Text(color),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _vinController,
                        label: 'VIN (Vehicle Identification Number)',
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter VIN';
                          }
                          if (value.length != 17) {
                            return 'VIN must be 17 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Technical Details Section
                      _buildSectionHeader('Technical Details'),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _fuelCapacityController,
                              label: 'Fuel Capacity (L)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final capacity = double.tryParse(value);
                                if (capacity == null || capacity <= 0) {
                                  return 'Invalid capacity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _currentMileageController,
                              label: 'Current Mileage (km)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final mileage = double.tryParse(value);
                                if (mileage == null || mileage < 0) {
                                  return 'Invalid mileage';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Purchase Information Section
                      _buildSectionHeader('Purchase Information (Optional)'),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectPurchaseDate(),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _purchaseDate != null
                                      ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _purchaseDate != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _purchasePriceController,
                              label: 'Purchase Price (\$)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final price = double.tryParse(value);
                                  if (price == null || price < 0) {
                                    return 'Invalid price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Notes Section
                      _buildSectionHeader('Additional Notes'),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update Vehicle' : 'Add Vehicle',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _purchaseDate = date;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final make = _selectedMake == 'Other' ? _makeController.text.trim() : _selectedMake;
      
      final vehicle = Vehicle(
        id: _isEditing ? widget.vehicle!.id : '',
        make: make,
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
        licensePlate: _licensePlateController.text.trim().toUpperCase(),
        vin: _vinController.text.trim().toUpperCase(),
        type: _selectedType,
        status: _selectedStatus,
        fuelCapacity: double.parse(_fuelCapacityController.text.trim()),
        currentMileage: double.parse(_currentMileageController.text.trim()),
        color: _selectedColor,
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePriceController.text.trim().isNotEmpty 
            ? double.tryParse(_purchasePriceController.text.trim()) 
            : null,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        createdAt: _isEditing ? widget.vehicle!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = _isEditing
          ? await ref.read(vehicleProvider.notifier).updateVehicle(vehicle)
          : await ref.read(vehicleProvider.notifier).addVehicle(vehicle);

      if (success && mounted) {
        DebugUtils.log('Vehicle ${_isEditing ? 'updated' : 'added'} successfully', 'VEHICLE_FORM');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Vehicle updated successfully' 
                  : 'Vehicle added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      DebugUtils.logError('Error saving vehicle', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vehicle: $e'),
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Delete Vehicle',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${widget.vehicle!.displayName}?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Close form dialog
                
                final success = await ref.read(vehicleProvider.notifier)
                    .deleteVehicle(widget.vehicle!.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                            ? 'Vehicle deleted successfully'
                            : 'Failed to delete vehicle',
                      ),
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