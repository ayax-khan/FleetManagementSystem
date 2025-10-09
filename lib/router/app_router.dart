import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../screens/dashboard_screen.dart';
import '../screens/vehicles/vehicle_list_screen.dart';
import '../screens/drivers/driver_list_screen.dart';
import '../screens/attendance/attendance_list_screen.dart';
import '../screens/fuel/fuel_list_screen.dart';
import '../screens/import/import_screen.dart';

class AppRouter {
  static const String dashboard = '/dashboard';
  static const String vehicles = '/vehicles';
  static const String drivers = '/drivers';
  static const String attendance = '/attendance';
  static const String fuel = '/fuel';
  static const String import = '/import';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return _buildPageRoute(
          const MainLayout(
            title: 'Dashboard',
            child: DashboardScreen(),
          ),
          settings,
        );
      
      case vehicles:
        return _buildPageRoute(
          const MainLayout(
            title: 'Vehicles',
            child: VehicleListScreen(),
          ),
          settings,
        );
      
      case drivers:
        return _buildPageRoute(
          const MainLayout(
            title: 'Drivers',
            child: DriverListScreen(),
          ),
          settings,
        );
      
      case attendance:
        return _buildPageRoute(
          const MainLayout(
            title: 'Attendance',
            child: AttendanceListScreen(),
          ),
          settings,
        );
      
      case fuel:
        return _buildPageRoute(
          const MainLayout(
            title: 'Fuel Management',
            child: FuelListScreen(),
          ),
          settings,
        );
      
      case import:
        return _buildPageRoute(
          const MainLayout(
            title: 'Import Data',
            child: ImportScreen(),
          ),
          settings,
        );
      
      default:
        return _buildPageRoute(
          const MainLayout(
            title: 'Dashboard',
            child: DashboardScreen(),
          ),
          settings,
        );
    }
  }

  static PageRoute _buildPageRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}