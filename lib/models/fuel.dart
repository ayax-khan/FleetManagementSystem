import 'package:flutter/material.dart';

// Main Fuel Record Model
class FuelRecord {
  final String id;
  final String vehicleId;
  final String vehicleName; // Cached for performance
  final String vehicleLicensePlate;
  final String driverId;
  final String driverName; // Cached for performance
  final DateTime date;
  final double quantity; // Liters
  final double unitPrice; // Price per liter
  final double totalCost;
  final String fuelStationId;
  final String fuelStationName;
  final FuelType fuelType;
  final double odometer; // Current odometer reading
  final double? previousOdometer; // Previous reading for consumption calculation
  final double? distanceTraveled; // Calculated distance
  final double? fuelConsumption; // Liters per 100km
  final PaymentMethod paymentMethod;
  final String? receiptNumber;
  final String? location;
  final String? notes;
  final List<String>? attachments; // Receipt photos, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleLicensePlate,
    required this.driverId,
    required this.driverName,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    required this.fuelStationId,
    required this.fuelStationName,
    required this.fuelType,
    required this.odometer,
    this.previousOdometer,
    this.distanceTraveled,
    this.fuelConsumption,
    required this.paymentMethod,
    this.receiptNumber,
    this.location,
    this.notes,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  FuelRecord copyWith({
    String? id,
    String? vehicleId,
    String? vehicleName,
    String? vehicleLicensePlate,
    String? driverId,
    String? driverName,
    DateTime? date,
    double? quantity,
    double? unitPrice,
    double? totalCost,
    String? fuelStationId,
    String? fuelStationName,
    FuelType? fuelType,
    double? odometer,
    double? previousOdometer,
    double? distanceTraveled,
    double? fuelConsumption,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    String? location,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalCost: totalCost ?? this.totalCost,
      fuelStationId: fuelStationId ?? this.fuelStationId,
      fuelStationName: fuelStationName ?? this.fuelStationName,
      fuelType: fuelType ?? this.fuelType,
      odometer: odometer ?? this.odometer,
      previousOdometer: previousOdometer ?? this.previousOdometer,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'vehicle_license_plate': vehicleLicensePlate,
      'driver_id': driverId,
      'driver_name': driverName,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_cost': totalCost,
      'fuel_station_id': fuelStationId,
      'fuel_station_name': fuelStationName,
      'fuel_type': fuelType.name,
      'odometer': odometer,
      'previous_odometer': previousOdometer,
      'distance_traveled': distanceTraveled,
      'fuel_consumption': fuelConsumption,
      'payment_method': paymentMethod.name,
      'receipt_number': receiptNumber,
      'location': location,
      'notes': notes,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FuelRecord.fromJson(Map<String, dynamic> json) {
    return FuelRecord(
      id: json['id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehicleLicensePlate: json['vehicle_license_plate'] ?? '',
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      date: DateTime.parse(json['date']),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      fuelStationId: json['fuel_station_id'] ?? '',
      fuelStationName: json['fuel_station_name'] ?? '',
      fuelType: FuelType.values.firstWhere(
        (e) => e.name == json['fuel_type'],
        orElse: () => FuelType.petrol,
      ),
      odometer: (json['odometer'] ?? 0.0).toDouble(),
      previousOdometer: json['previous_odometer']?.toDouble(),
      distanceTraveled: json['distance_traveled']?.toDouble(),
      fuelConsumption: json['fuel_consumption']?.toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      receiptNumber: json['receipt_number'],
      location: json['location'],
      notes: json['notes'],
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Calculated properties
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  String get formattedCost => 'PKR ${totalCost.toStringAsFixed(2)}';
  String get formattedQuantity => '${quantity.toStringAsFixed(2)} L';
  String get formattedUnitPrice => 'PKR ${unitPrice.toStringAsFixed(2)}/L';
  String get formattedOdometer => '${odometer.toStringAsFixed(0)} km';
  String get formattedConsumption => fuelConsumption != null 
      ? '${fuelConsumption!.toStringAsFixed(2)} L/100km'
      : 'N/A';
  String get formattedDistance => distanceTraveled != null 
      ? '${distanceTraveled!.toStringAsFixed(0)} km'
      : 'N/A';

  bool get hasReceipt => receiptNumber != null && receiptNumber!.isNotEmpty;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  bool get hasConsumptionData => fuelConsumption != null && distanceTraveled != null;
  
  // Efficiency rating based on fuel consumption
  FuelEfficiencyRating get efficiencyRating {
    if (fuelConsumption == null) return FuelEfficiencyRating.unknown;
    
    // Ratings based on typical vehicle consumption ranges
    if (fuelConsumption! <= 6.0) return FuelEfficiencyRating.excellent;
    if (fuelConsumption! <= 8.0) return FuelEfficiencyRating.good;
    if (fuelConsumption! <= 10.0) return FuelEfficiencyRating.average;
    if (fuelConsumption! <= 12.0) return FuelEfficiencyRating.poor;
    return FuelEfficiencyRating.terrible;
  }
}

enum FuelType {
  petrol('Petrol', '⛽'),
  diesel('Diesel', '🚛'),
  cng('CNG', '🔥'),
  lpg('LPG', '🚐'),
  electric('Electric', '🔌'),
  hybrid('Hybrid', '🔋');

  const FuelType(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  IconData get iconData {
    switch (this) {
      case FuelType.petrol:
        return Icons.local_gas_station;
      case FuelType.diesel:
        return Icons.local_shipping;
      case FuelType.cng:
        return Icons.whatshot;
      case FuelType.lpg:
        return Icons.propane_tank;
      case FuelType.electric:
        return Icons.electrical_services;
      case FuelType.hybrid:
        return Icons.battery_charging_full;
    }
  }
  
  Color get color {
    switch (this) {
      case FuelType.petrol:
        return const Color(0xFF4CAF50);
      case FuelType.diesel:
        return const Color(0xFF2196F3);
      case FuelType.cng:
        return const Color(0xFFFF9800);
      case FuelType.lpg:
        return const Color(0xFF9C27B0);
      case FuelType.electric:
        return const Color(0xFF607D8B);
      case FuelType.hybrid:
        return const Color(0xFF8BC34A);
    }
  }
}

enum PaymentMethod {
  cash('Cash', '💵'),
  card('Credit Card', '💳'),
  companyAccount('Company Account', '🏢'),
  fuelCard('Fuel Card', '⛽'),
  digitalWallet('Digital Wallet', '📱');

  const PaymentMethod(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  IconData get iconData {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.companyAccount:
        return Icons.business;
      case PaymentMethod.fuelCard:
        return Icons.local_gas_station;
      case PaymentMethod.digitalWallet:
        return Icons.account_balance_wallet;
    }
  }
  
  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return const Color(0xFF4CAF50);
      case PaymentMethod.card:
        return const Color(0xFF2196F3);
      case PaymentMethod.companyAccount:
        return const Color(0xFF1565C0);
      case PaymentMethod.fuelCard:
        return const Color(0xFFFF9800);
      case PaymentMethod.digitalWallet:
        return const Color(0xFF9C27B0);
    }
  }
}

enum FuelEfficiencyRating {
  excellent('Excellent', '🟢'),
  good('Good', '🔵'),
  average('Average', '🟡'),
  poor('Poor', '🟠'),
  terrible('Terrible', '🔴'),
  unknown('Unknown', '⚪');

  const FuelEfficiencyRating(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  IconData get iconData {
    switch (this) {
      case FuelEfficiencyRating.excellent:
        return Icons.eco;
      case FuelEfficiencyRating.good:
        return Icons.thumb_up;
      case FuelEfficiencyRating.average:
        return Icons.remove;
      case FuelEfficiencyRating.poor:
        return Icons.thumb_down;
      case FuelEfficiencyRating.terrible:
        return Icons.warning;
      case FuelEfficiencyRating.unknown:
        return Icons.help_outline;
    }
  }
  
  Color get color {
    switch (this) {
      case FuelEfficiencyRating.excellent:
        return const Color(0xFF4CAF50);
      case FuelEfficiencyRating.good:
        return const Color(0xFF2196F3);
      case FuelEfficiencyRating.average:
        return const Color(0xFFFF9800);
      case FuelEfficiencyRating.poor:
        return const Color(0xFFFF5722);
      case FuelEfficiencyRating.terrible:
        return const Color(0xFFF44336);
      case FuelEfficiencyRating.unknown:
        return const Color(0xFF9E9E9E);
    }
  }
}

// Fuel Station Model
class FuelStation {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String? phone;
  final List<FuelType> availableFuelTypes;
  final Map<FuelType, double> currentPrices;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FuelStation({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.phone,
    required this.availableFuelTypes,
    required this.currentPrices,
    this.rating = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'available_fuel_types': availableFuelTypes.map((e) => e.name).toList(),
      'current_prices': currentPrices.map((key, value) => MapEntry(key.name, value)),
      'rating': rating,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      phone: json['phone'],
      availableFuelTypes: (json['available_fuel_types'] as List?)
          ?.map((e) => FuelType.values.firstWhere((type) => type.name == e))
          .toList() ?? [],
      currentPrices: Map<FuelType, double>.fromEntries(
        (json['current_prices'] as Map<String, dynamic>? ?? {}).entries
            .map((e) => MapEntry(
              FuelType.values.firstWhere((type) => type.name == e.key),
              (e.value).toDouble(),
            )),
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get formattedRating => rating > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'Not rated';
  String get displayName => '$name - $location';
}

// Vehicle Fuel Analytics Model
class VehicleFuelAnalytics {
  final String vehicleId;
  final String vehicleName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalLiters;
  final double totalCost;
  final double totalDistance;
  final double averageConsumption;
  final double averageUnitPrice;
  final int totalFillUps;
  final FuelType primaryFuelType;
  final Map<FuelType, double> fuelTypeBreakdown;
  final List<FuelRecord> records;

  const VehicleFuelAnalytics({
    required this.vehicleId,
    required this.vehicleName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalLiters,
    required this.totalCost,
    required this.totalDistance,
    required this.averageConsumption,
    required this.averageUnitPrice,
    required this.totalFillUps,
    required this.primaryFuelType,
    required this.fuelTypeBreakdown,
    required this.records,
  });

  factory VehicleFuelAnalytics.fromRecords(
    String vehicleId,
    String vehicleName,
    DateTime periodStart,
    DateTime periodEnd,
    List<FuelRecord> records,
  ) {
    final filteredRecords = records
        .where((r) => 
          r.vehicleId == vehicleId &&
          r.date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          r.date.isBefore(periodEnd.add(const Duration(days: 1))))
        .toList();

    final totalLiters = filteredRecords.fold(0.0, (sum, r) => sum + r.quantity);
    final totalCost = filteredRecords.fold(0.0, (sum, r) => sum + r.totalCost);
    final totalDistance = filteredRecords
        .where((r) => r.distanceTraveled != null)
        .fold(0.0, (sum, r) => sum + r.distanceTraveled!);
    
    final consumptionRecords = filteredRecords.where((r) => r.fuelConsumption != null).toList();
    final averageConsumption = consumptionRecords.isNotEmpty
        ? consumptionRecords.fold(0.0, (sum, r) => sum + r.fuelConsumption!) / consumptionRecords.length
        : 0.0;
    
    final averageUnitPrice = filteredRecords.isNotEmpty
        ? filteredRecords.fold(0.0, (sum, r) => sum + r.unitPrice) / filteredRecords.length
        : 0.0;

    // Calculate fuel type breakdown
    final fuelTypeBreakdown = <FuelType, double>{};
    for (final record in filteredRecords) {
      fuelTypeBreakdown[record.fuelType] = 
          (fuelTypeBreakdown[record.fuelType] ?? 0.0) + record.quantity;
    }

    // Find primary fuel type
    FuelType primaryFuelType = FuelType.petrol;
    double maxQuantity = 0.0;
    for (final entry in fuelTypeBreakdown.entries) {
      if (entry.value > maxQuantity) {
        maxQuantity = entry.value;
        primaryFuelType = entry.key;
      }
    }

    return VehicleFuelAnalytics(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalLiters: totalLiters,
      totalCost: totalCost,
      totalDistance: totalDistance,
      averageConsumption: averageConsumption,
      averageUnitPrice: averageUnitPrice,
      totalFillUps: filteredRecords.length,
      primaryFuelType: primaryFuelType,
      fuelTypeBreakdown: fuelTypeBreakdown,
      records: filteredRecords,
    );
  }

  // Aliases for compatibility
  double get totalQuantity => totalLiters;

  // Formatted getters
  String get formattedTotalCost => 'PKR ${totalCost.toStringAsFixed(2)}';
  String get formattedTotalLiters => '${totalLiters.toStringAsFixed(2)} L';
  String get formattedTotalDistance => '${totalDistance.toStringAsFixed(0)} km';
  String get formattedAverageConsumption => '${averageConsumption.toStringAsFixed(2)} L/100km';
  String get formattedAveragePrice => 'PKR ${averageUnitPrice.toStringAsFixed(2)}/L';
  String get formattedPeriod => '${_formatDate(periodStart)} - ${_formatDate(periodEnd)}';

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  FuelEfficiencyRating get efficiencyRating {
    if (averageConsumption <= 6.0) return FuelEfficiencyRating.excellent;
    if (averageConsumption <= 8.0) return FuelEfficiencyRating.good;
    if (averageConsumption <= 10.0) return FuelEfficiencyRating.average;
    if (averageConsumption <= 12.0) return FuelEfficiencyRating.poor;
    return FuelEfficiencyRating.terrible;
  }
}

// Fuel Filter Model
class FuelFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? vehicleIds;
  final List<String>? driverIds;
  final List<FuelType>? fuelTypes;
  final List<PaymentMethod>? paymentMethods;
  final List<String>? fuelStationIds;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;

  const FuelFilter({
    this.startDate,
    this.endDate,
    this.vehicleIds,
    this.driverIds,
    this.fuelTypes,
    this.paymentMethods,
    this.fuelStationIds,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
  });

  FuelFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? vehicleIds,
    List<String>? driverIds,
    List<FuelType>? fuelTypes,
    List<PaymentMethod>? paymentMethods,
    List<String>? fuelStationIds,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) {
    return FuelFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      driverIds: driverIds ?? this.driverIds,
      fuelTypes: fuelTypes ?? this.fuelTypes,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      fuelStationIds: fuelStationIds ?? this.fuelStationIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      (vehicleIds == null || vehicleIds!.isEmpty) &&
      (driverIds == null || driverIds!.isEmpty) &&
      (fuelTypes == null || fuelTypes!.isEmpty) &&
      (paymentMethods == null || paymentMethods!.isEmpty) &&
      (fuelStationIds == null || fuelStationIds!.isEmpty) &&
      minAmount == null &&
      maxAmount == null &&
      (searchQuery == null || searchQuery!.isEmpty);
}