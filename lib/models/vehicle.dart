import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final String year;
  final String licensePlate;
  final String vin; // Vehicle Identification Number
  final VehicleType type;
  final VehicleStatus status;
  final double fuelCapacity;
  final double currentMileage;
  final String color;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
    required this.type,
    required this.status,
    required this.fuelCapacity,
    required this.currentMileage,
    required this.color,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    String? year,
    String? licensePlate,
    String? vin,
    VehicleType? type,
    VehicleStatus? status,
    double? fuelCapacity,
    double? currentMileage,
    String? color,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      type: type ?? this.type,
      status: status ?? this.status,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      currentMileage: currentMileage ?? this.currentMileage,
      color: color ?? this.color,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'vin': vin,
      'type': type.name,
      'status': status.name,
      'fuel_capacity': fuelCapacity,
      'current_mileage': currentMileage,
      'color': color,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      vin: json['vin'] ?? '',
      type: VehicleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VehicleType.car,
      ),
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VehicleStatus.active,
      ),
      fuelCapacity: (json['fuel_capacity'] ?? 0).toDouble(),
      currentMileage: (json['current_mileage'] ?? 0).toDouble(),
      color: json['color'] ?? '',
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.parse(json['purchase_date']) 
          : null,
      purchasePrice: json['purchase_price']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get displayName => '$make $model ($year)';
  
  String get fullDisplayName => '$make $model $year - $licensePlate';
  
  bool get isPurchased => purchaseDate != null && purchasePrice != null;
  
  int get ageInYears {
    final currentYear = DateTime.now().year;
    return currentYear - int.parse(year);
  }
}

enum VehicleType {
  car('Car', '🚗'),
  truck('Truck', '🚚'),
  van('Van', '🚐'),
  motorcycle('Motorcycle', '🏍️'),
  bus('Bus', '🚌'),
  trailer('Trailer', '🚛');

  const VehicleType(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

enum VehicleStatus {
  active('Active', '✅'),
  inactive('Inactive', '⏸️'),
  maintenance('In Maintenance', '🔧'),
  outOfService('Out of Service', '❌'),
  sold('Sold', '💰'),
  accident('Accident', '⚠️');

  const VehicleStatus(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  Color get color {
    switch (this) {
      case VehicleStatus.active:
        return const Color(0xFF4CAF50);
      case VehicleStatus.inactive:
        return const Color(0xFFFF9800);
      case VehicleStatus.maintenance:
        return const Color(0xFF2196F3);
      case VehicleStatus.outOfService:
        return const Color(0xFFF44336);
      case VehicleStatus.sold:
        return const Color(0xFF9E9E9E);
      case VehicleStatus.accident:
        return const Color(0xFFE91E63);
    }
  }
}

// Common vehicle makes for dropdown
class VehicleMakes {
  static const List<String> popular = [
    'Toyota',
    'Honda',
    'Ford',
    'Chevrolet',
    'Nissan',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Hyundai',
    'Kia',
    'Mazda',
    'Subaru',
    'Lexus',
    'Acura',
    'Infiniti',
    'Jeep',
    'Ram',
    'GMC',
    'Cadillac',
    'Buick',
    'Chrysler',
    'Dodge',
    'Lincoln',
    'Volvo',
    'Jaguar',
    'Land Rover',
    'Porsche',
    'Tesla',
    'Other',
  ];
}

// Common colors for dropdown
class VehicleColors {
  static const List<String> common = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Blue',
    'Red',
    'Green',
    'Yellow',
    'Orange',
    'Brown',
    'Purple',
    'Gold',
    'Other',
  ];
}