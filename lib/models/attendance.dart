import 'package:flutter/material.dart';

// Main Attendance Model for daily attendance records
class Attendance {
  final String id;
  final String driverId;
  final String driverName; // Cached for performance
  final String driverEmployeeId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final double overtimeHours;
  final double? regularHours;
  final String? checkInLocation;
  final String? checkOutLocation;
  final String? checkInPhoto;
  final String? checkOutPhoto;
  final String? notes;
  final double? totalEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attendance({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverEmployeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.overtimeHours = 0.0,
    this.regularHours,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInPhoto,
    this.checkOutPhoto,
    this.notes,
    this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
  });

  Attendance copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverEmployeeId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    double? overtimeHours,
    double? regularHours,
    String? checkInLocation,
    String? checkOutLocation,
    String? checkInPhoto,
    String? checkOutPhoto,
    String? notes,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverEmployeeId: driverEmployeeId ?? this.driverEmployeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      regularHours: regularHours ?? this.regularHours,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInPhoto: checkInPhoto ?? this.checkInPhoto,
      checkOutPhoto: checkOutPhoto ?? this.checkOutPhoto,
      notes: notes ?? this.notes,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_employee_id': driverEmployeeId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status.name,
      'overtime_hours': overtimeHours,
      'regular_hours': regularHours,
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'check_in_photo': checkInPhoto,
      'check_out_photo': checkOutPhoto,
      'notes': notes,
      'total_earnings': totalEarnings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverEmployeeId: json['driver_employee_id'] ?? '',
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
      regularHours: json['regular_hours']?.toDouble(),
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
      checkInPhoto: json['check_in_photo'],
      checkOutPhoto: json['check_out_photo'],
      notes: json['notes'],
      totalEarnings: json['total_earnings']?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Calculated properties
  double get totalHours {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!).inMinutes / 60.0;
    }
    return regularHours ?? 0.0;
  }

  double get calculatedRegularHours {
    const double standardHours = 8.0;
    final total = totalHours;
    return total > standardHours ? standardHours : total;
  }

  double get calculatedOvertimeHours {
    const double standardHours = 8.0;
    final total = totalHours;
    return total > standardHours ? total - standardHours : 0.0;
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isWorkingDay => status == AttendanceStatus.present || status == AttendanceStatus.halfDay || status == AttendanceStatus.late;
  
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  
  String get checkInTimeFormatted => checkInTime != null 
      ? '${checkInTime!.hour}:${checkInTime!.minute.toString().padLeft(2, '0')}'
      : 'Not checked in';
      
  String get checkOutTimeFormatted => checkOutTime != null 
      ? '${checkOutTime!.hour}:${checkOutTime!.minute.toString().padLeft(2, '0')}'
      : 'Not checked out';

  String get workingTimeFormatted {
    final hours = totalHours;
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    return '${wholeHours}h ${minutes}m';
  }

  String get statusDisplayText {
    switch (status) {
      case AttendanceStatus.present:
        return isCheckedOut ? 'Completed' : isCheckedIn ? 'Working' : 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'On Leave';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.late:
        return 'Late Arrival';
      case AttendanceStatus.sick:
        return 'Sick Leave';
      case AttendanceStatus.overtime:
        return 'Overtime';
    }
  }
}

enum AttendanceStatus {
  present('Present', '✅'),
  absent('Absent', '❌'),
  leave('Leave', '🏖️'),
  halfDay('Half Day', '⏰'),
  late('Late', '🕐'),
  sick('Sick', '🤒'),
  overtime('Overtime', '⏰');

  const AttendanceStatus(this.displayName, this.icon);
  final String displayName;
  final String icon;
  
  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF4CAF50);
      case AttendanceStatus.absent:
        return const Color(0xFFF44336);
      case AttendanceStatus.leave:
        return const Color(0xFF2196F3);
      case AttendanceStatus.halfDay:
        return const Color(0xFFFF9800);
      case AttendanceStatus.late:
        return const Color(0xFFFF5722);
      case AttendanceStatus.sick:
        return const Color(0xFF9C27B0);
      case AttendanceStatus.overtime:
        return const Color(0xFF673AB7);
    }
  }
}

// Monthly Attendance Summary for analytics and reporting
class AttendanceSummary {
  final String driverId;
  final String driverName;
  final int month;
  final int year;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int halfDays;
  final int lateDays;
  final int sickDays;
  final double totalHours;
  final double regularHours;
  final double overtimeHours;
  final double totalEarnings;
  final double attendancePercentage;

  const AttendanceSummary({
    required this.driverId,
    required this.driverName,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.halfDays,
    required this.lateDays,
    required this.sickDays,
    required this.totalHours,
    required this.regularHours,
    required this.overtimeHours,
    required this.totalEarnings,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromAttendanceList(
    String driverId,
    String driverName,
    int month,
    int year,
    List<Attendance> attendances,
  ) {
    final workingDays = attendances.where((a) => a.date.weekday != 7).length; // Exclude Sundays
    final presentDays = attendances.where((a) => a.status == AttendanceStatus.present).length;
    final absentDays = attendances.where((a) => a.status == AttendanceStatus.absent).length;
    final leaveDays = attendances.where((a) => a.status == AttendanceStatus.leave).length;
    final halfDays = attendances.where((a) => a.status == AttendanceStatus.halfDay).length;
    final lateDays = attendances.where((a) => a.status == AttendanceStatus.late).length;
    final sickDays = attendances.where((a) => a.status == AttendanceStatus.sick).length;
    
    final totalHours = attendances.fold(0.0, (sum, a) => sum + a.totalHours);
    final regularHours = attendances.fold(0.0, (sum, a) => sum + a.calculatedRegularHours);
    final overtimeHours = attendances.fold(0.0, (sum, a) => sum + a.calculatedOvertimeHours);
    final totalEarnings = attendances.fold(0.0, (sum, a) => sum + (a.totalEarnings ?? 0.0));
    
    final attendancePercentage = workingDays > 0 ? (presentDays + halfDays * 0.5) / workingDays * 100 : 0.0;

    return AttendanceSummary(
      driverId: driverId,
      driverName: driverName,
      month: month,
      year: year,
      totalDays: workingDays,
      presentDays: presentDays,
      absentDays: absentDays,
      leaveDays: leaveDays,
      halfDays: halfDays,
      lateDays: lateDays,
      sickDays: sickDays,
      totalHours: totalHours,
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      totalEarnings: totalEarnings,
      attendancePercentage: attendancePercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'month': month,
      'year': year,
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'leave_days': leaveDays,
      'half_days': halfDays,
      'late_days': lateDays,
      'sick_days': sickDays,
      'total_hours': totalHours,
      'regular_hours': regularHours,
      'overtime_hours': overtimeHours,
      'total_earnings': totalEarnings,
      'attendance_percentage': attendancePercentage,
    };
  }

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      leaveDays: json['leave_days'] ?? 0,
      halfDays: json['half_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      sickDays: json['sick_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      regularHours: (json['regular_hours'] ?? 0.0).toDouble(),
      overtimeHours: (json['overtime_hours'] ?? 0.0).toDouble(),
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      attendancePercentage: (json['attendance_percentage'] ?? 0.0).toDouble(),
    );
  }

  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String get formattedPeriod => '$monthName $year';
  
  String get attendanceGrade {
    if (attendancePercentage >= 95) return 'Excellent';
    if (attendancePercentage >= 90) return 'Good';
    if (attendancePercentage >= 80) return 'Average';
    if (attendancePercentage >= 70) return 'Below Average';
    return 'Poor';
  }

  Color get attendanceGradeColor {
    if (attendancePercentage >= 95) return const Color(0xFF4CAF50);
    if (attendancePercentage >= 90) return const Color(0xFF8BC34A);
    if (attendancePercentage >= 80) return const Color(0xFFFF9800);
    if (attendancePercentage >= 70) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }
}

// Check-in/Check-out Request Model
class AttendanceRequest {
  final String driverId;
  final AttendanceAction action;
  final DateTime timestamp;
  final String? location;
  final String? photoPath;
  final String? notes;
  final AttendanceStatus? status;

  const AttendanceRequest({
    required this.driverId,
    required this.action,
    required this.timestamp,
    this.location,
    this.photoPath,
    this.notes,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'photo_path': photoPath,
      'notes': notes,
      'status': status?.name,
    };
  }
}

enum AttendanceAction {
  checkIn('Check In', '🟢'),
  checkOut('Check Out', '🔴'),
  breakTime('Break', '⏸️'),
  resumeWork('Resume', '▶️');

  const AttendanceAction(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

// Attendance Filter Model for search and filtering
class AttendanceFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? driverIds;
  final List<AttendanceStatus>? statuses;
  final bool? hasOvertime;
  final bool? isLateArrival;
  final String? searchQuery;

  const AttendanceFilter({
    this.startDate,
    this.endDate,
    this.driverIds,
    this.statuses,
    this.hasOvertime,
    this.isLateArrival,
    this.searchQuery,
  });

  AttendanceFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? driverIds,
    List<AttendanceStatus>? statuses,
    bool? hasOvertime,
    bool? isLateArrival,
    String? searchQuery,
  }) {
    return AttendanceFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      driverIds: driverIds ?? this.driverIds,
      statuses: statuses ?? this.statuses,
      hasOvertime: hasOvertime ?? this.hasOvertime,
      isLateArrival: isLateArrival ?? this.isLateArrival,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      (driverIds == null || driverIds!.isEmpty) &&
      (statuses == null || statuses!.isEmpty) &&
      hasOvertime == null &&
      isLateArrival == null &&
      (searchQuery == null || searchQuery!.isEmpty);
}