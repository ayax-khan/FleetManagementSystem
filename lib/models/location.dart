class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String address;
  final double? altitude;
  final double? speed;
  final double? heading;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.address,
    this.altitude,
    this.speed,
    this.heading,
  });

  // Create LocationData from JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String? ?? 'Unknown Location',
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
    );
  }

  // Convert LocationData to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }

  // Create a copy with updated values
  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    String? address,
    double? altitude,
    double? speed,
    double? heading,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  // Get formatted coordinates string
  String get coordinatesString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Get accuracy description
  String get accuracyDescription {
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'LocationData('
           'lat: ${latitude.toStringAsFixed(6)}, '
           'lng: ${longitude.toStringAsFixed(6)}, '
           'accuracy: ${accuracy.toStringAsFixed(1)}m, '
           'address: $address'
           ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          timestamp == other.timestamp &&
          address == other.address &&
          altitude == other.altitude &&
          speed == other.speed &&
          heading == other.heading;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      accuracy.hashCode ^
      timestamp.hashCode ^
      address.hashCode ^
      (altitude?.hashCode ?? 0) ^
      (speed?.hashCode ?? 0) ^
      (heading?.hashCode ?? 0);
}

// Location check-in/out data for attendance
class AttendanceLocationData {
  final LocationData location;
  final bool isWithinOfficeArea;
  final double? distanceFromOffice;
  final DateTime timestamp;
  final String? notes;

  const AttendanceLocationData({
    required this.location,
    required this.isWithinOfficeArea,
    required this.timestamp,
    this.distanceFromOffice,
    this.notes,
  });

  factory AttendanceLocationData.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationData(
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      isWithinOfficeArea: json['is_within_office_area'] as bool,
      distanceFromOffice: json['distance_from_office'] != null 
          ? (json['distance_from_office'] as num).toDouble() 
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'is_within_office_area': isWithinOfficeArea,
      if (distanceFromOffice != null) 'distance_from_office': distanceFromOffice,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  @override
  String toString() {
    return 'AttendanceLocationData('
           'location: $location, '
           'withinOffice: $isWithinOfficeArea, '
           'distance: ${distanceFromOffice?.toStringAsFixed(1)}m'
           ')';
  }
}