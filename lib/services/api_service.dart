import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// API Service for communicating with the FastAPI backend
class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  late final Dio _dio;
  late final Logger _logger;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _logger = Logger();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleDioError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleDioError(DioException error) {
    String message = 'Unknown error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout - check if backend is running';
        break;
      case DioExceptionType.connectionError:
        message =
            'Connection error - backend may not be running on 127.0.0.1:8000';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout';
        break;
      case DioExceptionType.badResponse:
        if (error.response != null) {
          final statusCode = error.response!.statusCode;
          final data = error.response!.data;
          String detail = 'Server error';
          if (data is Map<String, dynamic>) {
            detail = data['detail'] ?? 'Server error';
          } else if (data is String && data.isNotEmpty) {
            detail = data;
          } else {
            detail = 'Unexpected response format';
          }
          message = 'HTTP $statusCode: $detail';
        }
        break;
      case DioExceptionType.unknown:
        message = 'Network error: ${error.message}';
        break;
      default:
        message = error.message ?? 'Unknown error';
    }

    _logger.e('API Error: $message');
  }

  // Health check
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      // Use the correct health endpoint path
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get('/api/health');
      return {'success': true, 'status': 'connected', 'data': response.data};
    } catch (e) {
      return {
        'success': false,
        'status': 'disconnected',
        'error': e.toString(),
      };
    }
  }

  // Generic API methods
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data ?? {};
    } catch (e) {
      // Handle redirect errors (307) by retrying without trailing slash
      if (e is DioException && e.response?.statusCode == 307) {
        try {
          // Try without trailing slash if it has one, or add one if it doesn't
          final newEndpoint = endpoint.endsWith('/')
              ? endpoint.substring(0, endpoint.length - 1)
              : '$endpoint/';
          final response = await _dio.put(newEndpoint, data: data);
          return response.data ?? {};
        } catch (retryError) {
          _logger.e('Retry failed for redirect: $retryError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // File upload for Excel import
  Future<Map<String, dynamic>> uploadFile(String endpoint, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(endpoint, data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Job API methods
  Future<List<Map<String, dynamic>>> getJobs({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final queryParams = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await get('/trips/', queryParameters: queryParams);
    
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch jobs');
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    final response = await post('/trips/', data: jobData);
    
    if (response['success'] == true) {
      return Map<String, dynamic>.from(response['data'] ?? {});
    } else {
      throw Exception(response['message'] ?? 'Failed to create job');
    }
  }

  Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> jobData) async {
    final response = await put('/trips/$jobId', data: jobData);
    
    if (response['success'] == true) {
      return Map<String, dynamic>.from(response['data'] ?? {});
    } else {
      throw Exception(response['message'] ?? 'Failed to update job');
    }
  }

  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    final response = await delete('/trips/$jobId');
    
    if (response['success'] == true) {
      return response;
    } else {
      throw Exception(response['message'] ?? 'Failed to delete job');
    }
  }

  Future<Map<String, dynamic>> getJob(String jobId) async {
    final response = await get('/trips/$jobId');
    
    if (response['success'] == true) {
      return Map<String, dynamic>.from(response['data'] ?? {});
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch job');
    }
  }

  // Vehicle API methods
  Future<List<Map<String, dynamic>>> getVehicles({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (status != null) params['status'] = status;

    final response = await get('/vehicles/', queryParameters: params);
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> getVehicle(String vehicleId) async {
    final response = await get('/vehicles/$vehicleId');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> vehicleData,
  ) async {
    final response = await post('/vehicles/', data: vehicleData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateVehicle(
    String vehicleId,
    Map<String, dynamic> updates,
  ) async {
    final response = await put('/vehicles/$vehicleId', data: updates);
    return response['data'] ?? {};
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    final response = await delete('/vehicles/$vehicleId');
    return response['success'] ?? false;
  }

  Future<Map<String, dynamic>> getVehicleStats(String vehicleId) async {
    final response = await get('/vehicles/$vehicleId/stats');
    return response['data'] ?? {};
  }

  // Driver API methods
  Future<List<Map<String, dynamic>>> getDrivers({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (status != null) params['status'] = status;

    final response = await get('/drivers/', queryParameters: params);
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> getDriver(String driverId) async {
    final response = await get('/drivers/$driverId');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createDriver(
    Map<String, dynamic> driverData,
  ) async {
    final response = await post('/drivers/', data: driverData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateDriver(
    String driverId,
    Map<String, dynamic> updates,
  ) async {
    final response = await put('/drivers/$driverId', data: updates);
    return response['data'] ?? {};
  }

  Future<bool> deleteDriver(String driverId) async {
    final response = await delete('/drivers/$driverId');
    return response['success'] ?? false;
  }

  // Trip API methods
  Future<List<Map<String, dynamic>>> getTrips({
    int skip = 0,
    int limit = 100,
    String? vehicleId,
    String? driverId,
    String? status,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (vehicleId != null) params['vehicle_id'] = vehicleId;
    if (driverId != null) params['driver_id'] = driverId;
    if (status != null) params['status'] = status;

    final response = await get('/trips', queryParameters: params);
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    final response = await post('/trips', data: tripData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateTrip(
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    final response = await put('/trips/$tripId', data: updates);
    return response['data'] ?? {};
  }

  // Fuel API methods
  Future<List<Map<String, dynamic>>> getFuelEntries({
    int skip = 0,
    int limit = 100,
    String? vehicleId,
    String? driverId,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (vehicleId != null) params['vehicle_id'] = vehicleId;
    if (driverId != null) params['driver_id'] = driverId;

    final response = await get('/fuel', queryParameters: params);
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> createFuelEntry(
    Map<String, dynamic> fuelData,
  ) async {
    final response = await post('/fuel', data: fuelData);
    return response['data'] ?? {};
  }

  // Maintenance API methods
  Future<List<Map<String, dynamic>>> getMaintenanceRecords({
    int skip = 0,
    int limit = 100,
    String? vehicleId,
    String? maintenanceType,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (vehicleId != null) params['vehicle_id'] = vehicleId;
    if (maintenanceType != null) params['maintenance_type'] = maintenanceType;

    final response = await get('/maintenance', queryParameters: params);
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> createMaintenanceRecord(
    Map<String, dynamic> maintenanceData,
  ) async {
    final response = await post('/maintenance', data: maintenanceData);
    return response['data'] ?? {};
  }

  // Excel API methods
  Future<Map<String, dynamic>> analyzeExcelFile(File file) async {
    return await uploadFile('/excel/analyze', file);
  }

  Future<Map<String, dynamic>> importExcelFile(
    File file, {
    List<String>? selectedSheets,
    Map<String, String>? entityMappings,
    bool clearExisting = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'import_request': jsonEncode({
          'selected_sheets': selectedSheets,
          'entity_mappings': entityMappings,
          'clear_existing': clearExisting,
        }),
      });

      final response = await _dio.post('/excel/import', data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final response = await get('/excel/database/stats');
    return response['data'] ?? {};
  }

  Future<bool> clearTable(String tableName) async {
    final response = await post('/excel/database/clear/$tableName');
    return response['success'] ?? false;
  }

  Future<bool> clearAllTables() async {
    final response = await post('/excel/database/clear-all');
    return response['success'] ?? false;
  }
}
