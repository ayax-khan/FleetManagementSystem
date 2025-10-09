import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// Import services
import 'services/api_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    logger.i(' Fleet Management System starting...');

    // Initialize API service (singleton)
    final apiService = ApiService();

    // Check backend connectivity
    final healthCheck = await apiService.checkHealth();
    if (healthCheck['success']) {
      logger.i(' Backend connected successfully');
      logger.d('Backend status: ${healthCheck['data']}');
    } else {
      logger.w(' Backend not available: ${healthCheck['error']}');
      logger.w(
        'Make sure the Python FastAPI backend is running on localhost:8000',
      );
    }

    logger.i(' App initialization completed');
  } catch (e, stackTrace) {
    logger.e(' Failed to initialize app', error: e, stackTrace: stackTrace);
    // Continue anyway - app will handle offline state
  }

  runApp(const ProviderScope(child: FleetManagementApp()));
}
