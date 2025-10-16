import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../models/job.dart';
import '../../models/vehicle.dart';
import '../../models/driver.dart';
import '../../providers/job_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/driver_provider.dart';

class JobCreateDialog extends ConsumerStatefulWidget {
  const JobCreateDialog({super.key});

  @override
  ConsumerState<JobCreateDialog> createState() => _JobCreateDialogState();
}

class _JobCreateDialogState extends ConsumerState<JobCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _purposeController = TextEditingController();
  final _destinationController = TextEditingController();
  final _officerStaffController = TextEditingController();
  final _coesController = TextEditingController();
  final _dutyDetailController = TextEditingController();
  final _odometerOutController = TextEditingController();
  
  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load vehicles and drivers when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(driverProvider.notifier).loadDrivers();
    });
  }

  @override
  void dispose() {
    _routeController.dispose();
    _purposeController.dispose();
    _destinationController.dispose();
    _officerStaffController.dispose();
    _coesController.dispose();
    _dutyDetailController.dispose();
    _odometerOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final driverState = ref.watch(driverProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Create New Job',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Vehicle Selection
              Container(
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
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Text(
                            'Vehicle Selection',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: vehicleState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<Vehicle>(
                          initialValue: _selectedVehicle,
                              decoration: InputDecoration(
                                hintText: 'Select Vehicle',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.directions_car_outlined),
                              ),
                              items: vehicleState.vehicles.map((vehicle) {
                                return DropdownMenuItem<Vehicle>(
                                  value: vehicle,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${vehicle.make} ${vehicle.model}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${vehicle.licensePlate} • ${vehicle.year}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (vehicle) {
                                setState(() {
                                  _selectedVehicle = vehicle;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a vehicle';
                                }
                                return null;
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Driver Selection
              Container(
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
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Text(
                            'Driver Selection',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: driverState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<Driver>(
                          initialValue: _selectedDriver,
                              decoration: InputDecoration(
                                hintText: 'Select Driver',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              items: driverState.drivers.map((driver) {
                                return DropdownMenuItem<Driver>(
                                  value: driver,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        driver.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'License: ${driver.licenseNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (driver) {
                                setState(() {
                                  _selectedDriver = driver;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a driver';
                                }
                                return null;
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Route Input
              TextFormField(
                controller: _routeController,
                decoration: InputDecoration(
                  labelText: 'Route',
                  hintText: 'e.g., Karachi to Lahore',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.route),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter route';
                  }
                  if (value.trim().length < 3) {
                    return 'Route must be at least 3 characters';
                  }
                  return null;
                },
                maxLines: 2,
                minLines: 1,
              ),
              
              const SizedBox(height: 16),
              
              // Purpose Input
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  hintText: 'e.g., Business meeting, delivery, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business_center),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter purpose';
                  }
                  if (value.trim().length < 3) {
                    return 'Purpose must be at least 3 characters';
                  }
                  return null;
                },
                maxLines: 3,
                minLines: 1,
              ),
              
              const SizedBox(height: 16),

              // Destination Input
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g., Office HQ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 12),

              // Officer/Staff Input
              TextFormField(
                controller: _officerStaffController,
                decoration: InputDecoration(
                  labelText: 'Officer/Staff',
                  hintText: 'e.g., John Doe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 12),

              // CoEs Input
              TextFormField(
                controller: _coesController,
                decoration: InputDecoration(
                  labelText: 'CoEs',
                  hintText: 'Enter CoEs if any',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 12),

              // Duty Detail Input
              TextFormField(
                controller: _dutyDetailController,
                decoration: InputDecoration(
                  labelText: 'Duty Detail',
                  hintText: 'e.g., VIP Transport',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.assignment_outlined),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              
              const SizedBox(height: 16),
              
              // Odometer Out Input
              TextFormField(
                controller: _odometerOutController,
                decoration: InputDecoration(
                  labelText: 'Odometer Reading (Out)',
                  hintText: 'Enter current odometer reading',
                  suffix: const Text('km'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter odometer reading';
                  }
                  final km = double.tryParse(value.trim());
                  if (km == null || km < 0) {
                    return 'Please enter valid odometer reading';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createJob,
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
                          : const Text(
                              'Create Job',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final job = Job.createPending(
        vehicleId: _selectedVehicle!.id,
        vehicleName: '${_selectedVehicle!.make} ${_selectedVehicle!.model}',
        driverId: _selectedDriver!.id,
        driverName: _selectedDriver!.fullName,
        routeFrom: _routeController.text.trim().split(' to ').first,
        routeTo: _routeController.text.trim().contains(' to ') 
            ? _routeController.text.trim().split(' to ').last 
            : _routeController.text.trim(),
        purpose: _purposeController.text.trim(),
        destination: _destinationController.text.trim().isEmpty ? null : _destinationController.text.trim(),
        officerStaff: _officerStaffController.text.trim().isEmpty ? null : _officerStaffController.text.trim(),
        coes: _coesController.text.trim().isEmpty ? null : _coesController.text.trim(),
        dutyDetail: _dutyDetailController.text.trim().isEmpty ? null : _dutyDetailController.text.trim(),
        startingMeterReading: double.parse(_odometerOutController.text.trim()),
        remarksOut: 'Created from app',
      );

      final success = await ref.read(jobProvider.notifier).createJob(job);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job created successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create job. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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