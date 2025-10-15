import 'dart:async';
import 'dart:math';
// import 'package:geolocator/geolocator.dart'; // Uncomment when geolocator package is added
import '../models/location.dart';
import '../utils/debug_utils.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Office/Work location coordinates (example)
  static const double _officeLatitude = 24.8607; // Karachi coordinates
  static const double _officeLongitude = 67.0011;
  static const double _allowedRadiusMeters = 100; // 100 meters radius

  LocationData? _lastKnownLocation;
  Timer? _locationUpdateTimer;

  // Stream controller for location updates
  final StreamController<LocationData> _locationStreamController = 
      StreamController<LocationData>.broadcast();

  Stream<LocationData> get locationStream => _locationStreamController.stream;

  /// Initialize location services
  Future<bool> initialize() async {
    try {
      DebugUtils.log('Initializing location service', 'LOCATION');
      
      // TODO: Uncomment when geolocator package is added
      /*
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        DebugUtils.log('Location services are disabled', 'LOCATION');
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          DebugUtils.log('Location permissions are denied', 'LOCATION');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        DebugUtils.log('Location permissions are permanently denied', 'LOCATION');
        return false;
      }
      */

      // For demo purposes, simulate successful initialization
      await Future.delayed(const Duration(milliseconds: 500));
      DebugUtils.log('Location service initialized successfully', 'LOCATION');
      
      return true;
    } catch (e) {
      DebugUtils.logError('Failed to initialize location service', e);
      return false;
    }
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      DebugUtils.log('Getting current location', 'LOCATION');
      
      // TODO: Uncomment when geolocator package is added
      /*
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        address: await _getAddressFromCoordinates(position.latitude, position.longitude),
      );
      */

      // For demo purposes, simulate location data
      final locationData = LocationData(
        latitude: _officeLatitude + (Random().nextDouble() - 0.5) * 0.001, // Small random offset
        longitude: _officeLongitude + (Random().nextDouble() - 0.5) * 0.001,
        accuracy: 5.0 + Random().nextDouble() * 10, // 5-15 meters accuracy
        timestamp: DateTime.now(),
        address: 'Office Location, Karachi, Pakistan',
      );

      _lastKnownLocation = locationData;
      _locationStreamController.add(locationData);
      
      DebugUtils.log('Location obtained: ${locationData.latitude}, ${locationData.longitude}', 'LOCATION');
      
      return locationData;
    } catch (e) {
      DebugUtils.logError('Failed to get current location', e);
      return null;
    }
  }

  /// Check if current location is within allowed office radius
  Future<LocationVerificationResult> verifyAttendanceLocation() async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        return LocationVerificationResult(
          isValid: false,
          message: 'Unable to get current location',
          distance: null,
          location: null,
        );
      }

      final distance = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        _officeLatitude,
        _officeLongitude,
      );

      final isWithinRadius = distance <= _allowedRadiusMeters;

      return LocationVerificationResult(
        isValid: isWithinRadius,
        message: isWithinRadius 
            ? 'Location verified - within office area'
            : 'Location verification failed - outside office area (${distance.toInt()}m away)',
        distance: distance,
        location: currentLocation,
      );
    } catch (e) {
      DebugUtils.logError('Location verification failed', e);
      return LocationVerificationResult(
        isValid: false,
        message: 'Location verification error: $e',
        distance: null,
        location: null,
      );
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // TODO: Use Geolocator.distanceBetween when package is added
    // return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    
    // Haversine formula for distance calculation
    const double earthRadius = 6371000; // meters
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Start continuous location tracking
  void startLocationTracking({Duration interval = const Duration(minutes: 1)}) {
    DebugUtils.log('Starting location tracking', 'LOCATION');
    
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(interval, (timer) {
      getCurrentLocation();
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    DebugUtils.log('Stopping location tracking', 'LOCATION');
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // TODO: Implement reverse geocoding when geocoding package is added
      /*
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      */
      
      // For demo purposes, return mock address
      return 'Office Location, Karachi, Pakistan';
    } catch (e) {
      DebugUtils.logError('Failed to get address from coordinates', e);
      return 'Unknown Location';
    }
  }

  /// Get last known location
  LocationData? get lastKnownLocation => _lastKnownLocation;

  /// Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    // TODO: Implement with geolocator package
    // return await Geolocator.isLocationServiceEnabled();
    return true; // For demo purposes
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      // TODO: Implement with geolocator package
      // return await Geolocator.openLocationSettings();
      return true; // For demo purposes
    } catch (e) {
      DebugUtils.logError('Failed to open location settings', e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    DebugUtils.log('Disposing location service', 'LOCATION');
    _locationUpdateTimer?.cancel();
    _locationStreamController.close();
  }
}

/// Location verification result
class LocationVerificationResult {
  final bool isValid;
  final String message;
  final double? distance;
  final LocationData? location;

  LocationVerificationResult({
    required this.isValid,
    required this.message,
    required this.distance,
    required this.location,
  });

  @override
  String toString() {
    return 'LocationVerificationResult(isValid: $isValid, message: $message, distance: $distance)';
  }
}