// lib/core/utils/validators.dart
import 'package:fleet_management/models/vehicle.dart';
import 'package:intl/intl.dart';

class Validators {
  // Vehicle registration number: Alphanumeric with dashes, e.g., GD-092
  static bool isValidRegistrationNumber(String regNo) {
    final regex = RegExp(r'^[A-Z]{2,3}-\d{3,4}$');
    return regex.hasMatch(regNo.toUpperCase());
  }

  // Add this to your Validators class in validators.dart
  static String? Function(String?) get required {
    return (value) => requiredField(value, 'This field');
  }

  // Or more specific version:
  static String? Function(String?) requiredFor(String fieldName) {
    return (value) => requiredField(value, fieldName);
  }

  // Driver license number: Length between 10-15 characters, alphanumeric
  static bool isValidLicenseNumber(String licenseNo) {
    return licenseNo.length >= 10 &&
        licenseNo.length <= 15 &&
        RegExp(r'^[A-Z0-9-]+$').hasMatch(licenseNo);
  }

  // Odometer: Positive number, greater than 0
  static bool isValidOdometer(double? odometer) {
    return odometer != null && odometer > 0;
  }

  // Trip KM validation: startKm < endKm
  static bool isValidTripKm(double startKm, double? endKm) {
    return endKm != null && endKm > startKm;
  }

  // Fuel liters: Positive number > 0
  static bool isValidFuelLiters(double liters) {
    return liters > 0;
  }

  // Price per liter: Non-negative
  static bool isValidPrice(double? price) {
    return price != null && price >= 0;
  }

  // Cost: Non-negative
  static bool isValidCost(double? cost) {
    return cost != null && cost >= 0;
  }

  // Date validation: Valid ISO date, future or past checks
  static bool isValidDate(String? dateStr, {bool allowFuture = true}) {
    if (dateStr == null) return false;
    try {
      final date = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
      if (!allowFuture && date.isAfter(DateTime.now())) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Expiry date: Must be in future
  static bool isValidExpiryDate(DateTime? expiry) {
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  // Phone number: Pakistani format, e.g., +92 or 03xx-xxxxxxx
  static bool isValidPhone(String? phone) {
    if (phone == null) return false;
    final regex = RegExp(r'^(?:\+92|0)?3[0-9]{2}[0-9]{7}$');
    return regex.hasMatch(phone);
  }

  // Status enum validation
  static bool isValidVehicleStatus(String status) {
    const validStatuses = ['active', 'maintenance', 'inactive', 'assigned'];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidDriverStatus(String status) {
    const validStatuses = ['active', 'on_leave', 'inactive'];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidJobStatus(String status) {
    const validStatuses = [
      'pending',
      'assigned',
      'ongoing',
      'completed',
      'cancelled',
    ];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidTripStatus(String status) {
    const validStatuses = ['ongoing', 'completed', 'approved'];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidAttendanceStatus(String status) {
    const validStatuses = ['present', 'absent', 'half_day', 'leave'];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidAllowanceStatus(String status) {
    const validStatuses = ['pending', 'approved', 'rejected', 'paid'];
    return validStatuses.contains(status.toLowerCase());
  }

  static bool isValidAllowanceType(String type) {
    const validTypes = [
      'conveyance',
      'overtime',
      'reimbursement',
      'private_use',
      'other',
    ];
    return validTypes.contains(type.toLowerCase());
  }

  static bool isValidShift(String? shift) {
    if (shift == null) return false;
    const validShifts = ['morning', 'evening', 'night'];
    return validShifts.contains(shift.toLowerCase());
  }

  // URL validation for attachments/receipts
  static bool isValidUrl(String? url) {
    if (url == null) return false;
    final regex = RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$');
    return regex.hasMatch(url);
  }

  // General required field check
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Combine validators for form fields
  static String? validateVehicle(Vehicle vehicle) {
    String? error = requiredField(
      vehicle.registrationNumber,
      'Registration Number',
    );
    if (error != null) return error;
    if (!isValidRegistrationNumber(vehicle.registrationNumber))
      return 'Invalid registration format';
    error = requiredField(vehicle.makeType, 'Make & Type');
    if (error != null) return error;
    if (vehicle.currentOdometer != null &&
        !isValidOdometer(vehicle.currentOdometer))
      return 'Invalid odometer';
    if (!isValidVehicleStatus(vehicle.status)) return 'Invalid vehicle status';
    return null;
  }

  // Similar for other models...
  // Add more as needed for Driver, Trip, etc.
}
