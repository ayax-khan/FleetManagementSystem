import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import '../../providers/driver_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/debug_utils.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  final Driver? driver;

  const DriverFormScreen({super.key, this.driver});

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _basicSalaryController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  DriverStatus _selectedStatus = DriverStatus.active;
  DriverCategory _selectedCategory = DriverCategory.regular;
  LicenseCategory _selectedLicenseCategory = LicenseCategory.lightVehicle;
  DateTime? _dateOfBirth;
  DateTime? _joiningDate;
  DateTime? _licenseExpiryDate;
  String? _selectedVehicleId;
  
  bool _isLoading = false;
  bool get _isEditing => widget.driver != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFormWithDriverData();
    } else {
      // Set default joining date to today for new drivers
      _joiningDate = DateTime.now();
    }
  }

  void _populateFormWithDriverData() {
    final driver = widget.driver!;
    _firstNameController.text = driver.firstName;
    _lastNameController.text = driver.lastName;
    _employeeIdController.text = driver.employeeId;
    _cnicController.text = driver.cnic;
    _phoneController.text = driver.phoneNumber;
    _emailController.text = driver.email ?? '';
    _addressController.text = driver.address;
    _licenseNumberController.text = driver.licenseNumber;
    _basicSalaryController.text = driver.basicSalary.toString();
    _emergencyContactNameController.text = driver.emergencyContactName ?? '';
    _emergencyContactNumberController.text = driver.emergencyContactNumber ?? '';
    _notesController.text = driver.notes ?? '';
    
    _selectedStatus = driver.status;
    _selectedCategory = driver.category;
    _selectedLicenseCategory = driver.licenseCategory;
    _dateOfBirth = driver.dateOfBirth;
    _joiningDate = driver.joiningDate;
    _licenseExpiryDate = driver.licenseExpiryDate;
    _selectedVehicleId = driver.vehicleAssigned;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _employeeIdController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _basicSalaryController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Driver' : 'Add Driver',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit : Icons.person_add,
                          size: 32,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Update Driver Information' : 'Add New Driver',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEditing 
                                  ? 'Modify the driver details below'
                                  : 'Fill in the driver information',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
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
                          return 'Please enter first name';
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
                          return 'Please enter last name';
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
                      controller: _employeeIdController,
                      label: 'Employee ID',
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter employee ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _cnicController,
                      label: 'CNIC',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          String text = newValue.text.replaceAll('-', '');
                          if (text.length > 13) text = text.substring(0, 13);
                          
                          String formatted = '';
                          for (int i = 0; i < text.length; i++) {
                            if (i == 5 || i == 12) formatted += '-';
                            formatted += text[i];
                          }
                          
                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter CNIC';
                        }
                        if (value.length != 15) {
                          return 'CNIC must be 13 digits';
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
                    child: InkWell(
                      onTap: () => _selectDateOfBirth(),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _dateOfBirth != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                          style: TextStyle(
                            color: _joiningDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Employment Details Section
              _buildSectionHeader('Employment Details'),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField<DriverStatus>(
                      label: 'Status',
                      value: _selectedStatus,
                      items: DriverStatus.values,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField<DriverCategory>(
                      label: 'Category',
                      value: _selectedCategory,
                      items: DriverCategory.values,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
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
              
              _buildTextField(
                controller: _basicSalaryController,
                label: 'Basic Salary (PKR)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter basic salary';
                  }
                  final salary = double.tryParse(value);
                  if (salary == null || salary <= 0) {
                    return 'Please enter a valid salary';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // License Information Section
              _buildSectionHeader('License Information'),
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
                          return 'Please enter license number';
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
                  decoration: InputDecoration(
                    labelText: 'License Expiry Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    errorText: _licenseExpiryDate != null && _licenseExpiryDate!.isBefore(DateTime.now())
                        ? 'License has expired'
                        : null,
                  ),
                  child: Text(
                    _licenseExpiryDate != null
                        ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                        : 'Select expiry date',
                    style: TextStyle(
                      color: _licenseExpiryDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Vehicle Assignment Section
              _buildSectionHeader('Vehicle Assignment'),
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
              
              const SizedBox(height: 24),
              
              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _emergencyContactNumberController,
                      label: 'Emergency Contact Number',
                      keyboardType: TextInputType.phone,
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
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? 'Update Driver' : 'Add Driver',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
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

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
    );
    if (date != null) {
      setState(() {
        _dateOfBirth = date;
      });
    }
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
      initialDate: _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 1095)), // 3 years from now
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years from now
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

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth'), backgroundColor: Colors.red),
      );
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
        id: _isEditing ? widget.driver!.id : '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeId: _employeeIdController.text.trim().toUpperCase(),
        cnic: _cnicController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        joiningDate: _joiningDate!,
        status: _selectedStatus,
        category: _selectedCategory,
        licenseNumber: _licenseNumberController.text.trim().toUpperCase(),
        licenseCategory: _selectedLicenseCategory,
        licenseExpiryDate: _licenseExpiryDate!,
        basicSalary: double.parse(_basicSalaryController.text.trim()),
        vehicleAssigned: _selectedVehicleId,
        emergencyContactName: _emergencyContactNameController.text.trim().isNotEmpty 
            ? _emergencyContactNameController.text.trim() : null,
        emergencyContactNumber: _emergencyContactNumberController.text.trim().isNotEmpty 
            ? _emergencyContactNumberController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: _isEditing ? widget.driver!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = _isEditing
          ? await ref.read(driverProvider.notifier).updateDriver(driver)
          : await ref.read(driverProvider.notifier).addDriver(driver);

      if (success && mounted) {
        DebugUtils.log('Driver ${_isEditing ? 'updated' : 'added'} successfully', 'DRIVER_FORM');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Driver updated successfully' : 'Driver added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      DebugUtils.logError('Error saving driver', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving driver: $e'), backgroundColor: Colors.red),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Driver', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${widget.driver!.fullName} (${widget.driver!.employeeId})?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Close form screen
                
                final success = await ref.read(driverProvider.notifier).deleteDriver(widget.driver!.id);
                
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
}