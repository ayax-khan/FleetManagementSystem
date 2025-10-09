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
      'first_name': firstName,
      'last_name': lastName,
      'employee_id': employeeId,
      'cnic': cnic,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'joining_date': joiningDate.toIso8601String(),
      'status': status.name,
      'category': category.name,
      'license_number': licenseNumber,
      'license_category': licenseCategory.name,
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'basic_salary': basicSalary,
      'vehicle_assigned': vehicleAssigned,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_number': emergencyContactNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      employeeId: json['employee_id'] ?? '',
      cnic: json['cnic'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      address: json['address'] ?? '',
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      joiningDate: DateTime.parse(json['joining_date']),
      status: DriverStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DriverStatus.active,
      ),
      category: DriverCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DriverCategory.regular,
      ),
      licenseNumber: json['license_number'] ?? '',
      licenseCategory: LicenseCategory.values.firstWhere(
        (e) => e.name == json['license_category'],
        orElse: () => LicenseCategory.lightVehicle,
      ),
      licenseExpiryDate: DateTime.parse(json['license_expiry_date']),
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      vehicleAssigned: json['vehicle_assigned'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactNumber: json['emergency_contact_number'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
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
  regular('Regular', '👤'),
  senior('Senior', '⭐'),
  trainee('Trainee', '📚'),
  contractor('Contractor', '🤝'),
  partTime('Part Time', '⏰');

  const DriverCategory(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  Color get color {
    switch (this) {
      case DriverCategory.regular:
        return const Color(0xFF607D8B);
      case DriverCategory.senior:
        return const Color(0xFFFF9800);
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

