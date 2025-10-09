import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';
import '../../models/vehicle.dart';
import '../../models/driver.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/fuel_provider.dart';

class FuelFilterDialog extends ConsumerStatefulWidget {
  final FuelFilter currentFilter;
  final Function(FuelFilter) onApplyFilter;

  const FuelFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  ConsumerState<FuelFilterDialog> createState() => _FuelFilterDialogState();
}

class _FuelFilterDialogState extends ConsumerState<FuelFilterDialog> {
  late FuelFilter _filter;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    
    if (_filter.minAmount != null) {
      _minAmountController.text = _filter.minAmount!.toStringAsFixed(0);
    }
    if (_filter.maxAmount != null) {
      _maxAmountController.text = _filter.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final drivers = ref.watch(driverProvider).drivers;
    final fuelStations = ref.watch(fuelProvider).fuelStations;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Fuel Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range
                    _buildSectionTitle('Date Range'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            'Start Date',
                            _filter.startDate,
                            (date) => setState(() {
                              _filter = _filter.copyWith(startDate: date);
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            'End Date',
                            _filter.endDate,
                            (date) => setState(() {
                              _filter = _filter.copyWith(endDate: date);
                            }),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Vehicles
                    if (vehicles.isNotEmpty) ...[
                      _buildSectionTitle('Vehicles'),
                      const SizedBox(height: 12),
                      _buildVehicleSelection(vehicles),
                      const SizedBox(height: 24),
                    ],
                    
                    // Drivers
                    if (drivers.isNotEmpty) ...[
                      _buildSectionTitle('Drivers'),
                      const SizedBox(height: 12),
                      _buildDriverSelection(drivers),
                      const SizedBox(height: 24),
                    ],
                    
                    // Fuel Types
                    _buildSectionTitle('Fuel Types'),
                    const SizedBox(height: 12),
                    _buildFuelTypeSelection(),
                    const SizedBox(height: 24),
                    
                    // Payment Methods
                    _buildSectionTitle('Payment Methods'),
                    const SizedBox(height: 12),
                    _buildPaymentMethodSelection(),
                    const SizedBox(height: 24),
                    
                    // Fuel Stations
                    if (fuelStations.isNotEmpty) ...[
                      _buildSectionTitle('Fuel Stations'),
                      const SizedBox(height: 12),
                      _buildStationSelection(fuelStations),
                      const SizedBox(height: 24),
                    ],
                    
                    // Amount Range
                    _buildSectionTitle('Amount Range (Rs)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Amount',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final amount = double.tryParse(value);
                              setState(() {
                                _filter = _filter.copyWith(minAmount: amount);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Maximum Amount',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final amount = double.tryParse(value);
                              setState(() {
                                _filter = _filter.copyWith(maxAmount: amount);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = const FuelFilter();
                        _minAmountController.clear();
                        _maxAmountController.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilter(_filter);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply Filter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('MMM d, yyyy').format(selectedDate)
                    : label,
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.clear, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelection(List<Vehicle> vehicles) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vehicles.map((vehicle) {
        final isSelected = _filter.vehicleIds?.contains(vehicle.id) == true;
        return FilterChip(
          label: Text('${vehicle.make} ${vehicle.model}'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                final currentIds = _filter.vehicleIds ?? <String>[];
                _filter = _filter.copyWith(
                  vehicleIds: [...currentIds, vehicle.id],
                );
              } else {
                final currentIds = _filter.vehicleIds ?? <String>[];
                _filter = _filter.copyWith(
                  vehicleIds: currentIds.where((id) => id != vehicle.id).toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDriverSelection(List<Driver> drivers) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: drivers.map((driver) {
        final isSelected = _filter.driverIds?.contains(driver.id) == true;
        return FilterChip(
          label: Text(driver.fullName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                final currentIds = _filter.driverIds ?? <String>[];
                _filter = _filter.copyWith(
                  driverIds: [...currentIds, driver.id],
                );
              } else {
                final currentIds = _filter.driverIds ?? <String>[];
                _filter = _filter.copyWith(
                  driverIds: currentIds.where((id) => id != driver.id).toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFuelTypeSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FuelType.values.map((fuelType) {
        final isSelected = _filter.fuelTypes?.contains(fuelType) == true;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fuelType.iconData, size: 16, color: fuelType.color),
              const SizedBox(width: 4),
              Text(fuelType.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                final currentTypes = _filter.fuelTypes ?? <FuelType>[];
                _filter = _filter.copyWith(
                  fuelTypes: [...currentTypes, fuelType],
                );
              } else {
                final currentTypes = _filter.fuelTypes ?? <FuelType>[];
                _filter = _filter.copyWith(
                  fuelTypes: currentTypes.where((type) => type != fuelType).toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((paymentMethod) {
        final isSelected = _filter.paymentMethods?.contains(paymentMethod) == true;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(paymentMethod.iconData, size: 16, color: paymentMethod.color),
              const SizedBox(width: 4),
              Text(paymentMethod.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                final currentMethods = _filter.paymentMethods ?? <PaymentMethod>[];
                _filter = _filter.copyWith(
                  paymentMethods: [...currentMethods, paymentMethod],
                );
              } else {
                final currentMethods = _filter.paymentMethods ?? <PaymentMethod>[];
                _filter = _filter.copyWith(
                  paymentMethods: currentMethods.where((method) => method != paymentMethod).toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStationSelection(List<FuelStation> stations) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stations.map((station) {
        final isSelected = _filter.fuelStationIds?.contains(station.id) == true;
        return FilterChip(
          label: Text(station.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                final currentIds = _filter.fuelStationIds ?? <String>[];
                _filter = _filter.copyWith(
                  fuelStationIds: [...currentIds, station.id],
                );
              } else {
                final currentIds = _filter.fuelStationIds ?? <String>[];
                _filter = _filter.copyWith(
                  fuelStationIds: currentIds.where((id) => id != station.id).toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }
}