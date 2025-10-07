// lib/app.dart
import 'package:fleet_management/ui/screens/dashboard_screen.dart';
import 'package:fleet_management/ui/screens/drivers_screen.dart';
import 'package:fleet_management/ui/screens/finance_screen.dart';
import 'package:fleet_management/ui/screens/fuel_screen.dart';
import 'package:fleet_management/ui/screens/import_wizard_screen.dart';
import 'package:fleet_management/ui/screens/login_screen.dart';
import 'package:fleet_management/ui/screens/maintenance_screen.dart';
import 'package:fleet_management/ui/screens/settings_screen.dart';
import 'package:fleet_management/ui/screens/splash_screen.dart';
import 'package:fleet_management/ui/screens/trips_screen.dart';
import 'package:fleet_management/ui/screens/vehicle_detail_screen.dart';
import 'package:fleet_management/ui/screens/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/vehicle_controller.dart';
// Import other controllers
import 'ui/theme.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'core/logger.dart';
import 'core/constants.dart';

class FleetApp extends StatelessWidget {
  const FleetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<DashboardController>(
          create: (_) => DashboardController(),
        ),
        ChangeNotifierProvider<VehicleController>(
          create: (_) => VehicleController(),
        ),
        // Add providers for other controllers
      ],
      child: MaterialApp(
        title: Constants.appName,
        theme: AppTheme.lightTheme, // Or dynamic based on settings
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/vehicles': (context) => const VehiclesScreen(),
          '/vehicle_detail': (context) =>
              VehicleDetailScreen(vehicleId: ''), // Pass id via args
          '/drivers': (context) => const DriversScreen(),
          '/trips': (context) => const TripsScreen(),
          '/maintenance': (context) => const MaintenanceScreen(),
          '/fuel': (context) => const FuelScreen(),
          '/finance': (context) => const FinanceScreen(),
          '/import': (context) => const ImportWizardScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/vehicle_detail') {
            final args = settings.arguments as String; // vehicleId
            return MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicleId: args),
            );
          }
          return null;
        },
      ),
    );
  }

  // App lifecycle handling
  static Future<void> initServices() async {
    await HiveService().init();
    await AuthService().init();
    Logger.info('App services initialized');
  }

  // Error handling
  static void handleError(Object error, StackTrace stack) {
    Logger.error('App error', error: error, stackTrace: stack);
    // Show dialog or report
  }

  // More: Localization, dynamic theme
  static ThemeData getDynamicTheme(String theme) {
    return theme == 'light' ? AppTheme.lightTheme : AppTheme.darkTheme;
  }

  // Offline mode check
  static bool checkOffline() {
    // Implement connectivity check
    return false;
  }

  // Full functionality: Deep links, push notifications setup if needed
}
