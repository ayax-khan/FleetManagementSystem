import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../utils/debug_utils.dart';

class JobState {
  final List<Job> jobs;
  final bool isLoading;
  final String? error;
  final Job? selectedJob;

  const JobState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
    this.selectedJob,
  });

  JobState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    String? error,
    Job? selectedJob,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return JobState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedJob: clearSelected ? null : (selectedJob ?? this.selectedJob),
    );
  }
}

class JobNotifier extends StateNotifier<JobState> {
  final ApiService _apiService = ApiService();
  bool _isOperationInProgress = false;
  
  // References to other providers for name lookup
  List<Map<String, dynamic>> _vehicleCache = [];
  List<Map<String, dynamic>> _driverCache = [];

  JobNotifier() : super(const JobState()) {
    _initializeAndLoadJobs();
  }

  Future<void> _initializeAndLoadJobs() async {
    await _loadVehicleAndDriverCache();
    await loadJobs();
  }

  Future<void> _loadVehicleAndDriverCache() async {
    try {
      // Load vehicle and driver data for name lookups
      final vehicles = await _apiService.getVehicles();
      final drivers = await _apiService.getDrivers();
      
      _vehicleCache = vehicles;
      _driverCache = drivers;
      
      DebugUtils.log('Loaded ${vehicles.length} vehicles and ${drivers.length} drivers for cache', 'JOB');
    } catch (e) {
      DebugUtils.logError('Failed to load vehicle/driver cache', e);
      _vehicleCache = [];
      _driverCache = [];
    }
  }

  Future<void> loadJobs() async {
    if (_isOperationInProgress) {
      DebugUtils.log('Load jobs blocked - operation in progress', 'JOB');
      return;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Loading jobs from backend API', 'JOB');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Refresh cache before loading jobs to get latest vehicle/driver names
      await _loadVehicleAndDriverCache();
      
      // Try to load from API first
      final jobsData = await _apiService.getJobs(limit: 1000);
      final jobs = jobsData.map((data) => _mapApiJobToModel(data)).toList();
      
      state = state.copyWith(
        jobs: jobs,
        isLoading: false,
      );

      DebugUtils.log('Loaded ${jobs.length} jobs from API', 'JOB');
    } catch (e) {
      DebugUtils.logError('Failed to load jobs from API, using empty list', e);
      
      // If API fails, start with empty list instead of dummy data
      state = state.copyWith(
        jobs: [],
        isLoading: false,
        error: 'Failed to load jobs: $e',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> createJob(Job job) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Create job blocked - operation in progress', 'JOB');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Creating job: ${job.jobId}', 'JOB');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Convert job to API format and send to backend
      final jobData = _mapJobToApiFormat(job);
      final createdJobData = await _apiService.createJob(jobData);
      
      // Convert API response back to Job model
      final createdJob = _mapApiJobToModel(createdJobData);
      
      // Add to local state
      final updatedJobs = [...state.jobs, createdJob];
      
      state = state.copyWith(
        jobs: updatedJobs,
        isLoading: false,
      );

      DebugUtils.log('Job created successfully: ${createdJob.jobId}', 'JOB');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create job: $e',
      );
      DebugUtils.logError('Failed to create job', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> completeJob(String jobId, {
    required DateTime dateTimeIn,
    required double endingMeterReading,
    required double fuelUsed,
    String? remarksIn,
  }) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Complete job blocked - operation in progress', 'JOB');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Completing job: $jobId', 'JOB');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Find the job
      final jobIndex = state.jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex == -1) {
        throw Exception('Job not found');
      }

      final job = state.jobs[jobIndex];
      if (job.status != JobStatus.pending) {
        throw Exception('Job is not in pending state');
      }

      // Complete the job locally first
      final completedJob = job.complete(
        dateTimeIn: dateTimeIn,
        endingMeterReading: endingMeterReading,
        fuelUsed: fuelUsed,
        remarksIn: remarksIn,
      );

      // Update in backend
      final jobData = _mapJobToApiFormat(completedJob);
      await _apiService.updateJob(jobId, jobData);

      // Update in local state
      final updatedJobs = [...state.jobs];
      updatedJobs[jobIndex] = completedJob;
      
      state = state.copyWith(
        jobs: updatedJobs,
        isLoading: false,
        selectedJob: completedJob,
      );

      DebugUtils.log('Job completed successfully: ${completedJob.jobId}', 'JOB');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete job: $e',
      );
      DebugUtils.logError('Failed to complete job', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    if (_isOperationInProgress) {
      DebugUtils.log('Delete job blocked - operation in progress', 'JOB');
      return false;
    }

    _isOperationInProgress = true;
    DebugUtils.log('Deleting job: $jobId', 'JOB');
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Delete from backend first
      await _apiService.deleteJob(jobId);
      
      // Remove from local state
      final updatedJobs = state.jobs.where((j) => j.id != jobId).toList();
      
      state = state.copyWith(
        jobs: updatedJobs,
        isLoading: false,
        clearSelected: state.selectedJob?.id == jobId,
      );

      DebugUtils.log('Job deleted successfully: $jobId', 'JOB');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete job: $e',
      );
      DebugUtils.logError('Failed to delete job', e);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  void selectJob(Job job) {
    DebugUtils.log('Job selected: ${job.jobId}', 'JOB');
    state = state.copyWith(selectedJob: job);
  }

  void clearSelection() {
    DebugUtils.log('Job selection cleared', 'JOB');
    state = state.copyWith(clearSelected: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Search and filter methods
  List<Job> searchJobs(String query) {
    if (query.isEmpty) return state.jobs;

    final lowerQuery = query.toLowerCase();
    return state.jobs.where((job) {
      return job.jobId.toLowerCase().contains(lowerQuery) ||
             job.vehicleName.toLowerCase().contains(lowerQuery) ||
             job.driverName.toLowerCase().contains(lowerQuery) ||
             job.routeFrom.toLowerCase().contains(lowerQuery) ||
             job.routeTo.toLowerCase().contains(lowerQuery) ||
             job.purpose.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Job> filterByStatus(JobStatus status) {
    return state.jobs.where((job) => job.status == status).toList();
  }

  List<Job> getPendingJobs() {
    return state.jobs.where((job) => job.isPending).toList();
  }

  List<Job> getCompletedJobs() {
    return state.jobs.where((job) => job.isCompleted).toList();
  }

  List<Job> getJobsForVehicle(String vehicleId) {
    return state.jobs.where((job) => job.vehicleId == vehicleId).toList();
  }

  List<Job> getJobsForDriver(String driverId) {
    return state.jobs.where((job) => job.driverId == driverId).toList();
  }

  // Statistics
  int get totalJobs => state.jobs.length;
  int get pendingJobs => getPendingJobs().length;
  int get completedJobs => getCompletedJobs().length;
  
  double get averageFuelEfficiency {
    final completed = getCompletedJobs();
    if (completed.isEmpty) return 0;
    
    final validJobs = completed.where((j) => j.fuelEfficiency != null && j.fuelEfficiency! > 0).toList();
    if (validJobs.isEmpty) return 0;
    
    final totalEfficiency = validJobs.map((j) => j.fuelEfficiency!).reduce((a, b) => a + b);
    return totalEfficiency / validJobs.length;
  }

  double get totalKilometers {
    return getCompletedJobs()
        .where((j) => j.totalKm != null)
        .map((j) => j.totalKm!)
        .fold(0.0, (sum, km) => sum + km);
  }

  double get totalFuelUsed {
    return getCompletedJobs()
        .where((j) => j.fuelUsed != null)
        .map((j) => j.fuelUsed!)
        .fold(0.0, (sum, fuel) => sum + fuel);
  }

  // Mapping methods for API integration
  Job _mapApiJobToModel(Map<String, dynamic> data) {
    // Parse route from backend format
    String route = data['route'] ?? '';
    String routeFrom = route.isNotEmpty ? route.split(' → ').first : '';
    String routeTo = route.isNotEmpty && route.contains(' → ') ? route.split(' → ').last : route;

    // Map backend status to JobStatus
    JobStatus status = JobStatus.pending;
    String backendStatus = data['status'] ?? 'in_progress';
    if (backendStatus == 'completed') {
      status = JobStatus.completed;
    }

    // Calculate total km and fuel efficiency if data available
    double? totalKm;
    double? fuelEfficiency;
    if (data['distance'] != null) {
      totalKm = (data['distance'] as num).toDouble();
    }
    if (totalKm != null && data['fuel_used'] != null && (data['fuel_used'] as num) > 0) {
      fuelEfficiency = totalKm / (data['fuel_used'] as num);
    }

    // Look up vehicle and driver names from cache
    String vehicleId = data['vehicle_id'] ?? '';
    String driverId = data['driver_id'] ?? '';
    
    String vehicleName = _getVehicleNameById(vehicleId);
    String driverName = _getDriverNameById(driverId);

    return Job(
      id: data['id'] ?? '',
      jobId: (data['job_id'] ?? _friendlyJobId(data)).toString(),
      dateTimeOut: DateTime.parse(data['start_time'] ?? DateTime.now().toIso8601String()),
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      driverId: driverId,
      driverName: driverName,
      routeFrom: routeFrom,
      routeTo: routeTo,
      purpose: data['purpose'] ?? '',
      destination: data['destination'],
      officerStaff: data['officer_staff'],
      coes: data['coes'],
      dutyDetail: data['duty_detail'],
      startingMeterReading: (data['start_km'] ?? 0.0).toDouble(),
      remarksOut: null, // Backend doesn't have this field
      status: status,
      dateTimeIn: data['end_time'] != null 
          ? DateTime.parse(data['end_time'])
          : null,
      endingMeterReading: data['end_km']?.toDouble(),
      totalKm: totalKm,
      fuelUsed: data['fuel_used']?.toDouble(),
      fuelEfficiency: fuelEfficiency,
      remarksIn: null, // Backend doesn't have this field
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper methods for name lookup
  String _getVehicleNameById(String vehicleId) {
    if (vehicleId.isEmpty) return 'No Vehicle';
    
    try {
      final vehicle = _vehicleCache.firstWhere(
        (v) => v['id']?.toString() == vehicleId,
      );
      
      // Try different possible name fields from the API
      String? name = vehicle['name'] ?? 
                     vehicle['make_type'] ?? 
                     vehicle['registration_number'];
      
      if (name != null && name.isNotEmpty) {
        return name;
      }
      
      // If no name found, try to construct from make/model
      String make = vehicle['make']?.toString() ?? '';
      String model = vehicle['model']?.toString() ?? '';
      if (make.isNotEmpty && model.isNotEmpty) {
        return '$make $model';
      }
      
      return vehicle['registration_number']?.toString() ?? 'Vehicle #$vehicleId';
    } catch (e) {
      DebugUtils.logError('Vehicle not found in cache: $vehicleId', e);
      return 'Vehicle #$vehicleId';
    }
  }
  
  String _getDriverNameById(String driverId) {
    if (driverId.isEmpty) return 'No Driver';
    
    try {
      final driver = _driverCache.firstWhere(
        (d) => d['id']?.toString() == driverId,
      );
      
      // Try to get the full name
      String? name = driver['name'];
      if (name != null && name.isNotEmpty) {
        return name;
      }
      
      // Try to construct from first/last name
      String firstName = driver['first_name']?.toString() ?? '';
      String lastName = driver['last_name']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
      
      // Fallback to employee ID or driver ID
      String? employeeId = driver['employee_id'];
      if (employeeId != null && employeeId.isNotEmpty) {
        return 'Driver $employeeId';
      }
      
      return 'Driver #$driverId';
    } catch (e) {
      DebugUtils.logError('Driver not found in cache: $driverId', e);
      return 'Driver #$driverId';
    }
  }

  Map<String, dynamic> _mapJobToApiFormat(Job job) {
    // Map to backend Trip format
    String route = '${job.routeFrom} → ${job.routeTo}';
    String status = job.status == JobStatus.completed ? 'completed' : 'in_progress';

    return {
      'job_id': job.jobId,
      'vehicle_id': job.vehicleId,
      'driver_id': job.driverId.isNotEmpty ? job.driverId : null,
      'start_km': job.startingMeterReading,
      'start_time': job.dateTimeOut.toIso8601String(),
      'purpose': job.purpose,
      'destination': job.destination,
      'officer_staff': job.officerStaff,
      'coes': job.coes,
      'duty_detail': job.dutyDetail,
      'route': route,
      'status': status,
      if (job.dateTimeIn != null) 'end_time': job.dateTimeIn!.toIso8601String(),
      if (job.endingMeterReading != null) 'end_km': job.endingMeterReading,
      if (job.totalKm != null) 'distance': job.totalKm,
      if (job.fuelUsed != null) 'fuel_used': job.fuelUsed,
    };
  }

  // Generate a readable fallback ID when backend doesn't provide job_id
  String _friendlyJobId(Map<String, dynamic> data) {
    final created = data['created_at']?.toString();
    String datePart;
    try {
      final dt = created != null ? DateTime.parse(created) : DateTime.now();
      datePart = '${dt.year}${dt.month.toString().padLeft(2,'0')}${dt.day.toString().padLeft(2,'0')}';
    } catch (_) {
      datePart = 'NA';
    }
    final rawId = data['id']?.toString() ?? '';
    final short = rawId.isNotEmpty ? rawId.replaceAll('-', '').substring(0, 6).toUpperCase() : 'XXXXXX';
    return 'JOB-$datePart-$short';
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});

// Computed providers for filtered data
final pendingJobsProvider = Provider<List<Job>>((ref) {
  final jobState = ref.watch(jobProvider);
  return jobState.jobs.where((j) => j.isPending).toList();
});

final completedJobsProvider = Provider<List<Job>>((ref) {
  final jobState = ref.watch(jobProvider);
  return jobState.jobs.where((j) => j.isCompleted).toList();
});

final jobStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final jobNotifier = ref.read(jobProvider.notifier);
  return {
    'total': jobNotifier.totalJobs,
    'pending': jobNotifier.pendingJobs,
    'completed': jobNotifier.completedJobs,
    'totalKm': jobNotifier.totalKilometers,
    'totalFuel': jobNotifier.totalFuelUsed,
    'avgEfficiency': jobNotifier.averageFuelEfficiency,
  };
});