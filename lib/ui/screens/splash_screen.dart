// lib/ui/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../../core/logger.dart';
import '../../services/hive_service.dart';
import '../../services/auth_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  double _progress = 0.0;
  String _currentStep = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _colorAnimation = ColorTween(begin: Colors.blue[900], end: Colors.blue[700])
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      _updateProgress(0.1, 'Starting application...');

      // Initialize Hive Service
      _updateProgress(0.3, 'Initializing database...');
      await HiveService().init();

      // Initialize Auth Service
      _updateProgress(0.6, 'Loading user session...');
      await AuthService().init();

      // Create demo users if needed
      _updateProgress(0.8, 'Setting up demo data...');
      await AuthService().createDemoUsers();

      _updateProgress(1.0, 'Ready!');

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
      });

      _navigateBasedOnAuth();
    } catch (e, stackTrace) {
      Logger.error(
        'App initialization failed',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _hasError = true;
        _errorMessage = _getUserFriendlyError(e);
        _isInitialized = true;
      });
    }
  }

  void _updateProgress(double progress, String step) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _currentStep = step;
      });
    }
  }

  String _getUserFriendlyError(dynamic error) {
    if (error.toString().contains('already open')) {
      return 'Database connection issue. Please restart the app.';
    } else if (error.toString().contains('permission')) {
      return 'Storage permission required. Please grant storage access.';
    } else if (error.toString().contains('encryption')) {
      return 'Security configuration error. App may need reinstallation.';
    } else {
      return 'Failed to initialize app: ${error.toString().split(':').first}';
    }
  }

  void _navigateBasedOnAuth() {
    if (_hasError) {
      // Stay on splash screen to show error
      return;
    }

    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      try {
        final authController = Provider.of<AuthController>(
          context,
          listen: false,
        );

        authController.checkAuth();

        if (authController.isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        Logger.error('Navigation failed', error: e);
        // Fallback to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progress = 0.0;
      _currentStep = 'Retrying...';
      _isInitialized = false;
    });

    _initializeApp();
  }

  void _continueToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo and App Name
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            Icons.local_shipping,
                            size: 100,
                            color: _colorAnimation.value,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'FleetMaster',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fleet Management System',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Progress Indicator and Status
                if (!_isInitialized) ...[
                  _buildProgressIndicator(),
                  const SizedBox(height: 20),
                  _buildStatusText(),
                ] else if (_hasError) ...[
                  _buildErrorState(),
                ] else ...[
                  _buildSuccessState(),
                ],

                const SizedBox(height: 40),

                // Version Info
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${(_progress * 100).toInt()}%',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _currentStep,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
        const SizedBox(height: 16),
        Text(
          'Initialization Error',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _retryInitialization,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _continueToLogin,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Continue to Login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 50, color: Colors.green[400]),
        const SizedBox(height: 16),
        Text(
          'Ready!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Redirecting...',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ),
      ],
    );
  }
}
