import 'package:flutter/material.dart';
import 'attendance.dart';

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String employeeId;
  final String cnic; // National ID
  final String phoneNumber;
  final String? email;
  final String address;
  final DateTime dateOfBirth;
  final DateTime joiningDate;
  final DriverStatus status;
  final DriverCategory category;
  final String licenseNumber;
  final LicenseCategory licenseCategory;
  final DateTime licenseExpiryDate;
  final double basicSalary;
  final String? vehicleAssigned; // Vehicle ID
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.employeeId,
    required this.cnic,
    required this.phoneNumber,
    this.email,
    required this.address,
    required this.dateOfBirth,
    required this.joiningDate,
    required this.status,
    required this.category,
    required this.licenseNumber,
    required this.licenseCategory,
    required this.licenseExpiryDate,
    required this.basicSalary,
    this.vehicleAssigned,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? employeeId,
    String? cnic,
    String? phoneNumber,
    String? email,
    String? address,
    DateTime? dateOfBirth,
    DateTime? joiningDate,
    DriverStatus? status,
    DriverCategory? category,
    String? licenseNumber,
    LicenseCategory? licenseCategory,
    DateTime? licenseExpiryDate,
    double? basicSalary,
    String? vehicleAssigned,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      employeeId: employeeId ?? this.employeeId,
      cnic: cnic ?? this.cnic,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      category: category ?? this.category,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseCategory: licenseCategory ?? this.licenseCategory,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      basicSalary: basicSalary ?? this.basicSalary,
      vehicleAssigned: vehicleAssigned ?? this.vehicleAssigned,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Backend expects 'name' field (combining first and last name)
      'name': fullName, // Use fullName getter that combines firstName + lastName
      'employee_id': employeeId,
      'cnic': cnic,
      // Map Flutter model fields to backend schema fields
      'license_number': licenseNumber,
      'license_expiry': licenseExpiryDate.toIso8601String().split('T')[0], // Date only
      'license_category': licenseCategory.name,
      'phone': phoneNumber,
      'email': email,
      'emergency_contact': emergencyContactName != null && emergencyContactNumber != null 
          ? '$emergencyContactName: $emergencyContactNumber' 
          : emergencyContactName ?? emergencyContactNumber,
      'address': address,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // Date only
      'joining_date': joiningDate.toIso8601String().split('T')[0], // Date only
      'basic_salary': basicSalary,
      'assigned_vehicle': vehicleAssigned,
      'category': category.name,
      'notes': notes,
      'status': status.name,
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Safe enum parsing helper
    T parseEnum<T extends Enum>(dynamic value, List<T> values, T defaultValue, String Function(T) nameExtractor, String Function(T) displayNameExtractor) {
      if (value == null) return defaultValue;
      
      final valueStr = value.toString().toLowerCase();
      
      // Try exact match first
      try {
        return values.firstWhere(
          (e) => nameExtractor(e).toLowerCase() == valueStr,
        );
      } catch (e) {
        // Try display name match
        try {
          return values.firstWhere(
            (e) => displayNameExtractor(e).toLowerCase() == valueStr,
          );
        } catch (e) {
          return defaultValue;
        }
      }
    }
    
    // Safe date parsing helper
    DateTime parseDate(String? dateStr, DateTime fallback) {
      if (dateStr == null || dateStr.isEmpty) return fallback;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return fallback;
      }
    }
    
    final now = DateTime.now();
    
    // Parse the 'name' field from backend and split it into first and last names
    String fullNameFromBackend = json['name']?.toString() ?? '';
    List<String> nameParts = fullNameFromBackend.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return Driver(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      employeeId: json['employee_id']?.toString() ?? '',
      cnic: json['cnic']?.toString() ?? '', // Backend doesn't have CNIC, using default
      phoneNumber: json['phone']?.toString() ?? '', // Backend uses 'phone' not 'phone_number'
      email: json['email']?.toString(),
      address: json['address']?.toString() ?? '',
      dateOfBirth: parseDate(json['date_of_birth']?.toString(), now.subtract(const Duration(days: 365 * 30))),
      joiningDate: parseDate(json['joining_date']?.toString(), now),
      status: parseEnum(
        json['status'],
        DriverStatus.values,
        DriverStatus.active,
        (e) => e.name,
        (e) => e.displayName,
      ),
      category: parseEnum(
        json['category'],
        DriverCategory.values,
        DriverCategory.regular,
        (e) => e.name,
        (e) => e.displayName,
      ),
      licenseNumber: json['license_number']?.toString() ?? '',
      licenseCategory: parseEnum(
        json['license_category'],
        LicenseCategory.values,
        LicenseCategory.lightVehicle,
        (e) => e.name,
        (e) => e.displayName,
      ),
      licenseExpiryDate: parseDate(json['license_expiry']?.toString(), now.add(const Duration(days: 365))), // Backend uses 'license_expiry'
      basicSalary: (json['basic_salary'] ?? 50000).toDouble(), // Default salary since backend doesn't have this field
      vehicleAssigned: json['assigned_vehicle']?.toString(), // Backend uses 'assigned_vehicle'
      emergencyContactName: _parseEmergencyContactName(json['emergency_contact']?.toString()),
      emergencyContactNumber: _parseEmergencyContactNumber(json['emergency_contact']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['created_at']?.toString(), now),
      updatedAt: parseDate(json['updated_at']?.toString(), now),
    );
  }

  String get fullName => '$firstName $lastName';
  
  String get displayName => '$fullName ($employeeId)';
  
  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  int get experienceInYears {
    final now = DateTime.now();
    int experience = now.year - joiningDate.year;
    if (now.month < joiningDate.month || 
        (now.month == joiningDate.month && now.day < joiningDate.day)) {
      experience--;
    }
    return experience;
  }

  bool get isLicenseExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = licenseExpiryDate.difference(now).inDays;
    return daysUntilExpiry <= 30; // License expiring in 30 days
  }

  bool get isLicenseExpired {
    return licenseExpiryDate.isBefore(DateTime.now());
  }

  bool get hasVehicleAssigned => vehicleAssigned != null && vehicleAssigned!.isNotEmpty;
  
  // Helper methods for parsing emergency contact from backend
  static String? _parseEmergencyContactName(String? emergencyContact) {
    if (emergencyContact == null || emergencyContact.isEmpty) return null;
    if (emergencyContact.contains(':')) {
      return emergencyContact.split(':')[0].trim();
    }
    return emergencyContact;
  }
  
  static String? _parseEmergencyContactNumber(String? emergencyContact) {
    if (emergencyContact == null || emergencyContact.isEmpty) return null;
    if (emergencyContact.contains(':')) {
      List<String> parts = emergencyContact.split(':');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return null;
  }
}

enum DriverStatus {
  active('Active', '✅'),
  inactive('Inactive', '⏸️'),
  suspended('Suspended', '🚫'),
  onLeave('On Leave', '🏖️'),
  terminated('Terminated', '❌');

  const DriverStatus(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  Color get color {
    switch (this) {
      case DriverStatus.active:
        return const Color(0xFF4CAF50);
      case DriverStatus.inactive:
        return const Color(0xFFFF9800);
      case DriverStatus.suspended:
        return const Color(0xFFF44336);
      case DriverStatus.onLeave:
        return const Color(0xFF2196F3);
      case DriverStatus.terminated:
        return const Color(0xFF9E9E9E);
    }
  }
}

enum DriverCategory {
  transportOfficial('Transport Official', '🎖️'),
  generalDrivers('General Drivers', '🚗'),
  shiftDrivers('Shift Drivers', '🔄'),
  entitledDrivers('Entitled Drivers', '⭐'),
  regular('Regular', '👤'),
  trainee('Trainee', '📚'),
  contractor('Contractor', '🤝'),
  partTime('Part Time', '⏰');

  const DriverCategory(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  Color get color {
    switch (this) {
      case DriverCategory.transportOfficial:
        return const Color(0xFF1976D2);
      case DriverCategory.generalDrivers:
        return const Color(0xFF607D8B);
      case DriverCategory.shiftDrivers:
        return const Color(0xFF00695C);
      case DriverCategory.entitledDrivers:
        return const Color(0xFFFF9800);
      case DriverCategory.regular:
        return const Color(0xFF607D8B);
      case DriverCategory.trainee:
        return const Color(0xFF4CAF50);
      case DriverCategory.contractor:
        return const Color(0xFF9C27B0);
      case DriverCategory.partTime:
        return const Color(0xFF2196F3);
    }
  }
}

enum LicenseCategory {
  motorcycle('Motorcycle', '🏍️', 'M'),
  lightVehicle('Light Vehicle', '🚗', 'LTV'),
  heavyVehicle('Heavy Vehicle', '🚚', 'HTV'),
  publicServiceVehicle('Public Service Vehicle', '🚌', 'PSV'),
  tractor('Tractor', '🚜', 'T'),
  internationalDriving('International Driving', '🌍', 'IDP');

  const LicenseCategory(this.displayName, this.icon, this.code);
  final String displayName;
  final String icon;
  final String code;
  
  Color get color {
    switch (this) {
      case LicenseCategory.motorcycle:
        return const Color(0xFF795548);
      case LicenseCategory.lightVehicle:
        return const Color(0xFF2196F3);
      case LicenseCategory.heavyVehicle:
        return const Color(0xFFFF5722);
      case LicenseCategory.publicServiceVehicle:
        return const Color(0xFF4CAF50);
      case LicenseCategory.tractor:
        return const Color(0xFF8BC34A);
      case LicenseCategory.internationalDriving:
        return const Color(0xFF9C27B0);
    }
  }
}

// Driver Attendance Model for integration with spreadsheet data
class DriverAttendance {
  final String id;
  final String driverId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final double overtimeHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverAttendance({
    required this.id,
    required this.driverId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.overtimeHours = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalHours {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!).inMinutes / 60.0;
    }
    return 0.0;
  }

  double get regularHours {
    const double standardHours = 8.0;
    final total = totalHours;
    return total > standardHours ? standardHours : total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status.name,
      'overtime_hours': overtimeHours,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DriverAttendance.fromJson(Map<String, dynamic> json) {
    return DriverAttendance(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time']) 
          : null,
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      overtimeHours: (json['overtime_hours'] ?? 0.0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

