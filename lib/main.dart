// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'app.dart';
import 'env.dart';
import 'core/logger.dart';
import 'dart:async';

void main() async {
  // CRITICAL FIX: ensureInitialized ko zone se bahar call karein
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  Env.loadEnv();

  // Init logger
  Logger.setDebugMode(Env.isDebug);

  // Error handling
  FlutterError.onError = (details) {
    FleetApp.handleError(details.exception, details.stack ?? StackTrace.empty);
  };

  // Run app in zone for error catching
  runZonedGuarded(
    () async {
      // Optional: Uncomment to reset Hive data
      // await Hive.deleteFromDisk();
      // Logger.info('Hive data reset complete');

      Logger.info('Starting app services initialization');
      await FleetApp.initServices();
      Logger.info('App services initialized, starting UI');
      runApp(const FleetApp());
    },
    (error, stack) {
      FleetApp.handleError(error, stack);
    },
  );
}
