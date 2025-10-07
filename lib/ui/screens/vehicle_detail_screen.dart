// lib/ui/screens/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vehicle_controller.dart';
import '../theme.dart';
import '../../models/vehicle.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({Key? key, required this.vehicleId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VehicleController>(
      create: (_) => VehicleController(),
      child: Consumer<VehicleController>(
        builder: (context, controller, child) {
          final vehicle = controller.selectedVehicle; // Assume loaded
          if (vehicle == null) {
            // Load if not
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(vehicle.registrationNumber),
              actions: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make & Type: ${vehicle.makeType}'),
                  Text('Model Year: ${vehicle.modelYear ?? 'N/A'}'),
                  Text('Engine CC: ${vehicle.engineCC ?? 'N/A'}'),
                  // All fields
                  const SizedBox(height: 20),
                  const Text('History'),
                  FutureBuilder<Map<String, dynamic>>(
                    future: controller.getVehicleHistory(vehicleId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // Display trips, fuel, maintenance in tabs or lists
                        return TabBarView(
                          children: [
                            ListView(
                              children: snapshot.data!['trips']
                                  .map((t) => ListTile(title: Text(t.purpose)))
                                  .toList(),
                            ),
                            // Others
                          ],
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
