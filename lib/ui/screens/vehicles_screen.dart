import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vehicle_controller.dart';
import '../../models/vehicle.dart';
import 'vehicle_detail_screen.dart';
import '../../core/utils/validators.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VehicleController>(
      create: (_) => VehicleController(),
      child: Consumer<VehicleController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Vehicles'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddEditDialog(context, controller),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: controller.setSearchTerm,
                    decoration: const InputDecoration(
                      labelText: 'Search by registration or make',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: controller.vehicles.isEmpty
                        ? const Center(child: Text("No vehicles found"))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: controller.vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = controller.vehicles[index];
                              return GestureDetector(
                                onTap: () {
                                  controller.selectVehicle(vehicle);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailScreen(
                                        vehicleId: vehicle.id!,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vehicle.registrationNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(vehicle.makeType),
                                        if (vehicle.modelYear != null)
                                          Text("Model: ${vehicle.modelYear}"),
                                        if (vehicle.engineCC != null)
                                          Text(
                                            "Engine: ${vehicle.engineCC} CC",
                                          ),
                                        const SizedBox(height: 10),
                                        Text('Status: ${vehicle.status}'),
                                        Text(
                                          'Odometer: ${vehicle.currentOdometer?.toStringAsFixed(0) ?? "0"} KM',
                                        ),
                                        if (vehicle.assignedDriver != null)
                                          Text(
                                            'Driver: ${vehicle.assignedDriver}',
                                          ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _showAddEditDialog(
                                                    context,
                                                    controller,
                                                    vehicle: vehicle,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                controller.deleteVehicle(
                                                  vehicle.id!,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    VehicleController controller, {
    Vehicle? vehicle,
  }) {
    final formKey = GlobalKey<FormState>();

    // Form controllers
    final regController = TextEditingController(
      text: vehicle?.registrationNumber ?? '',
    );
    final makeController = TextEditingController(text: vehicle?.makeType ?? '');
    final yearController = TextEditingController(
      text: vehicle?.modelYear ?? '',
    );
    final engineController = TextEditingController(
      text: vehicle?.engineCC?.toString() ?? '', // Convert double to string
    );
    final chassisController = TextEditingController(
      text: vehicle?.chassisNumber ?? '',
    );
    final engineNumController = TextEditingController(
      text: vehicle?.engineNumber ?? '',
    );
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final statusController = TextEditingController(
      text: vehicle?.status ?? 'active',
    );
    final odometerController = TextEditingController(
      text: vehicle?.currentOdometer?.toString() ?? '0',
    );
    final driverController = TextEditingController(
      text: vehicle?.assignedDriver ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(vehicle == null ? "Add Vehicle" : "Edit Vehicle"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: regController,
                    decoration: const InputDecoration(
                      labelText: "Registration Number*",
                    ),
                    validator: (value) =>
                        Validators.requiredField(value, "Registration Number"),
                  ),
                  TextFormField(
                    controller: makeController,
                    decoration: const InputDecoration(labelText: "Make/Type*"),
                    validator: (value) =>
                        Validators.requiredField(value, "Make/Type"),
                  ),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: "Model Year"),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null ||
                            year < 1900 ||
                            year > DateTime.now().year + 1) {
                          return 'Enter a valid year';
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: engineController,
                    decoration: const InputDecoration(labelText: "Engine CC"),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final engineCC = double.tryParse(value);
                        if (engineCC == null || engineCC <= 0) {
                          return 'Enter a valid engine CC';
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: chassisController,
                    decoration: const InputDecoration(
                      labelText: "Chassis Number",
                    ),
                  ),
                  TextFormField(
                    controller: engineNumController,
                    decoration: const InputDecoration(
                      labelText: "Engine Number",
                    ),
                  ),
                  TextFormField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: "Color"),
                  ),
                  DropdownButtonFormField<String>(
                    value: statusController.text,
                    decoration: const InputDecoration(labelText: "Status*"),
                    items: ['active', 'maintenance', 'inactive', 'assigned']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        statusController.text = value;
                      }
                    },
                    validator: (value) =>
                        Validators.requiredField(value, "Status"),
                  ),
                  TextFormField(
                    controller: odometerController,
                    decoration: const InputDecoration(
                      labelText: "Current Odometer*",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Odometer is required';
                      }
                      final odometer = double.tryParse(value);
                      if (odometer == null || odometer < 0) {
                        return 'Enter a valid odometer reading';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: driverController,
                    decoration: const InputDecoration(
                      labelText: "Assigned Driver ID",
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newVehicle = Vehicle(
                    id: vehicle?.id,
                    registrationNumber: regController.text.trim(),
                    makeType: makeController.text.trim(),
                    modelYear: yearController.text.trim().isNotEmpty
                        ? yearController.text.trim()
                        : null,
                    engineCC: engineController.text.trim().isNotEmpty
                        ? double.tryParse(
                            engineController.text.trim(),
                          ) // Convert string to double
                        : null,
                    chassisNumber: chassisController.text.trim().isNotEmpty
                        ? chassisController.text.trim()
                        : null,
                    engineNumber: engineNumController.text.trim().isNotEmpty
                        ? engineNumController.text.trim()
                        : null,
                    color: colorController.text.trim().isNotEmpty
                        ? colorController.text.trim()
                        : null,
                    status: statusController.text.trim(),
                    currentOdometer:
                        double.tryParse(odometerController.text) ?? 0,
                    assignedDriver: driverController.text.trim().isNotEmpty
                        ? driverController.text.trim()
                        : null,
                  );

                  // Validate vehicle using your existing validator
                  final validationError = Validators.validateVehicle(
                    newVehicle,
                  );
                  if (validationError != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(validationError)));
                    return;
                  }

                  if (vehicle == null) {
                    controller.addVehicle(newVehicle);
                  } else {
                    controller.updateVehicle(vehicle.id!, newVehicle);
                  }

                  Navigator.pop(context);
                }
              },
              child: Text(vehicle == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }
}
