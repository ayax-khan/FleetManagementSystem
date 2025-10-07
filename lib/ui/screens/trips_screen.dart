// lib/ui/screens/trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/trip_repo.dart';
import '../../models/trip_log.dart';
import '../theme.dart';
import '../../core/utils/validators.dart';
import '../widgets/data_table.dart';
import '../../controllers/dashboard_controller.dart'; // For integration
import 'package:intl/intl.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({Key? key}) : super(key: key);

  @override
  _TripsScreenState createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedVehicle;
  String? _selectedDriver;
  String _status = 'ongoing';
  TripLog? _editingTrip;

  List<TripLog> _trips = [];
  String _searchTerm = '';
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      _trips = await TripRepo().getAllTrips();
      // Filter by date if needed
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  List<TripLog> get filteredTrips => _trips.where((t) {
    final inDate =
        t.startTime.isAfter(_startDate) &&
        t.startTime.isBefore(_endDate.add(Duration(days: 1)));
    final inSearch =
        t.purpose?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false;
    return inDate && inSearch;
  }).toList();

  void _showAddEditDialog({TripLog? trip}) {
    _editingTrip = trip;
    if (trip != null) {
      _purposeController.text = trip.purpose ?? '';
      _startKmController.text = trip.startKm.toString();
      _endKmController.text = trip.endKm?.toString() ?? '';
      _startTime = trip.startTime;
      _endTime = trip.endTime;
      _status = trip.status;
      // Set vehicle, driver
    } else {
      // Clear
      _purposeController.clear();
      _startKmController.clear();
      _endKmController.clear();
      _startTime = null;
      _endTime = null;
      _status = 'ongoing';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_editingTrip == null ? 'Add Trip' : 'Edit Trip'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(labelText: 'Purpose'),
                    validator: (value) =>
                        Validators.requiredField(value, 'Purpose'),
                  ),
                  TextFormField(
                    controller: _startKmController,
                    decoration: const InputDecoration(labelText: 'Start KM'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null)
                        return 'Invalid Start KM';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _endKmController,
                    decoration: const InputDecoration(labelText: 'End KM'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && double.tryParse(value) == null)
                        return 'Invalid End KM';
                      return null;
                    },
                  ),
                  // Date pickers for start/end time
                  ListTile(
                    title: Text(
                      _startTime == null
                          ? 'Start Time'
                          : DateFormat('yyyy-MM-dd HH:mm').format(_startTime!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(
                            () => _startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      _endTime == null
                          ? 'End Time'
                          : DateFormat('yyyy-MM-dd HH:mm').format(_endTime!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(
                            () => _endTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // Dropdown for vehicle, driver from repos
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: ['ongoing', 'completed', 'approved']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  // Attachments upload
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(onPressed: _saveTrip, child: const Text('Save')),
          ],
        );
      },
    );
  }

  Future<void> _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      final trip = TripLog(
        vehicleId: _selectedVehicle ?? '',
        driverId: _selectedDriver ?? '',
        startKm: double.parse(_startKmController.text),
        endKm: _endKmController.text.isNotEmpty
            ? double.parse(_endKmController.text)
            : null,
        startTime: _startTime ?? DateTime.now(),
        endTime: _endTime,
        purpose: _purposeController.text,
        status: _status,
      );
      if (_editingTrip == null) {
        await TripRepo().addTrip(trip);
      } else {
        await TripRepo().updateTrip(_editingTrip!.id!, trip);
      }
      Navigator.pop(context);
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and date filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (term) => setState(() => _searchTerm = term),
                        decoration: const InputDecoration(labelText: 'Search'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          setState(() {
                            _startDate = range.start;
                            _endDate = range.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return ListTile(
                        title: Text(trip.purpose ?? 'Trip'),
                        subtitle: Text(
                          '${trip.startKm} - ${trip.endKm ?? 'Ongoing'} KM',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(trip: trip),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await TripRepo().deleteTrip(trip.id!);
                                _loadTrips();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Extend with more features: Export, charts for KM, integration with dashboard
  // Add pagination if many trips
  // Sort by date/status
  // ... (expand to make long)
}
