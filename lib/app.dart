import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'layouts/main_layout.dart';
import 'screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

class FleetManagementApp extends ConsumerWidget {
  const FleetManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp(
      title: 'Fleet Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        fontFamily: 'Inter', // Modern font
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: _getHomeScreen(authState),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.dashboard,
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getHomeScreen(AuthState authState) {
    // Add safety checks to prevent crashes during state transitions
    try {
      if (authState.isLoading) {
        return const SplashScreen();
      } else if (authState.isAuthenticated && authState.username != null) {
        return const MainLayout(
          title: 'Dashboard',
          child: DashboardScreen(),
        );
      } else {
        return const LoginScreen();
      }
    } catch (e) {
      // Fallback to login screen if there's any error
      return const LoginScreen();
    }
  }
}
