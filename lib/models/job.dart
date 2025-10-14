import 'package:uuid/uuid.dart';

enum JobStatus {
  pending('Pending', '🕒'),
  completed('Completed', '✅');

  const JobStatus(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

class Job {
  final String id;
  final String jobId; // Auto-generated job number like JOB001
  final DateTime dateTimeOut;
  final String vehicleId;
  final String vehicleName; // For display
  final String driverId;
  final String driverName; // For display
  final String routeFrom;
  final String routeTo;
  final String purpose;
  final double startingMeterReading; // Meter Out
  final String? remarksOut; // Remarks when going out
  final JobStatus status;
  
  // Fields for completed jobs
  final DateTime? dateTimeIn;
  final double? endingMeterReading; // Meter In
  final double? totalKm; // Auto calculated
  final double? fuelUsed; // Liters
  final double? fuelEfficiency; // KM/L - auto calculated
  final String? remarksIn; // Remarks when returning
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const Job({
    required this.id,
    required this.jobId,
    required this.dateTimeOut,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverId,
    required this.driverName,
    required this.routeFrom,
    required this.routeTo,
    required this.purpose,
    required this.startingMeterReading,
    this.remarksOut,
    required this.status,
    this.dateTimeIn,
    this.endingMeterReading,
    this.totalKm,
    this.fuelUsed,
    this.fuelEfficiency,
    this.remarksIn,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new pending job
  factory Job.createPending({
    required String vehicleId,
    required String vehicleName,
    required String driverId,
    required String driverName,
    required String routeFrom,
    required String routeTo,
    required String purpose,
    required double startingMeterReading,
    String? remarksOut,
    String? jobId,
  }) {
    const uuid = Uuid();
    final now = DateTime.now();
    
    return Job(
      id: uuid.v4(),
      jobId: jobId ?? _generateJobId(),
      dateTimeOut: now,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      driverId: driverId,
      driverName: driverName,
      routeFrom: routeFrom,
      routeTo: routeTo,
      purpose: purpose,
      startingMeterReading: startingMeterReading,
      remarksOut: remarksOut,
      status: JobStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Complete a job
  Job complete({
    required DateTime dateTimeIn,
    required double endingMeterReading,
    required double fuelUsed,
    String? remarksIn,
  }) {
    final totalKm = endingMeterReading - startingMeterReading;
    final fuelEfficiency = fuelUsed > 0 ? totalKm / fuelUsed : 0.0;
    
    return copyWith(
      status: JobStatus.completed,
      dateTimeIn: dateTimeIn,
      endingMeterReading: endingMeterReading,
      totalKm: totalKm,
      fuelUsed: fuelUsed,
      fuelEfficiency: fuelEfficiency,
      remarksIn: remarksIn,
      updatedAt: DateTime.now(),
    );
  }

  Job copyWith({
    String? id,
    String? jobId,
    DateTime? dateTimeOut,
    String? vehicleId,
    String? vehicleName,
    String? driverId,
    String? driverName,
    String? routeFrom,
    String? routeTo,
    String? purpose,
    double? startingMeterReading,
    String? remarksOut,
    JobStatus? status,
    DateTime? dateTimeIn,
    double? endingMeterReading,
    double? totalKm,
    double? fuelUsed,
    double? fuelEfficiency,
    String? remarksIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      dateTimeOut: dateTimeOut ?? this.dateTimeOut,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeFrom: routeFrom ?? this.routeFrom,
      routeTo: routeTo ?? this.routeTo,
      purpose: purpose ?? this.purpose,
      startingMeterReading: startingMeterReading ?? this.startingMeterReading,
      remarksOut: remarksOut ?? this.remarksOut,
      status: status ?? this.status,
      dateTimeIn: dateTimeIn ?? this.dateTimeIn,
      endingMeterReading: endingMeterReading ?? this.endingMeterReading,
      totalKm: totalKm ?? this.totalKm,
      fuelUsed: fuelUsed ?? this.fuelUsed,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      remarksIn: remarksIn ?? this.remarksIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'date_time_out': dateTimeOut.toIso8601String(),
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'driver_id': driverId,
      'driver_name': driverName,
      'route_from': routeFrom,
      'route_to': routeTo,
      'purpose': purpose,
      'starting_meter_reading': startingMeterReading,
      'remarks_out': remarksOut,
      'status': status.name,
      'date_time_in': dateTimeIn?.toIso8601String(),
      'ending_meter_reading': endingMeterReading,
      'total_km': totalKm,
      'fuel_used': fuelUsed,
      'fuel_efficiency': fuelEfficiency,
      'remarks_in': remarksIn,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (from API)
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      dateTimeOut: DateTime.parse(json['date_time_out']),
      vehicleId: json['vehicle_id'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      routeFrom: json['route_from'] ?? '',
      routeTo: json['route_to'] ?? '',
      purpose: json['purpose'] ?? '',
      startingMeterReading: (json['starting_meter_reading'] ?? 0).toDouble(),
      remarksOut: json['remarks_out'],
      status: JobStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JobStatus.pending,
      ),
      dateTimeIn: json['date_time_in'] != null 
          ? DateTime.parse(json['date_time_in'])
          : null,
      endingMeterReading: json['ending_meter_reading']?.toDouble(),
      totalKm: json['total_km']?.toDouble(),
      fuelUsed: json['fuel_used']?.toDouble(),
      fuelEfficiency: json['fuel_efficiency']?.toDouble(),
      remarksIn: json['remarks_in'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Helper getters
  String get route => '$routeFrom → $routeTo';
  
  String get formattedTimeOut => 
      '${dateTimeOut.day}/${dateTimeOut.month}/${dateTimeOut.year} '
      '${dateTimeOut.hour.toString().padLeft(2, '0')}:'
      '${dateTimeOut.minute.toString().padLeft(2, '0')}';
  
  String get formattedTimeIn {
    if (dateTimeIn == null) return '-';
    return '${dateTimeIn!.day}/${dateTimeIn!.month}/${dateTimeIn!.year} '
           '${dateTimeIn!.hour.toString().padLeft(2, '0')}:'
           '${dateTimeIn!.minute.toString().padLeft(2, '0')}';
  }
  
  String get formattedTotalKm => totalKm != null ? '${totalKm!.toStringAsFixed(1)} KM' : '-';
  
  String get formattedFuelUsed => fuelUsed != null ? '${fuelUsed!.toStringAsFixed(1)} L' : '-';
  
  String get formattedFuelEfficiency => fuelEfficiency != null 
      ? '${fuelEfficiency!.toStringAsFixed(1)} KM/L' 
      : '-';

  Duration get jobDuration {
    if (status == JobStatus.pending) return Duration.zero;
    if (dateTimeIn == null) return Duration.zero;
    return dateTimeIn!.difference(dateTimeOut);
  }

  String get formattedDuration {
    final duration = jobDuration;
    if (duration == Duration.zero) return '-';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    return '${hours}h ${minutes}m';
  }

  bool get isPending => status == JobStatus.pending;
  bool get isCompleted => status == JobStatus.completed;

  // Generate job ID
  static String _generateJobId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'JOB$timestamp';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Job(id: $id, jobId: $jobId, status: ${status.displayName}, '
           'vehicle: $vehicleName, driver: $driverName, route: $route)';
  }
}